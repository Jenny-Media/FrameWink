import Foundation

protocol AlbumSynchronizing {
    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void,
        checkpoint: @escaping @MainActor (AlbumSyncCheckpoint) async -> Void
    ) async throws -> AlbumSyncReport
}

extension AlbumSynchronizing {
    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> AlbumSyncReport {
        try await synchronize(
            albumIdentifier: albumIdentifier,
            strictOffline: strictOffline,
            progress: progress,
            checkpoint: { _ in }
        )
    }
}

struct AlbumSyncCheckpoint: Equatable {
    let records: [CachedAlbumAsset]
    let preparedRecords: [CachedAlbumAsset]
    let progress: ImportProgress
}

final class AlbumSyncService: AlbumSynchronizing {
    private let client: PhotoLibraryClient
    private let store: AlbumSourceStoring
    private let downsampler: ImageDownsampling
    private let now: () -> Date
    private let makeID: () -> UUID
    private let initialCheckpointCount: Int
    private let checkpointInterval: Int

    init(
        client: PhotoLibraryClient,
        store: AlbumSourceStoring,
        downsampler: ImageDownsampling,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init,
        initialCheckpointCount: Int = 10,
        checkpointInterval: Int = 30
    ) {
        self.client = client
        self.store = store
        self.downsampler = downsampler
        self.now = now
        self.makeID = makeID
        self.initialCheckpointCount = max(initialCheckpointCount, 1)
        self.checkpointInterval = max(checkpointInterval, 1)
    }

    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void,
        checkpoint: @escaping @MainActor (AlbumSyncCheckpoint) async -> Void
    ) async throws -> AlbumSyncReport {
        let allAssets = try await client.assets(in: albumIdentifier)
        let assets = allAssets.filter { !$0.isHidden && !$0.isScreenshot }
        let processingOrder = Self.prioritizedAssets(
            assets,
            initialCount: initialCheckpointCount
        )
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
        var filenamesPendingRemoval = stale.map(\.photo.filename)
        let provisionalCheckpointCounts = Array(
            Set([initialCheckpointCount, checkpointInterval])
        ).sorted()
        var nextProvisionalCheckpointIndex = 0
        await progress(ImportProgress(completedCount: 0, totalCount: assets.count))

        do {
            for (index, asset) in processingOrder.enumerated() {
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
                            if let existingFilename = existing?.photo.filename {
                                filenamesPendingRemoval.append(existingFilename)
                            }
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

                let completedCount = index + 1
                let hasPendingProvisionalCheckpoint = nextProvisionalCheckpointIndex
                    < provisionalCheckpointCounts.count
                let isRecurringCheckpoint = completedCount.isMultiple(
                    of: checkpointInterval
                )
                if (hasPendingProvisionalCheckpoint || isRecurringCheckpoint),
                   completedCount < processingOrder.count {
                    let preparedRecords = processingOrder
                        .prefix(completedCount)
                        .compactMap { existingByAsset[$0.id] }
                    let reachedProvisionalCheckpoint = hasPendingProvisionalCheckpoint
                        && preparedRecords.count
                            >= provisionalCheckpointCounts[nextProvisionalCheckpointIndex]
                    guard reachedProvisionalCheckpoint || isRecurringCheckpoint else {
                        continue
                    }
                    while nextProvisionalCheckpointIndex
                        < provisionalCheckpointCounts.count,
                        preparedRecords.count
                            >= provisionalCheckpointCounts[nextProvisionalCheckpointIndex] {
                        nextProvisionalCheckpointIndex += 1
                    }
                    let checkpointRecords = Self.orderedRecords(existingByAsset)
                    try store.replaceRecords(
                        checkpointRecords,
                        removingFilenames: filenamesPendingRemoval
                    )
                    newlyCommittedFilenames.removeAll(keepingCapacity: true)
                    filenamesPendingRemoval.removeAll(keepingCapacity: true)
                    await checkpoint(
                        AlbumSyncCheckpoint(
                            records: checkpointRecords,
                            preparedRecords: preparedRecords,
                            progress: ImportProgress(
                                completedCount: completedCount,
                                totalCount: assets.count
                            )
                        )
                    )
                    try Task.checkCancellation()
                }
            }

            try Task.checkCancellation()
            let records = Self.orderedRecords(existingByAsset)
            try store.replaceRecords(
                records,
                removingFilenames: filenamesPendingRemoval
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

    nonisolated static func prioritizedAssets(
        _ assets: [PhotoLibraryAsset],
        initialCount: Int
    ) -> [PhotoLibraryAsset] {
        let boundedCount = min(max(initialCount, 1), assets.count)
        guard boundedCount > 1, boundedCount < assets.count else { return assets }

        let lastIndex = assets.count - 1
        let divisor = boundedCount - 1
        let initialIndices = (0..<boundedCount).map { position in
            Int((Double(position) * Double(lastIndex) / Double(divisor)).rounded())
        }
        let initialIndexSet = Set(initialIndices)
        return initialIndices.map { assets[$0] }
            + assets.indices.compactMap { index in
                initialIndexSet.contains(index) ? nil : assets[index]
            }
    }

    private static func orderedRecords(
        _ recordsByAsset: [String: CachedAlbumAsset]
    ) -> [CachedAlbumAsset] {
        recordsByAsset.values.sorted { $0.assetIdentifier < $1.assetIdentifier }
    }
}
