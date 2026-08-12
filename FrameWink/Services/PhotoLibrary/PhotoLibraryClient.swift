import Foundation

@MainActor
protocol PhotoLibraryClient: AnyObject {
    func authorizationState() -> PhotoLibraryAuthorizationState
    func requestAuthorization() async -> PhotoLibraryAuthorizationState
    func albums() throws -> [PhotoLibraryAlbum]
    func assets(in albumIdentifier: String) throws -> [PhotoLibraryAsset]
    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws
    func changeEvents() -> AsyncStream<Void>
}

enum PhotoLibraryClientError: LocalizedError, Equatable {
    case accessDenied
    case albumUnavailable
    case assetUnavailable
    case cloudAssetUnavailable
    case imageDataUnavailable

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo access is not available. You can keep using Free Smart Reel or change access in iPad Settings."
        case .albumUnavailable:
            return "That album is no longer available. Choose another album in Wall Mode Setup."
        case .assetUnavailable:
            return "A photo in this album is no longer available."
        case .cloudAssetUnavailable:
            return "A photo is stored only in iCloud and Strict Offline is enabled."
        case .imageDataUnavailable:
            return "Photos could not provide image data for this item."
        }
    }
}
