import Foundation

protocol AlbumSynchronizing {
    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> AlbumSyncReport
}

final class AlbumSyncService: AlbumSynchronizing {
    private let client: PhotoLibraryClient
    private let store: AlbumSourceStoring
    private let downsampler: ImageDownsampling
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        client: PhotoLibraryClient,
        store: AlbumSourceStoring,
        downsampler: ImageDownsampling,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.client = client
        self.store = store
        self.downsampler = downsampler
        self.now = now
        self.makeID = makeID
    }

    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> AlbumSyncReport {
        let allAssets = try await client.assets(in: albumIdentifier)
        let assets = allAssets.filter { !$0.isHidden && !$0.isScreenshot }
        var existingByAsset = Dictionary(
            uniqueKeysWithValues: try store.loadRecords().map {
                ($0.assetIdentifier, $0)
            }
        )
        let validAssetIDs = Set(assets.map(\.id))
        let stale = existingByAsset.values.filter {
            !validAssetIDs.contains($0.assetIdentifier)
        }
        for record in stale {
            existingByAsset[record.assetIdentifier] = nil
        }

        var importedCount = 0
        var refreshedCount = 0
        var cloudOnlyCount = 0
        var failures: [String] = []
        var newlyCommittedFilenames: [String] = []
        var supersededFilenames: [String] = []
        await progress(ImportProgress(completedCount: 0, totalCount: assets.count))

        do {
            for (index, asset) in assets.enumerated() {
                try Task.checkCancellation()
                let existing = existingByAsset[asset.id]
                let needsRefresh = existing == nil
                    || existing?.assetModificationDate != asset.modificationDate
                if needsRefresh {
                    let sourceURL = try store.temporaryURL(pathExtension: "source")
                    let downsampledURL = try store.temporaryURL(pathExtension: "jpg")
                    defer {
                        try? FileManager.default.removeItem(at: sourceURL)
                        try? FileManager.default.removeItem(at: downsampledURL)
                    }
                    do {
                        try await client.exportCurrentImage(
                            assetIdentifier: asset.id,
                            to: sourceURL,
                            networkAccessAllowed: !strictOffline
                        )
                        try Task.checkCancellation()
                        let size = try downsampler.downsampleImage(
                            at: sourceURL,
                            to: downsampledURL,
                            maxPixelDimension: 2_560
                        )
                        let photoID = existing?.photo.id ?? makeID()
                        let filename = photoID.uuidString + ".jpg"
                        if existing != nil {
                            let replacementFilename = makeID().uuidString + ".jpg"
                            try store.commitTemporaryImage(
                                at: downsampledURL,
                                filename: replacementFilename
                            )
                            newlyCommittedFilenames.append(replacementFilename)
                            supersededFilenames.append(existing?.photo.filename ?? "")
                            existingByAsset[asset.id] = CachedAlbumAsset(
                                assetIdentifier: asset.id,
                                assetModificationDate: asset.modificationDate,
                                photo: ImportedPhoto(
                                    id: photoID,
                                    filename: replacementFilename,
                                    pixelWidth: size.width,
                                    pixelHeight: size.height,
                                    importedAt: now(),
                                    creationDate: asset.creationDate
                                ),
                                isHidden: asset.isHidden,
                                isScreenshot: asset.isScreenshot,
                                burstIdentifier: asset.burstIdentifier
                            )
                            refreshedCount += 1
                        } else {
                            try store.commitTemporaryImage(
                                at: downsampledURL,
                                filename: filename
                            )
                            newlyCommittedFilenames.append(filename)
                            existingByAsset[asset.id] = CachedAlbumAsset(
                                assetIdentifier: asset.id,
                                assetModificationDate: asset.modificationDate,
                                photo: ImportedPhoto(
                                    id: photoID,
                                    filename: filename,
                                    pixelWidth: size.width,
                                    pixelHeight: size.height,
                                    importedAt: now(),
                                    creationDate: asset.creationDate
                                ),
                                isHidden: asset.isHidden,
                                isScreenshot: asset.isScreenshot,
                                burstIdentifier: asset.burstIdentifier
                            )
                            importedCount += 1
                        }
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch PhotoLibraryClientError.cloudAssetUnavailable {
                        cloudOnlyCount += 1
                    } catch {
                        failures.append(error.localizedDescription)
                    }
                }

                await progress(
                    ImportProgress(
                        completedCount: index + 1,
                        totalCount: assets.count
                    )
                )
            }

            try Task.checkCancellation()
            let records = existingByAsset.values.sorted {
                $0.assetIdentifier < $1.assetIdentifier
            }
            try store.replaceRecords(
                records,
                removingFilenames: stale.map(\.photo.filename) + supersededFilenames
            )
            return AlbumSyncReport(
                records: records,
                importedCount: importedCount,
                refreshedCount: refreshedCount,
                removedCount: stale.count,
                cloudOnlyCount: cloudOnlyCount,
                failures: failures
            )
        } catch {
            for filename in newlyCommittedFilenames {
                store.removeImage(filename: filename)
            }
            throw error
        }
    }
}
