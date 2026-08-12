import Foundation

struct PhotoSignals: Codable, Equatable {
    let candidateID: UUID
    let algorithmRevision: Int
    let sharpness: Double
    let exposure: Double
    let contrast: Double
    let faceQuality: Double?
    let saliencyConfidence: Double?
    let layoutFitness: Double
    let importantRects: [NormalizedRect]

    var qualityScore: Double {
        let exposureFitness = max(0, 1 - abs(exposure - 0.5) * 2)
        return bounded(
            sharpness * 0.24
                + exposureFitness * 0.18
                + contrast * 0.15
                + (faceQuality ?? 0.5) * 0.15
                + (saliencyConfidence ?? 0.5) * 0.10
                + layoutFitness * 0.18
        )
    }

    private func bounded(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

protocol PhotoFeaturePrintDistance {
    func normalizedDistance(to other: any PhotoFeaturePrintDistance) -> Double?
}

struct FixtureFeaturePrint: PhotoFeaturePrintDistance {
    let values: [Double]

    func normalizedDistance(to other: any PhotoFeaturePrintDistance) -> Double? {
        guard let other = other as? FixtureFeaturePrint,
              values.count == other.values.count,
              !values.isEmpty else {
            return nil
        }

        let squaredDistance = zip(values, other.values).reduce(0.0) { partial, pair in
            let difference = pair.0 - pair.1
            return partial + difference * difference
        }
        return min(sqrt(squaredDistance / Double(values.count)), 1)
    }
}

struct AnalyzedPhoto {
    let candidate: PhotoCandidate
    let signals: PhotoSignals
    let featurePrint: (any PhotoFeaturePrintDistance)?
}

enum CurationReason: String, Codable, Equatable {
    case quality
    case face
    case saliency
    case layout
    case dateDiversity
}

struct CuratedPhoto: Identifiable, Codable, Equatable {
    let candidateID: UUID
    let algorithmRevision: Int
    let finalScore: Double
    let reasons: [CurationReason]
    let importantRects: [NormalizedRect]

    init(
        candidateID: UUID,
        algorithmRevision: Int,
        finalScore: Double,
        reasons: [CurationReason],
        importantRects: [NormalizedRect] = []
    ) {
        self.candidateID = candidateID
        self.algorithmRevision = algorithmRevision
        self.finalScore = finalScore
        self.reasons = reasons
        self.importantRects = importantRects
    }

    var id: UUID { candidateID }
}

struct SmartReel: Identifiable, Codable, Equatable {
    let id: UUID
    let algorithmRevision: Int
    let createdAt: Date
    let selections: [CuratedPhoto]
}

struct DisplayHistoryEntry: Codable, Equatable {
    let candidateID: UUID
    var lastDisplayedAt: Date
    var displayCount: Int
}
