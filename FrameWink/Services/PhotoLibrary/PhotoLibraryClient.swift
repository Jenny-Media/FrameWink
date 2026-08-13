import Foundation
import UIKit

@MainActor
protocol PhotoLibraryClient: AnyObject {
    func authorizationState() -> PhotoLibraryAuthorizationState
    func requestAuthorization() async -> PhotoLibraryAuthorizationState
    func albums() async throws -> [PhotoLibraryAlbum]
    func albumThumbnail(
        albumIdentifier: String,
        maxPixelDimension: Int
    ) async -> UIImage?
    func albumThumbnail(
        album: PhotoLibraryAlbum,
        maxPixelDimension: Int,
        progress: @escaping (AlbumThumbnailLoadingPhase) -> Void
    ) async -> UIImage?
    func preheatAlbumThumbnails(
        albums: [PhotoLibraryAlbum],
        maxPixelDimension: Int
    )
    func assets(in albumIdentifier: String) async throws -> [PhotoLibraryAsset]
    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws
    func changeEvents() -> AsyncStream<Void>
}

extension PhotoLibraryClient {
    func albumThumbnail(
        albumIdentifier: String,
        maxPixelDimension: Int
    ) async -> UIImage? {
        nil
    }

    func albumThumbnail(
        album: PhotoLibraryAlbum,
        maxPixelDimension: Int,
        progress: @escaping (AlbumThumbnailLoadingPhase) -> Void
    ) async -> UIImage? {
        progress(.local)
        return await albumThumbnail(
            albumIdentifier: album.id,
            maxPixelDimension: maxPixelDimension
        )
    }

    func preheatAlbumThumbnails(
        albums: [PhotoLibraryAlbum],
        maxPixelDimension: Int
    ) {}
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
            return "That album is no longer available. Choose another album."
        case .assetUnavailable:
            return "A photo in this album is no longer available."
        case .cloudAssetUnavailable:
            return "This photo needs to download from iCloud."
        case .imageDataUnavailable:
            return "Photos could not provide image data for this item."
        }
    }
}
