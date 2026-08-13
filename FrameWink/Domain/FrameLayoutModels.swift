import Foundation

struct PixelSize: Codable, Equatable {
    let width: Int
    let height: Int

    var aspectRatio: Double {
        guard width > 0, height > 0 else { return 0 }
        return Double(width) / Double(height)
    }

    var isLandscape: Bool {
        width > height
    }
}

struct NormalizedRect: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    static let unit = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }
    var midX: Double { x + width / 2 }
    var midY: Double { y + height / 2 }

    var isWithinUnitBounds: Bool {
        minX >= 0 && minY >= 0 && maxX <= 1 && maxY <= 1
            && width >= 0 && height >= 0
    }

    func clampedToUnitBounds() -> NormalizedRect {
        let clampedMinX = min(max(minX, 0), 1)
        let clampedMinY = min(max(minY, 0), 1)
        let clampedMaxX = min(max(maxX, clampedMinX), 1)
        let clampedMaxY = min(max(maxY, clampedMinY), 1)
        return NormalizedRect(
            x: clampedMinX,
            y: clampedMinY,
            width: clampedMaxX - clampedMinX,
            height: clampedMaxY - clampedMinY
        )
    }
}

enum FrameLayoutPreference: String, CaseIterable, Codable, Identifiable {
    case automatic
    case fit
    case fill
    case mosaic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Auto"
        case .fit: return "Fit"
        case .fill: return "Fill"
        case .mosaic: return "Mosaic"
        }
    }
}

enum FrameLayoutKind: String, Equatable {
    case singleFit
    case singleFill
    case pairedPortraits
    case stackedLandscapes
    case mosaic
}

enum FrameContentMode: Equatable {
    case fit
    case crop
}

struct FrameLayoutItem: Identifiable, Equatable {
    let id: String
    let pixelSize: PixelSize
    let importantRects: [NormalizedRect]
    let creationDate: Date?

    init(
        id: String,
        pixelSize: PixelSize,
        importantRects: [NormalizedRect],
        creationDate: Date? = nil
    ) {
        self.id = id
        self.pixelSize = pixelSize
        self.importantRects = importantRects
        self.creationDate = creationDate
    }
}

struct FrameLayoutPlacement: Identifiable, Equatable {
    let id: String
    let photoID: String
    let screenFrame: NormalizedRect
    let sourceCrop: NormalizedRect
    let contentMode: FrameContentMode
}

struct FramePage: Identifiable, Equatable {
    let id: String
    let kind: FrameLayoutKind
    let placements: [FrameLayoutPlacement]
}

enum FramePageAnchorResolver {
    static func index(
        preserving photoID: String?,
        in pages: [FramePage],
        fallbackIndex: Int
    ) -> Int {
        guard !pages.isEmpty else { return 0 }
        if let photoID,
           let anchoredIndex = pages.firstIndex(where: { page in
               page.placements.contains(where: { $0.photoID == photoID })
           }) {
            return anchoredIndex
        }
        return min(max(fallbackIndex, 0), pages.count - 1)
    }
}

enum FrameMotionSafety {
    static func canZoom(
        placement: FrameLayoutPlacement,
        importantRects: [NormalizedRect],
        maximumScale: Double
    ) -> Bool {
        canApply(
            state: FramePhotoMotionState(scale: maximumScale, offsetX: 0, offsetY: 0),
            placement: placement,
            importantRects: importantRects
        )
    }

    static func canApply(
        state: FramePhotoMotionState,
        placement: FrameLayoutPlacement,
        importantRects: [NormalizedRect]
    ) -> Bool {
        guard placement.contentMode == .crop, state.scale >= 1 else { return false }
        let maximumOffset = (state.scale - 1) / 2
        let tolerance = 0.000_001
        guard abs(state.offsetX) <= maximumOffset + tolerance,
              abs(state.offsetY) <= maximumOffset + tolerance else {
            return false
        }
        let protectedRects = importantRects
            .map { $0.clampedToUnitBounds() }
            .filter { $0.width > 0 && $0.height > 0 }
        guard !protectedRects.isEmpty else { return true }

        let crop = placement.sourceCrop
        let visibleWidth = crop.width / state.scale
        let visibleHeight = crop.height / state.scale
        let visibleCrop = NormalizedRect(
            x: crop.midX - visibleWidth / 2
                - state.offsetX * crop.width / state.scale,
            y: crop.midY - visibleHeight / 2
                - state.offsetY * crop.height / state.scale,
            width: visibleWidth,
            height: visibleHeight
        )
        return protectedRects.allSatisfy { rect in
            rect.minX >= visibleCrop.minX - tolerance
                && rect.maxX <= visibleCrop.maxX + tolerance
                && rect.minY >= visibleCrop.minY - tolerance
                && rect.maxY <= visibleCrop.maxY + tolerance
        }
    }
}

struct FramePhotoMotionState: Equatable {
    let scale: Double
    let offsetX: Double
    let offsetY: Double
}

struct FramePhotoMotionPlan: Equatable {
    let start: FramePhotoMotionState
    let end: FramePhotoMotionState
}

enum FramePhotoMotionPlanner {
    static func plan(
        photoID: String,
        placement: FrameLayoutPlacement,
        importantRects: [NormalizedRect],
        preferredMaximumScale: Double = 1.07
    ) -> FramePhotoMotionPlan? {
        guard placement.contentMode == .crop else { return nil }

        let scaleCandidates = [
            min(max(preferredMaximumScale, 1.035), 1.08),
            1.05,
            1.035,
        ]
        let seed = stableHash(photoID)

        for scale in scaleCandidates {
            let plans = candidatePlans(scale: scale)
            let startIndex = Int(seed % UInt64(plans.count))
            for offset in plans.indices {
                let candidate = plans[(startIndex + offset) % plans.count]
                if FrameMotionSafety.canApply(
                    state: candidate.start,
                    placement: placement,
                    importantRects: importantRects
                ), FrameMotionSafety.canApply(
                    state: candidate.end,
                    placement: placement,
                    importantRects: importantRects
                ) {
                    return candidate
                }
            }
        }
        return nil
    }

    private static func candidatePlans(scale: Double) -> [FramePhotoMotionPlan] {
        let centered = FramePhotoMotionState(scale: 1, offsetX: 0, offsetY: 0)
        let zoomed = FramePhotoMotionState(scale: scale, offsetX: 0, offsetY: 0)
        let pan = min(0.018, (scale - 1) * 0.36)
        let left = FramePhotoMotionState(scale: scale, offsetX: -pan, offsetY: 0)
        let right = FramePhotoMotionState(scale: scale, offsetX: pan, offsetY: 0)
        let up = FramePhotoMotionState(scale: scale, offsetX: 0, offsetY: -pan)
        let down = FramePhotoMotionState(scale: scale, offsetX: 0, offsetY: pan)
        let upperLeft = FramePhotoMotionState(
            scale: scale,
            offsetX: -pan * 0.75,
            offsetY: -pan * 0.75
        )
        let lowerRight = FramePhotoMotionState(
            scale: scale,
            offsetX: pan * 0.75,
            offsetY: pan * 0.75
        )
        return [
            FramePhotoMotionPlan(start: centered, end: zoomed),
            FramePhotoMotionPlan(start: zoomed, end: centered),
            FramePhotoMotionPlan(start: left, end: right),
            FramePhotoMotionPlan(start: right, end: left),
            FramePhotoMotionPlan(start: up, end: down),
            FramePhotoMotionPlan(start: down, end: up),
            FramePhotoMotionPlan(start: upperLeft, end: lowerRight),
            FramePhotoMotionPlan(start: lowerRight, end: upperLeft),
        ]
    }

    private static func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
