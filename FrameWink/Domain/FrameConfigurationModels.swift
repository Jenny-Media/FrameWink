import Foundation

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
        interval = min(max(interval, 5), 3_600)
    }
}

struct FrameConfigurationArchive: Codable, Equatable {
    var configurations: [SavedFrameConfiguration]
    var activeConfigurationID: UUID?
}
