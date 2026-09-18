import Foundation
import SwiftUI
import UIKit

@MainActor
final class AutomaticAlbumController: ObservableObject {
    private static let minimumInitialCandidateCount = 10
    private static let refinedCandidateCount = 30

    @Published private(set) var authorization: PhotoLibraryAuthorizationState
    @Published private(set) var albums: [PhotoLibraryAlbum] = []
    @Published private(set) var albumCatalogPhase: AlbumCatalogLoadingPhase = .idle
    @Published private(set) var configuration: AutomaticAlbumConfiguration
    @Published private(set) var records: [CachedAlbumAsset] = []
    @Published private(set) var smartReel: SmartReel?
    @Published private(set) var phase: AutomaticAlbumPhase = .idle
    @Published private(set) var lastSyncReport: AlbumSyncReport?
    @Published private(set) var excludedPhotoIDs: Set<UUID> = []
    @Published private(set) var isDeletingCachedAlbum = false
    @Published private(set) var isCleaningAlbumSpace = false
    @Published private(set) var lastFreedAlbumBytes: Int64?

    private let client: PhotoLibraryClient
    private let store: AlbumSourceStoring
    private let synchronizer: AlbumSynchronizing
    private let smartReelBuilder: SmartReelBuilding
    private let displayHistoryStore: DisplayHistoryStoring?
    private let changeRefreshDelayNanoseconds: UInt64
    private let availableStorageBytes: () -> Int64?
    private var isEntitled = false
    private var syncTask: Task<Void, Never>?
    private var albumCatalogTask: Task<Void, Never>?
    private var albumCountTask: Task<Void, Never>?
    private var albumCatalogGeneration = UUID()
    private var observationTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var generation = UUID()
    private var lastProgressUpdate = Date.distantPast
    private var isRefreshInProgress = false
    private var shouldBuildProvisionalReels = false
    private var provisionalCandidateCount = 0
    private var preheatedAlbumCatalogKey: String?
    private var mostRecentExclusion: (selection: CuratedPhoto, index: Int)?
    private var imageRestoreTasks: [UUID: Task<UIImage?, Never>] = [:]

    init(
        client: PhotoLibraryClient,
        store: AlbumSourceStoring,
        synchronizer: AlbumSynchronizing,
        smartReelBuilder: SmartReelBuilding,
        displayHistoryStore: DisplayHistoryStoring? = nil,
        changeRefreshDelayNanoseconds: UInt64 = 1_000_000_000,
        availableStorageBytes: @escaping () -> Int64? = LocalStorageUsage.systemAvailableStorageBytes
    ) {
        self.client = client
        self.store = store
        self.synchronizer = synchronizer
        self.smartReelBuilder = smartReelBuilder
        self.displayHistoryStore = displayHistoryStore
        self.changeRefreshDelayNanoseconds = changeRefreshDelayNanoseconds
        self.availableStorageBytes = availableStorageBytes
        authorization = client.authorizationState()
        var loadedConfiguration = store.loadConfiguration()
        if loadedConfiguration.strictOffline {
            loadedConfiguration.strictOffline = false
            try? store.saveConfiguration(loadedConfiguration)
        }
        configuration = loadedConfiguration
        records = (try? store.loadRecords()) ?? []
        excludedPhotoIDs = (try? smartReelBuilder.loadExclusions()) ?? []
        if store.savedReelBelongsToCurrentAlbum(),
           let saved = try? smartReelBuilder.loadSavedReel() {
            let availableIDs = Set(records.filter {
                store.containsImage(filename: $0.photo.filename)
            }.map(\.photo.id))
            let selections = saved.selections.filter {
                availableIDs.contains($0.candidateID)
            }
            if !selections.isEmpty {
                smartReel = SmartReel(
                    id: saved.id,
                    algorithmRevision: saved.algorithmRevision,
                    createdAt: saved.createdAt,
                    selections: selections
                )
                phase = .ready(
                    photoCount: records.count,
                    suggestionCount: selections.count
                )
            }
        }
    }

    deinit {
        syncTask?.cancel()
        albumCatalogTask?.cancel()
        albumCountTask?.cancel()
        observationTask?.cancel()
        debounceTask?.cancel()
    }

    var selectedAlbumTitle: String {
        configuration.albumTitle ?? "No album selected"
    }

    var canDisplay: Bool {
        isEntitled
            && authorization.permitsReading
            && configuration.isConfigured
            && smartReel?.selections.isEmpty == false
    }

    var reviewPhotos: [ImportedPhoto] {
        guard let smartReel = smartReel else { return [] }
        let photosByID = Dictionary(
            uniqueKeysWithValues: records.map { ($0.photo.id, $0.photo) }
        )
        return smartReel.selections.compactMap { photosByID[$0.candidateID] }
    }

    var excludedReviewPhotos: [ImportedPhoto] {
        records.map(\.photo).filter { excludedPhotoIDs.contains($0.id) }
    }

    var slides: [DisplaySlide] {
        guard canDisplay, let smartReel = smartReel else { return [] }
        let recordsByID = Dictionary(
            uniqueKeysWithValues: records.map { ($0.photo.id, $0) }
        )
        return smartReel.selections.compactMap { selection -> DisplaySlide? in
            guard let record = recordsByID[selection.candidateID] else { return nil }
            return DisplaySlide(
                id: "album-" + record.photo.id.uuidString,
                title: LocalizedStringKey(selectedAlbumTitle),
                caption: "Selected privately on this device",
                accessibilityLabel: "A photo selected from your automatic album",
                source: .automaticAlbum(record.photo),
                importantRects: selection.importantRects
            )
        }
    }

    func setEntitled(_ entitled: Bool) {
        guard isEntitled != entitled else { return }
        isEntitled = entitled
        if entitled {
            authorization = client.authorizationState()
            startObservingIfNeeded()
            if configuration.isConfigured && authorization.permitsReading {
                refresh()
            }
        } else {
            generation = UUID()
            albumCatalogTask?.cancel()
            albumCatalogTask = nil
            albumCountTask?.cancel()
            albumCountTask = nil
            albumCatalogGeneration = UUID()
            albumCatalogPhase = .idle
            syncTask?.cancel()
            syncTask = nil
            isRefreshInProgress = false
            debounceTask?.cancel()
            observationTask?.cancel()
            observationTask = nil
        }
    }

    func refreshAuthorizationAfterForegrounding() {
        let previous = authorization
        let updated = client.authorizationState()
        authorization = updated
        if updated.permitsReading {
            startObservingIfNeeded()
            if configuration.isConfigured && !previous.permitsReading {
                refresh()
            }
        } else if configuration.isConfigured {
            generation = UUID()
            syncTask?.cancel()
            syncTask = nil
            isRefreshInProgress = false
            debounceTask?.cancel()
            observationTask?.cancel()
            observationTask = nil
            phase = .accessDenied
        }
    }

    func requestAccessAndLoadAlbums() {
        guard isEntitled else { return }
        let hasCachedCatalog = !albums.isEmpty
        albumCatalogPhase = .loading
        if !hasCachedCatalog {
            phase = .loadingAlbums
        }
        albumCatalogTask?.cancel()
        albumCountTask?.cancel()
        albumCatalogGeneration = UUID()
        let catalogGeneration = albumCatalogGeneration
        albumCatalogTask = Task { [weak self] in
            guard let self = self else { return }
            var status = client.authorizationState()
            if status == .notDetermined {
                status = await client.requestAuthorization()
            }
            guard isEntitled else { return }
            authorization = status
            guard status.permitsReading else {
                albums = []
                albumCatalogPhase = .idle
                preheatedAlbumCatalogKey = nil
                phase = .accessDenied
                return
            }
            do {
                let discoveredAlbums = try await client.albums()
                try Task.checkCancellation()
                albums = discoveredAlbums
                albumCatalogPhase = .idle
                if phase == .loadingAlbums {
                    phase = currentReadyPhase
                }
                startObservingIfNeeded()
                preheatAlbumCovers(maxPixelDimension: 384)
                loadEligiblePhotoCounts(
                    for: discoveredAlbums,
                    catalogGeneration: catalogGeneration
                )
            } catch is CancellationError {
                return
            } catch {
                albumCatalogPhase = .failed(error.localizedDescription)
                if albums.isEmpty {
                    phase = .failed(error.localizedDescription)
                } else if phase == .loadingAlbums {
                    phase = currentReadyPhase
                }
            }
        }
    }

    private func loadEligiblePhotoCounts(
        for discoveredAlbums: [PhotoLibraryAlbum],
        catalogGeneration: UUID
    ) {
        albumCountTask?.cancel()
        albumCountTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            for album in discoveredAlbums {
                guard !Task.isCancelled else { return }
                let count: Int
                do {
                    guard let discoveredCount = try await client.eligiblePhotoCount(in: album) else {
                        continue
                    }
                    count = discoveredCount
                } catch is CancellationError {
                    return
                } catch {
                    continue
                }
                guard !Task.isCancelled,
                      self.albumCatalogGeneration == catalogGeneration,
                      let index = self.albums.firstIndex(where: { $0.id == album.id }) else {
                    return
                }
                self.albums[index] = self.albums[index].updatingPhotoCount(count)
                await Task.yield()
            }
            guard !Task.isCancelled else { return }
            self.albumCountTask = nil
        }
    }

    func preheatAlbumCovers(maxPixelDimension: Int) {
        guard !albums.isEmpty else { return }
        let dimension = min(max(maxPixelDimension, 1), 768)
        let initialAlbums = Array(albums.prefix(18))
        let coverRevision = initialAlbums.flatMap { album in
            [album.id] + Array(album.coverAssetIdentifiers.prefix(1))
        }
        let catalogKey = ([String(dimension)] + coverRevision).joined(separator: "|")
        guard preheatedAlbumCatalogKey != catalogKey else { return }
        preheatedAlbumCatalogKey = catalogKey
        client.preheatAlbumThumbnails(
            albums: initialAlbums,
            maxPixelDimension: dimension
        )
    }

    func selectAlbum(_ album: PhotoLibraryAlbum) {
        cancelAlbumCountLoading()
        let isSwitchingAlbums = configuration.albumIdentifier != album.id
        var updatedConfiguration = configuration
        updatedConfiguration.albumIdentifier = album.id
        updatedConfiguration.albumTitle = album.title
        do {
            try store.saveConfiguration(updatedConfiguration)
            configuration = updatedConfiguration
            if isSwitchingAlbums {
                smartReel = nil
                records = []
            }
            refresh()
            startObservingIfNeeded()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func cancelAlbumCountLoading() {
        albumCountTask?.cancel()
        albumCountTask = nil
        albumCatalogGeneration = UUID()
    }

    func setAutomaticRefresh(_ enabled: Bool) {
        guard configuration.automaticRefresh != enabled else { return }
        var updatedConfiguration = configuration
        updatedConfiguration.automaticRefresh = enabled
        guard persistConfiguration(updatedConfiguration) else { return }
        if enabled {
            startObservingIfNeeded()
        } else {
            observationTask?.cancel()
            observationTask = nil
        }
    }

    func setStrictOffline(_ enabled: Bool) {
        guard configuration.strictOffline != enabled else { return }
        var updatedConfiguration = configuration
        updatedConfiguration.strictOffline = enabled
        guard persistConfiguration(updatedConfiguration) else { return }
        if configuration.isConfigured {
            refresh()
        }
    }

    func refresh() {
        guard !isDeletingCachedAlbum, !isCleaningAlbumSpace else { return }
        guard isEntitled else { return }
        guard authorization.permitsReading,
              let albumIdentifier = configuration.albumIdentifier else {
            if configuration.isConfigured { phase = .accessDenied }
            return
        }

        let previousSync = syncTask
        previousSync?.cancel()
        generation = UUID()
        let currentGeneration = generation
        lastProgressUpdate = .distantPast
        isRefreshInProgress = true
        shouldBuildProvisionalReels = smartReel == nil
        provisionalCandidateCount = 0
        phase = .syncing(ImportProgress(completedCount: 0, totalCount: 0))
        syncTask = Task { [weak self] in
            guard let self = self else { return }
            defer {
                if generation == currentGeneration {
                    isRefreshInProgress = false
                    syncTask = nil
                }
            }
            do {
                // Album changes share one image store. Let the cancelled sync
                // finish its rollback before a new album reads or writes it.
                await previousSync?.value
                try Task.checkCancellation()
                guard generation == currentGeneration else { return }
                let report = try await synchronizer.synchronize(
                    albumIdentifier: albumIdentifier,
                    strictOffline: configuration.strictOffline
                ) { [weak self] progress in
                    guard let self = self, self.generation == currentGeneration else {
                        return
                    }
                    self.publishProgress(progress, phase: AutomaticAlbumPhase.syncing)
                } checkpoint: { [weak self] checkpoint in
                    guard let self = self,
                          self.generation == currentGeneration else {
                        return
                    }
                    let store = self.store
                    let availableStorageBytes = self.availableStorageBytes
                    let (cachedBytes, availableBytes) = await Task.detached(priority: .utility) {
                        (store.cachedImageBytes(), availableStorageBytes())
                    }.value
                    let overBudget = cachedBytes
                        > PhotoStoragePolicy.automaticAlbumBudget(
                            availableStorageBytes: availableBytes,
                            cachedImageBytes: cachedBytes
                        )
                    var targetCount: Int?
                    if self.shouldBuildProvisionalReels {
                        if checkpoint.preparedRecords.count >= Self.refinedCandidateCount,
                           self.provisionalCandidateCount < Self.refinedCandidateCount {
                            targetCount = Self.refinedCandidateCount
                        } else if self.provisionalCandidateCount
                            < Self.minimumInitialCandidateCount,
                            checkpoint.preparedRecords.count
                                >= Self.minimumInitialCandidateCount {
                            targetCount = Self.minimumInitialCandidateCount
                        }
                    }
                    guard overBudget || targetCount != nil else { return }
                    self.records = checkpoint.records
                    do {
                        try await self.curate(
                            currentGeneration: currentGeneration,
                            candidateRecords: overBudget
                                ? checkpoint.records
                                : Array(checkpoint.preparedRecords.prefix(targetCount ?? 0))
                        )
                        guard self.generation == currentGeneration else { return }
                        if let targetCount {
                            self.provisionalCandidateCount = targetCount
                        }
                        if overBudget {
                            _ = try await self.pruneCachedAlbumImages(force: false)
                        }
                    } catch is CancellationError {
                        return
                    } catch {
                        // Keep synchronizing. A later checkpoint or the final
                        // complete album can still produce the first reel.
                    }
                }
                try Task.checkCancellation()
                guard generation == currentGeneration else { return }
                records = report.records
                lastSyncReport = report
                shouldBuildProvisionalReels = false
                try await curate(currentGeneration: currentGeneration)
                _ = try await pruneCachedAlbumImages(force: false)
            } catch is CancellationError {
                return
            } catch PhotoLibraryClientError.accessDenied {
                authorization = client.authorizationState()
                phase = .accessDenied
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func neverShow(candidateID: UUID) {
        guard let smartReel = smartReel,
              let index = smartReel.selections.firstIndex(where: {
                  $0.candidateID == candidateID
              }) else {
            return
        }
        do {
            let selection = smartReel.selections[index]
            let updated = try smartReelBuilder.exclude(
                candidateID: candidateID,
                from: smartReel
            )
            self.smartReel = updated
            excludedPhotoIDs.insert(candidateID)
            mostRecentExclusion = (selection, index)
            phase = .ready(
                photoCount: records.count,
                suggestionCount: updated.selections.count
            )
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    var canUndoNeverShow: Bool {
        mostRecentExclusion != nil
    }

    func undoNeverShow() {
        guard let smartReel,
              let mostRecentExclusion else {
            return
        }
        do {
            let restored = try smartReelBuilder.restore(
                selection: mostRecentExclusion.selection,
                at: mostRecentExclusion.index,
                to: smartReel
            )
            self.smartReel = restored
            excludedPhotoIDs.remove(mostRecentExclusion.selection.candidateID)
            self.mostRecentExclusion = nil
            phase = .ready(
                photoCount: records.count,
                suggestionCount: restored.selections.count
            )
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func clearNeverShowUndo() {
        mostRecentExclusion = nil
    }

    func resetNeverShowChoices() {
        do {
            try smartReelBuilder.resetExclusions()
            excludedPhotoIDs.removeAll()
            smartReel = nil
            mostRecentExclusion = nil
            recurateCachedPhotos()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func restoreNeverShowChoice(candidateID: UUID) {
        do {
            try smartReelBuilder.restoreExcluded(candidateID: candidateID)
            excludedPhotoIDs.remove(candidateID)
            if mostRecentExclusion?.selection.candidateID == candidateID {
                mostRecentExclusion = nil
            }
            recurateCachedPhotos()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        guard let record = records.first(where: { $0.photo.id == photo.id }) else {
            return await store.image(for: photo)
        }
        return await loadImage(for: record)
    }

    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int = 640) async -> UIImage? {
        if !store.containsImage(filename: photo.filename),
           let record = records.first(where: { $0.photo.id == photo.id }) {
            _ = await loadImage(for: record)
        }
        return await store.thumbnail(for: photo, maxPixelDimension: maxPixelDimension)
    }

    private func loadImage(for record: CachedAlbumAsset) async -> UIImage? {
        if let image = await store.image(for: record.photo) { return image }
        guard authorization.permitsReading, configuration.isConfigured else { return nil }
        if let existing = imageRestoreTasks[record.photo.id] {
            return await existing.value
        }

        let task = Task { [client, store] () -> UIImage? in
            guard LocalStorageUsage.systemAvailableStorageBytes().map({
                $0 >= PhotoStoragePolicy.minimumFreeStorageBytes
            }) ?? true else { return nil }
            guard let sourceURL = try? store.temporaryURL(pathExtension: "source"),
                  let imageURL = try? store.temporaryURL(pathExtension: "jpg") else {
                return nil
            }
            defer {
                try? FileManager.default.removeItem(at: sourceURL)
                try? FileManager.default.removeItem(at: imageURL)
            }
            do {
                try await client.exportCurrentImage(
                    assetIdentifier: record.assetIdentifier,
                    to: sourceURL,
                    networkAccessAllowed: true
                )
                try Task.checkCancellation()
                try await Task.detached(priority: .userInitiated) {
                    _ = try ImageIODownsampler().downsampleImage(
                        at: sourceURL,
                        to: imageURL,
                        maxPixelDimension: 2_560
                    )
                    store.removeImage(filename: record.photo.filename)
                    try store.commitTemporaryImage(
                        at: imageURL,
                        filename: record.photo.filename
                    )
                }.value
                return await store.image(for: record.photo)
            } catch {
                return nil
            }
        }
        imageRestoreTasks[record.photo.id] = task
        let image = await task.value
        imageRestoreTasks[record.photo.id] = nil
        return image
    }

    func thumbnail(
        for album: PhotoLibraryAlbum,
        maxPixelDimension: Int = 384,
        progress: @escaping (AlbumThumbnailLoadingPhase) -> Void = { _ in }
    ) async -> UIImage? {
        await client.albumThumbnail(
            album: album,
            maxPixelDimension: maxPixelDimension,
            progress: progress
        )
    }

    func recordDisplayed(_ photo: ImportedPhoto, at date: Date = Date()) {
        try? displayHistoryStore?.recordDisplayed(candidateID: photo.id, at: date)
    }

    func freeUpAlbumSpace() async -> Int64? {
        guard !isCleaningAlbumSpace, !isDeletingCachedAlbum else { return nil }
        isCleaningAlbumSpace = true
        generation = UUID()
        let taskToStop = syncTask
        taskToStop?.cancel()
        await taskToStop?.value
        syncTask = nil
        isRefreshInProgress = false
        do {
            let removedBytes = try await pruneCachedAlbumImages(force: true)
            lastFreedAlbumBytes = removedBytes
            phase = currentReadyPhase
            isCleaningAlbumSpace = false
            return removedBytes
        } catch {
            phase = .failed(error.localizedDescription)
            isCleaningAlbumSpace = false
            return nil
        }
    }

    private func pruneCachedAlbumImages(force: Bool) async throws -> Int64 {
        let keepIDs = Set(smartReel?.selections.map(\.candidateID) ?? [])
            .union(imageRestoreTasks.keys)
        let store = store
        let availableStorageBytes = availableStorageBytes
        return try await Task.detached(priority: .utility) {
            if force {
                return try store.pruneCachedImages(keepingPhotoIDs: keepIDs)
            }
            let cachedBytes = store.cachedImageBytes()
            return try store.pruneCachedImagesToBudget(
                keepingPhotoIDs: keepIDs,
                budgetBytes: PhotoStoragePolicy.automaticAlbumBudget(
                    availableStorageBytes: availableStorageBytes(),
                    cachedImageBytes: cachedBytes
                )
            )
        }.value
    }

    func deleteCachedAlbum() async -> Bool {
        guard !isDeletingCachedAlbum, !isCleaningAlbumSpace else { return false }
        isDeletingCachedAlbum = true
        generation = UUID()
        albumCatalogTask?.cancel()
        albumCatalogTask = nil
        albumCountTask?.cancel()
        albumCountTask = nil
        albumCatalogGeneration = UUID()
        let taskToStop = syncTask
        taskToStop?.cancel()
        isRefreshInProgress = false
        debounceTask?.cancel()
        await taskToStop?.value
        syncTask = nil
        let restoreTasks = Array(imageRestoreTasks.values)
        restoreTasks.forEach { $0.cancel() }
        for task in restoreTasks { _ = await task.value }
        imageRestoreTasks.removeAll()
        do {
            let store = store
            try await Task.detached(priority: .userInitiated) {
                try store.deleteAllCachedData()
            }.value
            records = []
            smartReel = nil
            excludedPhotoIDs.removeAll()
            albums = []
            albumCatalogPhase = .idle
            preheatedAlbumCatalogKey = nil
            configuration = .defaultConfiguration
            lastSyncReport = nil
            lastFreedAlbumBytes = nil
            phase = .idle
            observationTask?.cancel()
            observationTask = nil
            isDeletingCachedAlbum = false
            return true
        } catch {
            phase = .failed(error.localizedDescription)
            isDeletingCachedAlbum = false
            return false
        }
    }

    private func curate(
        currentGeneration: UUID,
        candidateRecords: [CachedAlbumAsset]? = nil
    ) async throws {
        let recordsToCurate = candidateRecords ?? records
        guard !recordsToCurate.isEmpty else {
            smartReel = nil
            phase = .failed("No usable photos were found in this album. Choose another album or try again.")
            return
        }
        let recordsByID = Dictionary(
            uniqueKeysWithValues: recordsToCurate.map { ($0.photo.id, $0) }
        )
        let reel = try await smartReelBuilder.buildUnbounded(
            candidates: recordsToCurate.map { $0.candidate() },
            maximumSelectionCount: min(max(recordsToCurate.count, 30), 100),
            imageProvider: { [weak self] id in
                guard let record = recordsByID[id] else { return nil }
                return await self?.loadImage(for: record)
            },
            progress: { [weak self] progress in
                guard let self = self, self.generation == currentGeneration else {
                    return
                }
                self.publishProgress(progress, phase: AutomaticAlbumPhase.curating)
            }
        )
        try Task.checkCancellation()
        guard generation == currentGeneration else { return }
        var readySelections: [CuratedPhoto] = []
        for selection in reel.selections {
            try Task.checkCancellation()
            guard let record = recordsByID[selection.candidateID] else { continue }
            let isCached = store.containsImage(filename: record.photo.filename)
            let isAvailable = isCached ? true : await loadImage(for: record) != nil
            if isAvailable {
                readySelections.append(selection)
            }
        }
        guard !readySelections.isEmpty else { throw SmartReelBuildError.noUsablePhotos }
        let readyReel = SmartReel(
            id: reel.id,
            algorithmRevision: reel.algorithmRevision,
            createdAt: reel.createdAt,
            selections: readySelections
        )
        smartReel = readyReel
        try store.markSavedReelForCurrentAlbum()
        phase = .ready(
            photoCount: records.count,
            suggestionCount: readyReel.selections.count
        )
    }

    private func recurateCachedPhotos() {
        guard !records.isEmpty else {
            refresh()
            return
        }
        syncTask?.cancel()
        generation = UUID()
        let currentGeneration = generation
        isRefreshInProgress = false
        phase = .curating(
            ImportProgress(completedCount: 0, totalCount: records.count)
        )
        syncTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if generation == currentGeneration {
                    syncTask = nil
                }
            }
            do {
                try await curate(currentGeneration: currentGeneration)
            } catch is CancellationError {
                return
            } catch {
                guard generation == currentGeneration else { return }
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private var currentReadyPhase: AutomaticAlbumPhase {
        if let count = smartReel?.selections.count, count > 0 {
            return .ready(photoCount: records.count, suggestionCount: count)
        }
        return .idle
    }

    private func publishProgress(
        _ progress: ImportProgress,
        phase: (ImportProgress) -> AutomaticAlbumPhase
    ) {
        let now = Date()
        guard progress.completedCount == progress.totalCount
            || now.timeIntervalSince(lastProgressUpdate) >= 0.1 else {
            return
        }
        lastProgressUpdate = now
        self.phase = phase(progress)
    }

    @discardableResult
    private func persistConfiguration(
        _ updatedConfiguration: AutomaticAlbumConfiguration
    ) -> Bool {
        do {
            try store.saveConfiguration(updatedConfiguration)
            configuration = updatedConfiguration
            return true
        } catch {
            phase = .failed(error.localizedDescription)
            return false
        }
    }

    private func startObservingIfNeeded() {
        guard isEntitled,
              authorization.permitsReading,
              configuration.isConfigured,
              configuration.automaticRefresh,
              observationTask == nil else {
            return
        }
        observationTask = Task { [weak self, client] in
            for await _ in client.changeEvents() {
                guard let self = self, !Task.isCancelled else { return }
                self.scheduleRefreshAfterChange()
            }
        }
    }

    private func scheduleRefreshAfterChange() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: self.changeRefreshDelayNanoseconds)
            guard !Task.isCancelled else { return }
            guard !self.isRefreshInProgress else { return }
            self.refresh()
        }
    }
}
