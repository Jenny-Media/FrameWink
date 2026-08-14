import Foundation

enum FramePlaybackTiming {
    static let defaultInterval: TimeInterval = 30
    static let availableIntervals: [TimeInterval] = [10, 30, 60, 300]

    static func normalized(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return defaultInterval }

        // Seven seconds was FrameWink's implicit default before timing had a
        // selected UI state. Treat it as the new default rather than as an
        // intentional custom choice.
        if abs(interval - 7) < 0.001 {
            return defaultInterval
        }

        return availableIntervals.min { left, right in
            let leftDistance = abs(left - interval)
            let rightDistance = abs(right - interval)
            if leftDistance == rightDistance {
                return left == defaultInterval
            }
            return leftDistance < rightDistance
        } ?? defaultInterval
    }

    static func title(for interval: TimeInterval) -> String {
        switch Int(interval) {
        case 10: return "10s"
        case 30: return "30s"
        case 60: return "1m"
        case 300: return "5m"
        default: return "30s"
        }
    }
}

enum FrameConfigurationSource: String, CaseIterable, Codable, Identifiable {
    case samples
    case freeSmartReel
    case automaticAlbum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .samples: return "Sample Photos"
        case .freeSmartReel: return "Free Smart Reel"
        case .automaticAlbum: return "Automatic Album"
        }
    }
}

struct SavedFrameConfiguration: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var source: FrameConfigurationSource
    var albumIdentifier: String?
    var albumTitle: String?
    var layoutPreference: FrameLayoutPreference
    var interval: TimeInterval

    mutating func normalize() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { name = "Frame" }
        layoutPreference = .automatic
        interval = FramePlaybackTiming.normalized(interval)
    }
}

struct FrameConfigurationArchive: Codable, Equatable {
    var configurations: [SavedFrameConfiguration]
    var activeConfigurationID: UUID?
}
