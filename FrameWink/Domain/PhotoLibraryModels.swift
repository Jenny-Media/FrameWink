import Foundation

enum PhotoLibraryAuthorizationState: String, Equatable {
    case notDetermined
    case restricted
    case denied
    case limited
    case authorized

    var permitsReading: Bool {
        self == .authorized || self == .limited
    }
}

struct PhotoLibraryAlbum: Identifiable, Equatable {
    let id: String
    let title: String
    let photoCount: Int
}

struct PhotoLibraryAsset: Identifiable, Equatable {
    let id: String
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?
    let modificationDate: Date?
    let isHidden: Bool
    let isScreenshot: Bool
    let burstIdentifier: String?
}

struct AutomaticAlbumConfiguration: Codable, Equatable {
    var albumIdentifier: String?
    var albumTitle: String?
    var automaticRefresh: Bool
    var strictOffline: Bool

    static let defaultConfiguration = AutomaticAlbumConfiguration(
        albumIdentifier: nil,
        albumTitle: nil,
        automaticRefresh: true,
        strictOffline: true
    )

    var isConfigured: Bool {
        guard let albumIdentifier = albumIdentifier else { return false }
        return !albumIdentifier.isEmpty
    }
}

struct CachedAlbumAsset: Codable, Equatable, Identifiable {
    let assetIdentifier: String
    let assetModificationDate: Date?
    let photo: ImportedPhoto
    let isHidden: Bool?
    let isScreenshot: Bool?
    let burstIdentifier: String?

    init(
        assetIdentifier: String,
        assetModificationDate: Date?,
        photo: ImportedPhoto,
        isHidden: Bool? = nil,
        isScreenshot: Bool? = nil,
        burstIdentifier: String? = nil
    ) {
        self.assetIdentifier = assetIdentifier
        self.assetModificationDate = assetModificationDate
        self.photo = photo
        self.isHidden = isHidden
        self.isScreenshot = isScreenshot
        self.burstIdentifier = burstIdentifier
    }

    var id: String { assetIdentifier }

    func candidate(from asset: PhotoLibraryAsset? = nil) -> PhotoCandidate {
        PhotoCandidate(
            id: photo.id,
            source: .photoLibraryAlbum,
            pixelWidth: photo.pixelWidth,
            pixelHeight: photo.pixelHeight,
            creationDate: asset?.creationDate ?? photo.creationDate,
            isHidden: asset?.isHidden ?? isHidden ?? false,
            isScreenshot: asset?.isScreenshot ?? isScreenshot ?? false,
            burstIdentifier: asset?.burstIdentifier ?? burstIdentifier
        )
    }
}

struct AlbumSyncReport: Equatable {
    let records: [CachedAlbumAsset]
    let importedCount: Int
    let refreshedCount: Int
    let removedCount: Int
    let cloudOnlyCount: Int
    let failures: [String]

    var hasPartialFailure: Bool {
        cloudOnlyCount > 0 || !failures.isEmpty
    }
}

enum AutomaticAlbumPhase: Equatable {
    case idle
    case loadingAlbums
    case syncing(ImportProgress)
    case curating(ImportProgress)
    case ready(photoCount: Int, suggestionCount: Int)
    case accessDenied
    case failed(String)
}
