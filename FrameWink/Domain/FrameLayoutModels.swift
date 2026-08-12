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

enum FrameLayoutPreference: String, CaseIterable, Identifiable {
    case automatic
    case fit
    case fill

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Auto"
        case .fit: return "Fit"
        case .fill: return "Fill"
        }
    }
}

enum FrameLayoutKind: String, Equatable {
    case singleFit
    case singleFill
    case pairedPortraits
}

enum FrameContentMode: Equatable {
    case fit
    case crop
}

struct FrameLayoutItem: Identifiable, Equatable {
    let id: String
    let pixelSize: PixelSize
    let importantRects: [NormalizedRect]
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
