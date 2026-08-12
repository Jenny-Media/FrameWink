import CoreGraphics
import Foundation
import UIKit
import Vision

protocol PhotoAnalyzing {
    func restoredAnalysis(
        candidate: PhotoCandidate,
        cachedSignals: PhotoSignals
    ) -> AnalyzedPhoto?

    func analyze(
        candidate: PhotoCandidate,
        image: UIImage,
        cachedSignals: PhotoSignals?
    ) async throws -> AnalyzedPhoto
}

extension PhotoAnalyzing {
    func restoredAnalysis(
        candidate: PhotoCandidate,
        cachedSignals: PhotoSignals
    ) -> AnalyzedPhoto? {
        guard cachedSignals.isReusable(
            for: candidate,
            algorithmRevision: SmartReelCurator.algorithmRevision
        ) else {
            return nil
        }
        return AnalyzedPhoto(
            candidate: candidate,
            signals: cachedSignals,
            featurePrint: nil
        )
    }
}

enum PhotoAnalysisError: LocalizedError {
    case missingImageData

    var errorDescription: String? {
        "This photo could not be analyzed."
    }
}

final class VisionFeaturePrint: PhotoFeaturePrintDistance {
    private let observation: VNFeaturePrintObservation

    init(observation: VNFeaturePrintObservation) {
        self.observation = observation
    }

    convenience init?(archivedData: Data) {
        guard let observation = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: VNFeaturePrintObservation.self,
            from: archivedData
        ) else {
            return nil
        }
        self.init(observation: observation)
    }

    func normalizedDistance(to other: any PhotoFeaturePrintDistance) -> Double? {
        guard let other = other as? VisionFeaturePrint else { return nil }
        var distance: Float = 0
        do {
            try observation.computeDistance(&distance, to: other.observation)
            return min(max(Double(distance) / 40, 0), 1)
        } catch {
            return nil
        }
    }
}

struct VisionPhotoAnalyzer: PhotoAnalyzing {
    func restoredAnalysis(
        candidate: PhotoCandidate,
        cachedSignals: PhotoSignals
    ) -> AnalyzedPhoto? {
        guard cachedSignals.isReusable(
            for: candidate,
            algorithmRevision: SmartReelCurator.algorithmRevision
        ) else {
            return nil
        }
        let featurePrint: VisionFeaturePrint?
        if let archive = cachedSignals.featurePrintArchive {
            guard let restored = VisionFeaturePrint(archivedData: archive) else {
                return nil
            }
            featurePrint = restored
        } else {
            featurePrint = nil
        }
        return AnalyzedPhoto(
            candidate: candidate,
            signals: cachedSignals,
            featurePrint: featurePrint
        )
    }

    func analyze(
        candidate: PhotoCandidate,
        image: UIImage,
        cachedSignals: PhotoSignals?
    ) async throws -> AnalyzedPhoto {
        if let cachedSignals = cachedSignals,
           let restored = restoredAnalysis(
               candidate: candidate,
               cachedSignals: cachedSignals
           ) {
            return restored
        }
        return try await Task.detached(priority: .utility) {
            try Task.checkCancellation()
            guard let cgImage = image.cgImage else {
                throw PhotoAnalysisError.missingImageData
            }

            let vision: VisionResult
            switch ProcessInfo.processInfo.thermalState {
            case .serious, .critical:
                // Keep curation usable under thermal pressure while avoiding
                // optional Vision work until the device cools.
                vision = .empty
            default:
                vision = Self.performVision(on: cgImage)
            }
            try Task.checkCancellation()

            let conventional = Self.conventionalSignals(for: cgImage)
            let importantRects = (vision.faceRects + vision.salientRects)
                .filter(\.isWithinUnitBounds)
            let featurePrintArchive = vision.featurePrint.flatMap {
                try? NSKeyedArchiver.archivedData(
                    withRootObject: $0,
                    requiringSecureCoding: true
                )
            }
            let signals = PhotoSignals(
                candidateID: candidate.id,
                algorithmRevision: SmartReelCurator.algorithmRevision,
                contentRevision: candidate.contentRevision,
                sharpness: conventional.sharpness,
                exposure: conventional.exposure,
                contrast: conventional.contrast,
                faceQuality: vision.faceQuality,
                saliencyConfidence: vision.saliencyConfidence,
                layoutFitness: Self.layoutFitness(
                    pixelWidth: candidate.pixelWidth,
                    pixelHeight: candidate.pixelHeight,
                    importantRects: importantRects
                ),
                importantRects: importantRects,
                featurePrintArchive: featurePrintArchive
            )

            return AnalyzedPhoto(
                candidate: candidate,
                signals: signals,
                featurePrint: vision.featurePrint.map(VisionFeaturePrint.init)
            )
        }.value
    }

    private static func performVision(on image: CGImage) -> VisionResult {
#if targetEnvironment(simulator)
        // The iOS 27 Simulator currently reports repeated Espresso-context
        // failures for these Vision requests. Conventional signals and all
        // deterministic curation logic remain executable there; public Vision
        // enrichment is verified on physical hardware during release testing.
        return VisionResult(
            featurePrint: nil,
            faceQuality: nil,
            saliencyConfidence: nil,
            faceRects: [],
            salientRects: []
        )
#else
        let featureRequest = VNGenerateImageFeaturePrintRequest()
        let faceRequest = VNDetectFaceCaptureQualityRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()

        // Vision capabilities differ by OS, hardware, and image. Keep each
        // optional enrichment independent so one unavailable request never
        // discards otherwise usable conventional quality signals.
        try? VNImageRequestHandler(cgImage: image, orientation: .up)
            .perform([featureRequest])
        try? VNImageRequestHandler(cgImage: image, orientation: .up)
            .perform([faceRequest])
        try? VNImageRequestHandler(cgImage: image, orientation: .up)
            .perform([saliencyRequest])

        let faces = faceRequest.results ?? []
        let saliency = saliencyRequest.results?.first
        return VisionResult(
            featurePrint: featureRequest.results?.first,
            faceQuality: faces.compactMap(\.faceCaptureQuality).max().map(Double.init),
            saliencyConfidence: saliency.map { Double($0.confidence) },
            faceRects: faces.map { topLeftRect(from: $0.boundingBox) },
            salientRects: (saliency?.salientObjects ?? []).map {
                topLeftRect(from: $0.boundingBox)
            }
        )
#endif
    }

    private static func conventionalSignals(for image: CGImage) -> ConventionalSignals {
        let width = 64
        let height = max(1, min(64, Int(Double(width) / max(
            Double(image.width) / Double(max(image.height, 1)),
            0.01
        ))))
        var pixels = [UInt8](repeating: 0, count: width * height)
        let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard rendered else {
            return ConventionalSignals(sharpness: 0, exposure: 0.5, contrast: 0)
        }

        let normalized = pixels.map { Double($0) / 255 }
        let mean = normalized.reduce(0, +) / Double(normalized.count)
        let variance = normalized.reduce(0) { partial, value in
            let difference = value - mean
            return partial + difference * difference
        } / Double(normalized.count)
        let contrast = min(sqrt(variance) * 4, 1)

        var edgeTotal = 0.0
        var edgeCount = 0
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                if x + 1 < width {
                    edgeTotal += abs(normalized[index] - normalized[index + 1])
                    edgeCount += 1
                }
                if y + 1 < height {
                    edgeTotal += abs(normalized[index] - normalized[index + width])
                    edgeCount += 1
                }
            }
        }
        let sharpness = edgeCount > 0
            ? min((edgeTotal / Double(edgeCount)) * 8, 1)
            : 0
        return ConventionalSignals(sharpness: sharpness, exposure: mean, contrast: contrast)
    }

    private static func layoutFitness(
        pixelWidth: Int,
        pixelHeight: Int,
        importantRects: [NormalizedRect]
    ) -> Double {
        guard pixelWidth > 0, pixelHeight > 0 else { return 0 }
        let aspect = Double(pixelWidth) / Double(pixelHeight)
        let aspectFitness: Double
        switch aspect {
        case 0.55...2.2:
            aspectFitness = 1
        case 0.35..<0.55, 2.2...3.2:
            aspectFitness = 0.72
        default:
            aspectFitness = 0.45
        }

        guard !importantRects.isEmpty else { return aspectFitness }
        let minX = importantRects.map(\.minX).min() ?? 0
        let maxX = importantRects.map(\.maxX).max() ?? 1
        let minY = importantRects.map(\.minY).min() ?? 0
        let maxY = importantRects.map(\.maxY).max() ?? 1
        let span = max(maxX - minX, maxY - minY)
        return min(aspectFitness * (span > 0.9 ? 0.82 : 1), 1)
    }

    private static func topLeftRect(from visionRect: CGRect) -> NormalizedRect {
        NormalizedRect(
            x: Double(visionRect.minX),
            y: Double(1 - visionRect.maxY),
            width: Double(visionRect.width),
            height: Double(visionRect.height)
        ).clampedToUnitBounds()
    }
}

private struct ConventionalSignals {
    let sharpness: Double
    let exposure: Double
    let contrast: Double
}

private struct VisionResult {
    let featurePrint: VNFeaturePrintObservation?
    let faceQuality: Double?
    let saliencyConfidence: Double?
    let faceRects: [NormalizedRect]
    let salientRects: [NormalizedRect]

    static let empty = VisionResult(
        featurePrint: nil,
        faceQuality: nil,
        saliencyConfidence: nil,
        faceRects: [],
        salientRects: []
    )
}
