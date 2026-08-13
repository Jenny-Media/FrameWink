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
        guard placement.contentMode == .crop, maximumScale >= 1 else { return false }
        let protectedRects = importantRects
            .map { $0.clampedToUnitBounds() }
            .filter { $0.width > 0 && $0.height > 0 }
        guard !protectedRects.isEmpty else { return true }

        let crop = placement.sourceCrop
        let visibleWidth = crop.width / maximumScale
        let visibleHeight = crop.height / maximumScale
        let visibleCrop = NormalizedRect(
            x: crop.x + (crop.width - visibleWidth) / 2,
            y: crop.y + (crop.height - visibleHeight) / 2,
            width: visibleWidth,
            height: visibleHeight
        )
        let tolerance = 0.000_001
        return protectedRects.allSatisfy { rect in
            rect.minX >= visibleCrop.minX - tolerance
                && rect.maxX <= visibleCrop.maxX + tolerance
                && rect.minY >= visibleCrop.minY - tolerance
                && rect.maxY <= visibleCrop.maxY + tolerance
        }
    }
}
