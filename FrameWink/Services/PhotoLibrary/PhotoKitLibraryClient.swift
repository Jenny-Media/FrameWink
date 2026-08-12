import Foundation
import Photos

@MainActor
final class PhotoKitLibraryClient: NSObject, PhotoLibraryClient {
    private let photoLibrary: PHPhotoLibrary
    private let imageManager: PHImageManager
    private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var isObservingChanges = false

    init(
        photoLibrary: PHPhotoLibrary = .shared(),
        imageManager: PHImageManager = .default()
    ) {
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        super.init()
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

    func albums() throws -> [PhotoLibraryAlbum] {
        guard authorizationState().permitsReading else {
            throw PhotoLibraryClientError.accessDenied
        }

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
        return collections.compactMap { collection in
            guard seen.insert(collection.localIdentifier).inserted else { return nil }
            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "mediaType == %d",
                PHAssetMediaType.image.rawValue
            )
            let count = PHAsset.fetchAssets(in: collection, options: options).count
            return PhotoLibraryAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled Album",
                photoCount: count
            )
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func assets(in albumIdentifier: String) throws -> [PhotoLibraryAsset] {
        guard authorizationState().permitsReading else {
            throw PhotoLibraryClientError.accessDenied
        }
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
        fetched.enumerateObjects { asset, _, _ in
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
        options.isNetworkAccessAllowed = networkAccessAllowed
        let requestState = PhotoKitImageRequestState()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestState.install(continuation: continuation)
                let requestID = imageManager.requestImageDataAndOrientation(
                    for: asset,
                    options: options
                ) { data, _, _, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        requestState.finish(.failure(error))
                    } else if (info?[PHImageCancelledKey] as? Bool) == true {
                        requestState.finish(.failure(CancellationError()))
                    } else if data == nil,
                              (info?[PHImageResultIsInCloudKey] as? Bool) == true {
                        requestState.finish(
                            .failure(PhotoLibraryClientError.cloudAssetUnavailable)
                        )
                    } else if let data = data {
                        do {
                            try data.write(to: destinationURL, options: .atomic)
                            requestState.finish(.success(()))
                        } catch {
                            requestState.finish(.failure(error))
                        }
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
