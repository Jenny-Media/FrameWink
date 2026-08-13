import Foundation
import Photos
import UIKit

@MainActor
final class PhotoKitLibraryClient: NSObject, PhotoLibraryClient {
    private static let displayCacheMaxPixelDimension: CGFloat = 2_560

    private let photoLibrary: PHPhotoLibrary
    private let imageManager: PHImageManager
    private let albumThumbnailCache = NSCache<NSString, UIImage>()
    private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var isObservingChanges = false

    init(
        photoLibrary: PHPhotoLibrary = .shared(),
        imageManager: PHImageManager = .default()
    ) {
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        super.init()
        albumThumbnailCache.countLimit = 80
        albumThumbnailCache.totalCostLimit = 32 * 1_024 * 1_024
    }

    deinit {
        if isObservingChanges {
            photoLibrary.unregisterChangeObserver(self)
        }
    }

    func authorizationState() -> PhotoLibraryAuthorizationState {
        Self.authorizationState(
            from: PHPhotoLibrary.authorizationStatus(for: .readWrite)
        )
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationState {
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
        return Self.authorizationState(from: status)
    }

    func albums() async throws -> [PhotoLibraryAlbum] {
        guard authorizationState().permitsReading else {
            throw PhotoLibraryClientError.accessDenied
        }

        let discovery = Task.detached(priority: .userInitiated) {
            try Self.discoverAlbums()
        }
        return try await withTaskCancellationHandler {
            try await discovery.value
        } onCancel: {
            discovery.cancel()
        }
    }

    func albumThumbnail(
        albumIdentifier: String,
        maxPixelDimension: Int
    ) async -> UIImage? {
        guard authorizationState().permitsReading else { return nil }
        let cacheKey = "\(albumIdentifier)|\(max(maxPixelDimension, 1))" as NSString
        if let cached = albumThumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        let discovery = Task.detached(priority: .utility) {
            try Self.discoverAlbumCoverAssetIdentifier(
                albumIdentifier: albumIdentifier
            )
        }
        let assetIdentifier: String?
        do {
            assetIdentifier = try await withTaskCancellationHandler {
                try await discovery.value
            } onCancel: {
                discovery.cancel()
            }
        } catch {
            return nil
        }
        guard let assetIdentifier,
              let asset = PHAsset.fetchAssets(
                withLocalIdentifiers: [assetIdentifier],
                options: nil
              ).firstObject else {
            return nil
        }

        let dimension = CGFloat(max(maxPixelDimension, 1))
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        let requestState = PhotoKitThumbnailRequestState()
        let image = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                requestState.install(continuation: continuation)
                let requestID = imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: dimension, height: dimension),
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    if (info?[PHImageCancelledKey] as? Bool) == true
                        || info?[PHImageErrorKey] != nil {
                        requestState.finish(nil)
                    } else {
                        requestState.finish(image)
                    }
                }
                requestState.setRequestID(requestID, manager: imageManager)
            }
        } onCancel: {
            requestState.cancel(manager: imageManager)
        }
        if let image {
            let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
            albumThumbnailCache.setObject(image, forKey: cacheKey, cost: cost)
        }
        return image
    }

    nonisolated private static func discoverAlbums() throws -> [PhotoLibraryAlbum] {
        var collections: [PHAssetCollection] = []
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        userAlbums.enumerateObjects { collection, _, _ in
            collections.append(collection)
        }

        let supportedSmartAlbums: [PHAssetCollectionSubtype] = [
            .smartAlbumUserLibrary,
            .smartAlbumFavorites,
            .smartAlbumRecentlyAdded,
        ]
        for subtype in supportedSmartAlbums {
            let fetched = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: subtype,
                options: nil
            )
            fetched.enumerateObjects { collection, _, _ in
                collections.append(collection)
            }
        }

        var seen: Set<String> = []
        let albums: [PhotoLibraryAlbum] = collections.compactMap { collection in
            guard !Task.isCancelled else { return nil }
            guard seen.insert(collection.localIdentifier).inserted else { return nil }
            let estimatedCount = collection.estimatedAssetCount
            return PhotoLibraryAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled Album",
                photoCount: estimatedCount == NSNotFound ? nil : estimatedCount
            )
        }
        try Task.checkCancellation()
        return albums.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    nonisolated private static func discoverAlbumCoverAssetIdentifier(
        albumIdentifier: String
    ) throws -> String? {
        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumIdentifier],
            options: nil
        )
        guard let collection = collections.firstObject else { return nil }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.image.rawValue
        )
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false),
        ]
        let fetched = PHAsset.fetchAssets(in: collection, options: options)
        var identifier: String?
        fetched.enumerateObjects { asset, _, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }
            guard !asset.isHidden,
                  !asset.mediaSubtypes.contains(.photoScreenshot) else {
                return
            }
            identifier = asset.localIdentifier
            stop.pointee = true
        }
        try Task.checkCancellation()
        return identifier
    }

    func assets(in albumIdentifier: String) async throws -> [PhotoLibraryAsset] {
        guard authorizationState().permitsReading else {
            throw PhotoLibraryClientError.accessDenied
        }
        let discovery = Task.detached(priority: .userInitiated) {
            try Self.discoverAssets(in: albumIdentifier)
        }
        return try await withTaskCancellationHandler {
            try await discovery.value
        } onCancel: {
            discovery.cancel()
        }
    }

    nonisolated private static func discoverAssets(
        in albumIdentifier: String
    ) throws -> [PhotoLibraryAsset] {
        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumIdentifier],
            options: nil
        )
        guard let collection = collections.firstObject else {
            throw PhotoLibraryClientError.albumUnavailable
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.image.rawValue
        )
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true),
        ]
        let fetched = PHAsset.fetchAssets(in: collection, options: options)
        var result: [PhotoLibraryAsset] = []
        result.reserveCapacity(fetched.count)
        fetched.enumerateObjects { asset, _, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }
            result.append(
                PhotoLibraryAsset(
                    id: asset.localIdentifier,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    creationDate: asset.creationDate,
                    modificationDate: asset.modificationDate,
                    isHidden: asset.isHidden,
                    isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
                    burstIdentifier: asset.burstIdentifier
                )
            )
        }
        try Task.checkCancellation()
        return result.sorted {
            switch ($0.creationDate, $1.creationDate) {
            case let (left?, right?) where left != right:
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return $0.id < $1.id
            }
        }
    }

    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws {
        let fetched = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetIdentifier],
            options: nil
        )
        guard let asset = fetched.firstObject else {
            throw PhotoLibraryClientError.assetUnavailable
        }

        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = networkAccessAllowed
        let requestState = PhotoKitImageRequestState()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestState.install(continuation: continuation)
                let requestID = imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(
                        width: Self.displayCacheMaxPixelDimension,
                        height: Self.displayCacheMaxPixelDimension
                    ),
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    if (info?[PHImageCancelledKey] as? Bool) == true {
                        requestState.finish(.failure(CancellationError()))
                    } else if let failure = Self.exportFailure(
                        error: info?[PHImageErrorKey] as? Error,
                        isInCloud: (info?[PHImageResultIsInCloudKey] as? Bool) == true,
                        networkAccessAllowed: networkAccessAllowed
                    ) {
                        requestState.finish(.failure(failure))
                    } else if (info?[PHImageResultIsDegradedKey] as? Bool) == true {
                        return
                    } else if let image = image {
                        Self.writeDisplayImage(
                            image,
                            to: destinationURL,
                            requestState: requestState
                        )
                    } else {
                        requestState.finish(
                            .failure(PhotoLibraryClientError.imageDataUnavailable)
                        )
                    }
                }
                requestState.setRequestID(requestID, manager: imageManager)
            }
        } onCancel: {
            requestState.cancel(manager: imageManager)
        }
    }

    nonisolated private static func writeDisplayImage(
        _ image: UIImage,
        to destinationURL: URL,
        requestState: PhotoKitImageRequestState
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                guard let data = image.jpegData(
                    compressionQuality: 0.96
                ) else {
                    requestState.finish(
                        .failure(PhotoLibraryClientError.imageDataUnavailable)
                    )
                    return
                }
                do {
                    try data.write(to: destinationURL, options: .atomic)
                    requestState.finish(.success(()))
                } catch {
                    requestState.finish(.failure(error))
                }
            }
        }
    }

    nonisolated static func exportFailure(
        error: Error?,
        isInCloud: Bool,
        networkAccessAllowed: Bool
    ) -> Error? {
        if !networkAccessAllowed,
           isInCloud || isNetworkAccessRequired(error) {
            return PhotoLibraryClientError.cloudAssetUnavailable
        }
        return error
    }

    nonisolated private static func isNetworkAccessRequired(_ error: Error?) -> Bool {
        guard let error = error as NSError? else { return false }
        return error.domain == PHPhotosErrorDomain
            && error.code == PHPhotosError.networkAccessRequired.rawValue
    }

    func changeEvents() -> AsyncStream<Void> {
        if !isObservingChanges {
            isObservingChanges = true
            photoLibrary.register(self)
        }
        let id = UUID()
        return AsyncStream { continuation in
            changeContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.removeChangeContinuation(id)
                }
            }
        }
    }

    private func removeChangeContinuation(_ id: UUID) {
        changeContinuations[id] = nil
        guard changeContinuations.isEmpty, isObservingChanges else { return }
        photoLibrary.unregisterChangeObserver(self)
        isObservingChanges = false
    }

    private static func authorizationState(
        from status: PHAuthorizationStatus
    ) -> PhotoLibraryAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .limited:
            return .limited
        case .authorized:
            return .authorized
        @unknown default:
            return .restricted
        }
    }
}

extension PhotoKitLibraryClient: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            self?.changeContinuations.values.forEach { $0.yield(()) }
        }
    }
}

private final class PhotoKitImageRequestState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?
    private var requestID = PHInvalidImageRequestID
    private var isCancelled = false
    private var isFinished = false

    func install(continuation: CheckedContinuation<Void, Error>) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else {
            continuation.resume(throwing: CancellationError())
            return
        }
        self.continuation = continuation
    }

    func setRequestID(_ requestID: PHImageRequestID, manager: PHImageManager) {
        lock.lock()
        self.requestID = requestID
        let shouldCancel = isCancelled
        lock.unlock()
        if shouldCancel {
            manager.cancelImageRequest(requestID)
        }
    }

    func cancel(manager: PHImageManager) {
        let continuation: CheckedContinuation<Void, Error>?
        let requestID: PHImageRequestID
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isCancelled = true
        isFinished = true
        continuation = self.continuation
        self.continuation = nil
        requestID = self.requestID
        lock.unlock()

        if requestID != PHInvalidImageRequestID {
            manager.cancelImageRequest(requestID)
        }
        continuation?.resume(throwing: CancellationError())
    }

    func finish(_ result: Result<Void, Error>) {
        let continuation: CheckedContinuation<Void, Error>?
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        switch result {
        case .success:
            continuation?.resume()
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }
}

private final class PhotoKitThumbnailRequestState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<UIImage?, Never>?
    private var requestID = PHInvalidImageRequestID
    private var isFinished = false

    func install(continuation: CheckedContinuation<UIImage?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else {
            continuation.resume(returning: nil)
            return
        }
        self.continuation = continuation
    }

    func setRequestID(_ requestID: PHImageRequestID, manager: PHImageManager) {
        lock.lock()
        self.requestID = requestID
        let shouldCancel = isFinished
        lock.unlock()
        if shouldCancel {
            manager.cancelImageRequest(requestID)
        }
    }

    func cancel(manager: PHImageManager) {
        let continuation: CheckedContinuation<UIImage?, Never>?
        let requestID: PHImageRequestID
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        continuation = self.continuation
        self.continuation = nil
        requestID = self.requestID
        lock.unlock()

        if requestID != PHInvalidImageRequestID {
            manager.cancelImageRequest(requestID)
        }
        continuation?.resume(returning: nil)
    }

    func finish(_ image: UIImage?) {
        let continuation: CheckedContinuation<UIImage?, Never>?
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: image)
    }
}
