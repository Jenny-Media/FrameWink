import Foundation
import SwiftUI
import UIKit

@MainActor
final class AutomaticAlbumController: ObservableObject {
    @Published private(set) var authorization: PhotoLibraryAuthorizationState
    @Published private(set) var albums: [PhotoLibraryAlbum] = []
    @Published private(set) var configuration: AutomaticAlbumConfiguration
    @Published private(set) var records: [CachedAlbumAsset] = []
    @Published private(set) var smartReel: SmartReel?
    @Published private(set) var phase: AutomaticAlbumPhase = .idle
    @Published private(set) var lastSyncReport: AlbumSyncReport?

    private let client: PhotoLibraryClient
    private let store: AlbumSourceStoring
    private let synchronizer: AlbumSynchronizing
    private let smartReelBuilder: SmartReelBuilding
    private let displayHistoryStore: DisplayHistoryStoring?
    private let changeRefreshDelayNanoseconds: UInt64
    private var isEntitled = false
    private var syncTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var generation = UUID()
    private var lastProgressUpdate = Date.distantPast

    init(
        client: PhotoLibraryClient,
        store: AlbumSourceStoring,
        synchronizer: AlbumSynchronizing,
        smartReelBuilder: SmartReelBuilding,
        displayHistoryStore: DisplayHistoryStoring? = nil,
        changeRefreshDelayNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.client = client
        self.store = store
        self.synchronizer = synchronizer
        self.smartReelBuilder = smartReelBuilder
        self.displayHistoryStore = displayHistoryStore
        self.changeRefreshDelayNanoseconds = changeRefreshDelayNanoseconds
        authorization = client.authorizationState()
        configuration = store.loadConfiguration()
        records = (try? store.loadRecords()) ?? []
        if let saved = try? smartReelBuilder.loadSavedReel() {
            let availableIDs = Set(records.map(\.photo.id))
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

    var slides: [DisplaySlide] {
        guard canDisplay, let smartReel = smartReel else { return [] }
        let recordsByID = Dictionary(
            uniqueKeysWithValues: records.map { ($0.photo.id, $0) }
        )
        return smartReel.selections.compactMap { selection in
            guard let record = recordsByID[selection.candidateID] else { return nil }
            return DisplaySlide(
                id: "album-" + record.photo.id.uuidString,
                title: "Automatic album selection",
                caption: LocalizedStringKey(
                    "Refreshed privately from \(selectedAlbumTitle)"
                ),
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
            syncTask?.cancel()
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
            debounceTask?.cancel()
            observationTask?.cancel()
            observationTask = nil
            phase = .accessDenied
        }
    }

    func requestAccessAndLoadAlbums() {
        guard isEntitled else { return }
        phase = .loadingAlbums
        Task { [weak self] in
            guard let self = self else { return }
            var status = client.authorizationState()
            if status == .notDetermined {
                status = await client.requestAuthorization()
            }
            guard isEntitled else { return }
            authorization = status
            guard status.permitsReading else {
                albums = []
                phase = .accessDenied
                return
            }
            do {
                albums = try await client.albums()
                phase = currentReadyPhase
                startObservingIfNeeded()
            } catch {
                albums = []
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func selectAlbum(_ album: PhotoLibraryAlbum) {
        let isSwitchingAlbums = configuration.albumIdentifier != album.id
        var updatedConfiguration = configuration
        updatedConfiguration.albumIdentifier = album.id
        updatedConfiguration.albumTitle = album.title
        do {
            try store.saveConfiguration(updatedConfiguration)
            configuration = updatedConfiguration
            if isSwitchingAlbums {
                smartReel = nil
            }
            refresh()
            startObservingIfNeeded()
        } catch {
            phase = .failed(error.localizedDescription)
        }
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
        _ = persistConfiguration(updatedConfiguration)
    }

    func refresh() {
        guard isEntitled else { return }
        guard authorization.permitsReading,
              let albumIdentifier = configuration.albumIdentifier else {
            if configuration.isConfigured { phase = .accessDenied }
            return
        }

        syncTask?.cancel()
        generation = UUID()
        let currentGeneration = generation
        lastProgressUpdate = .distantPast
        phase = .syncing(ImportProgress(completedCount: 0, totalCount: 0))
        syncTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let report = try await synchronizer.synchronize(
                    albumIdentifier: albumIdentifier,
                    strictOffline: configuration.strictOffline
                ) { [weak self] progress in
                    guard let self = self, self.generation == currentGeneration else {
                        return
                    }
                    self.publishProgress(progress, phase: AutomaticAlbumPhase.syncing)
                }
                try Task.checkCancellation()
                guard generation == currentGeneration else { return }
                records = report.records
                lastSyncReport = report
                try await curate(currentGeneration: currentGeneration)
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
        guard let smartReel = smartReel else { return }
        do {
            let updated = try smartReelBuilder.exclude(
                candidateID: candidateID,
                from: smartReel
            )
            self.smartReel = updated
            phase = .ready(
                photoCount: records.count,
                suggestionCount: updated.selections.count
            )
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func resetNeverShowChoices() {
        do {
            try smartReelBuilder.resetExclusions()
            smartReel = nil
            refresh()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        await store.image(for: photo)
    }

    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int = 640) async -> UIImage? {
        await store.thumbnail(for: photo, maxPixelDimension: maxPixelDimension)
    }

    func recordDisplayed(_ photo: ImportedPhoto, at date: Date = Date()) {
        try? displayHistoryStore?.recordDisplayed(candidateID: photo.id, at: date)
    }

    func deleteCachedAlbum() {
        generation = UUID()
        syncTask?.cancel()
        debounceTask?.cancel()
        do {
            try store.deleteAllCachedData()
            records = []
            smartReel = nil
            albums = []
            configuration = .defaultConfiguration
            lastSyncReport = nil
            phase = .idle
            observationTask?.cancel()
            observationTask = nil
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func curate(currentGeneration: UUID) async throws {
        guard !records.isEmpty else {
            smartReel = nil
            phase = .failed(
                "No locally available photos were found in this album. If Strict Offline is on, make photos available on this iPad or allow iCloud downloads."
            )
            return
        }
        let recordsByID = Dictionary(
            uniqueKeysWithValues: records.map { ($0.photo.id, $0) }
        )
        let reel = try await smartReelBuilder.buildUnbounded(
            candidates: records.map { $0.candidate() },
            maximumSelectionCount: min(max(records.count, 30), 100),
            imageProvider: { [store] id in
                guard let record = recordsByID[id] else { return nil }
                return await store.image(for: record.photo)
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
        smartReel = reel
        phase = .ready(
            photoCount: records.count,
            suggestionCount: reel.selections.count
        )
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
            self.refresh()
        }
    }
}
