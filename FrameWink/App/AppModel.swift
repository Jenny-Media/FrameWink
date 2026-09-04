import SwiftUI
import UIKit

enum PhotoCollectionMode: String, CaseIterable, Identifiable {
    case samples
    case personal
    case automaticAlbum

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .samples:
            return "Samples"
        case .personal:
            return "My Photos"
        case .automaticAlbum:
            return "Auto Album"
        }
    }
}

enum ImportPhase: Equatable {
    case idle
    case importing(ImportProgress)
    case cancelling(ImportProgress)
    case finished(PhotoImportReport)
    case deletionFailed(String)
}

enum CurationPhase: Equatable {
    case idle
    case analyzing(ImportProgress)
    case ready(Int)
    case cancelled
    case failed(String)
}

enum DisplaySlideSource {
    case bundled(resourceName: String)
    case imported(ImportedPhoto)
    case automaticAlbum(ImportedPhoto)
}

struct DisplaySlide: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    let accessibilityLabel: LocalizedStringKey
    let source: DisplaySlideSource
    let importantRects: [NormalizedRect]
    let bundledPixelSize: PixelSize?

    init(
        id: String,
        title: LocalizedStringKey,
        caption: LocalizedStringKey,
        accessibilityLabel: LocalizedStringKey,
        source: DisplaySlideSource,
        importantRects: [NormalizedRect] = [],
        bundledPixelSize: PixelSize? = nil
    ) {
        self.id = id
        self.title = title
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel
        self.source = source
        self.importantRects = importantRects
        self.bundledPixelSize = bundledPixelSize
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var importedPhotos: [ImportedPhoto] = []
    @Published var collectionMode: PhotoCollectionMode = .samples
    @Published private(set) var importPhase: ImportPhase = .idle
    @Published private(set) var curationPhase: CurationPhase = .idle
    @Published private(set) var smartReel: SmartReel?

    private let importer: PhotoImporting
    private let imageLoader: ImportedPhotoImageLoading
    private let smartReelBuilder: SmartReelBuilding?
    private var importTask: Task<Void, Never>?
    private var curationTask: Task<Void, Never>?
    private var curationGeneration = UUID()
    private var lastCurationProgressUpdate = Date.distantPast
    private var retryItems: [PhotoImportItem] = []
    private var curatedCandidateCount = 0
    private var pendingCurationCandidateCount: Int?
    private var mostRecentExclusion: (selection: CuratedPhoto, index: Int)?

    init(
        importer: PhotoImporting,
        imageLoader: ImportedPhotoImageLoading,
        smartReelBuilder: SmartReelBuilding? = nil
    ) {
        self.importer = importer
        self.imageLoader = imageLoader
        self.smartReelBuilder = smartReelBuilder
        importedPhotos = (try? importer.loadImportedPhotos()) ?? []
        if let savedReel = try? smartReelBuilder?.loadSavedReel() {
            let availableIDs = Set(importedPhotos.map(\.id))
            let availableSelections = savedReel.selections.filter {
                availableIDs.contains($0.candidateID)
            }
            if !availableSelections.isEmpty {
                smartReel = SmartReel(
                    id: savedReel.id,
                    algorithmRevision: savedReel.algorithmRevision,
                    createdAt: savedReel.createdAt,
                    selections: availableSelections
                )
                curationPhase = .ready(availableSelections.count)
                curatedCandidateCount = importedPhotos.count
            }
        }
    }

    var slides: [DisplaySlide] {
#if DEBUG
        if let scenario = DebugScreenshotScenario.current {
            if scenario == .portraitFrame,
               let portrait = BundledSampleCatalog.photos.first(where: {
                   $0.id == "sample-water-bird"
               }) {
                return [portrait.slide]
            }
            if scenario == .pairedFrame {
                let pairOrder = [
                    "sample-water-bird",
                    "sample-evening-sail",
                ]
                let photosByID = Dictionary(
                    uniqueKeysWithValues: BundledSampleCatalog.photos.map { ($0.id, $0) }
                )
                return pairOrder.compactMap { photosByID[$0]?.slide }
            }
            if scenario == .mosaicFrame,
               UIDevice.current.userInterfaceIdiom == .phone,
               let compactPhoto = BundledSampleCatalog.photos.first(where: {
                   $0.id == "sample-taipei-skyline"
               }) {
                return [compactPhoto.slide]
            }
            if scenario == .frameControls,
               let controlsPhoto = BundledSampleCatalog.photos.first(where: {
                   $0.id == "sample-antelope-canyon"
               }) {
                return [controlsPhoto.slide]
            }
            if [.smartFrame, .mosaicFrame, .frameControls, .blackoutFrame]
                .contains(scenario) {
                let marketingOrder = [
                    "sample-yellowstone-falls",
                    "sample-san-francisco-sunset",
                    "sample-golden-gate",
                    "sample-antelope-canyon",
                    "sample-horseshoe-bend",
                    "sample-sun-rays-ocean",
                    "sample-autumn-waterfall",
                    "sample-taipei-skyline",
                    "sample-mountain-icicles",
                    "sample-autumn-cyclist",
                ]
                let photosByID = Dictionary(
                    uniqueKeysWithValues: BundledSampleCatalog.photos.map { ($0.id, $0) }
                )
                return marketingOrder.compactMap { photosByID[$0]?.slide }
            }
        }
#endif
        if collectionMode == .personal, !importedPhotos.isEmpty {
            let photosByID = Dictionary(uniqueKeysWithValues: importedPhotos.map { ($0.id, $0) })
            let selections: [(ImportedPhoto, [NormalizedRect])]
            if let smartReel = smartReel {
                selections = smartReel.selections.compactMap { selection in
                    photosByID[selection.candidateID].map {
                        ($0, selection.importantRects)
                    }
                }
            } else {
                selections = importedPhotos.map { ($0, []) }
            }

            return selections.map { photo, importantRects in
                DisplaySlide(
                    id: photo.id.uuidString,
                    title: "My Photos",
                    caption: "Selected privately on this device",
                    accessibilityLabel: "A photo selected for your Smart Reel",
                    source: .imported(photo),
                    importantRects: importantRects
                )
            }
        }

        return BundledSampleCatalog.slides
    }

    var canRetryImport: Bool {
        !retryItems.isEmpty
    }

    var remainingPhotoCapacity: Int {
        ManualPhotoCollectionPolicy.remainingCapacity(after: importedPhotos.count)
    }

    var canAddPhotos: Bool {
        remainingPhotoCapacity > 0
    }

    var isImporting: Bool {
        switch importPhase {
        case .importing, .cancelling:
            return true
        case .idle, .finished, .deletionFailed:
            return false
        }
    }

    var reviewPhotos: [ImportedPhoto] {
        guard let smartReel = smartReel else { return [] }
        let photosByID = Dictionary(uniqueKeysWithValues: importedPhotos.map { ($0.id, $0) })
        return smartReel.selections.compactMap { photosByID[$0.candidateID] }
    }

    var isCurating: Bool {
        if case .analyzing = curationPhase { return true }
        return false
    }

    func prepareSmartReelIfNeeded() {
        guard !importedPhotos.isEmpty, smartReel == nil, !isCurating else { return }
        refreshSmartReel()
    }

    func refreshSmartReel() {
        guard !importedPhotos.isEmpty else {
            return
        }

        requestCuration(
            candidateCount: importedPhotos.count,
            supersedesActiveCuration: true
        )
    }

    private func requestCuration(
        candidateCount: Int,
        supersedesActiveCuration: Bool
    ) {
        guard smartReelBuilder != nil, candidateCount > 0 else { return }
        let boundedCount = min(candidateCount, importedPhotos.count)

        if isCurating, !supersedesActiveCuration {
            pendingCurationCandidateCount = max(
                pendingCurationCandidateCount ?? 0,
                boundedCount
            )
            return
        }

        if !supersedesActiveCuration,
           boundedCount <= curatedCandidateCount {
            return
        }

        startCuration(candidateCount: boundedCount)
    }

    private func startCuration(candidateCount: Int) {
        guard let smartReelBuilder = smartReelBuilder else { return }

        curationTask?.cancel()
        curationGeneration = UUID()
        lastCurationProgressUpdate = .distantPast
        let generation = curationGeneration
        let photos = Array(importedPhotos.prefix(candidateCount))
        let photosByID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
        let imageLoader = imageLoader
        curationPhase = .analyzing(
            ImportProgress(completedCount: 0, totalCount: photos.count)
        )

        curationTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let reel = try await smartReelBuilder.buildUnbounded(
                    candidates: photos.map(\.candidate),
                    maximumSelectionCount: min(
                        photos.count,
                        ManualPhotoCollectionPolicy.maximumReelSelectionCount
                    ),
                    imageProvider: { id in
                        guard let photo = photosByID[id] else { return nil }
                        return await imageLoader.image(for: photo)
                    },
                    progress: { [weak self] progress in
                        guard let self = self,
                              self.curationGeneration == generation else { return }
                        let now = Date()
                        guard progress.completedCount == progress.totalCount
                            || now.timeIntervalSince(self.lastCurationProgressUpdate) >= 0.1 else {
                            return
                        }
                        self.lastCurationProgressUpdate = now
                        self.curationPhase = .analyzing(progress)
                    }
                )
                try Task.checkCancellation()
                guard curationGeneration == generation else { return }
                smartReel = reel
                curationPhase = .ready(reel.selections.count)
                curatedCandidateCount = photos.count
                curationTask = nil
                startPendingCurationIfNeeded()
            } catch is CancellationError {
                guard curationGeneration == generation else { return }
                curationPhase = .cancelled
                curationTask = nil
            } catch {
                guard curationGeneration == generation else { return }
                curationPhase = .failed(error.localizedDescription)
                curationTask = nil
                // A later import checkpoint may contain enough stronger photos
                // to recover from an early no-usable-photos result.
                startPendingCurationIfNeeded()
            }
        }
    }

    private func startPendingCurationIfNeeded() {
        guard let pendingCount = pendingCurationCandidateCount else { return }
        pendingCurationCandidateCount = nil
        requestCuration(
            candidateCount: pendingCount,
            supersedesActiveCuration: false
        )
    }

    func cancelCuration() {
        pendingCurationCandidateCount = nil
        curationTask?.cancel()
    }

    func neverShow(candidateID: UUID) {
        guard let smartReelBuilder = smartReelBuilder,
              let smartReel = smartReel,
              let index = smartReel.selections.firstIndex(where: {
                  $0.candidateID == candidateID
              }) else {
            return
        }
        do {
            let selection = smartReel.selections[index]
            let updated = try smartReelBuilder.exclude(candidateID: candidateID, from: smartReel)
            self.smartReel = updated
            mostRecentExclusion = (selection, index)
            curationPhase = .ready(updated.selections.count)
        } catch {
            curationPhase = .failed(error.localizedDescription)
        }
    }

    var canUndoNeverShow: Bool {
        mostRecentExclusion != nil
    }

    func undoNeverShow() {
        guard let smartReelBuilder,
              let smartReel,
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
            self.mostRecentExclusion = nil
            curationPhase = .ready(restored.selections.count)
        } catch {
            curationPhase = .failed(error.localizedDescription)
        }
    }

    func clearNeverShowUndo() {
        mostRecentExclusion = nil
    }

    func resetNeverShowChoices() {
        guard let smartReelBuilder = smartReelBuilder else { return }
        do {
            try smartReelBuilder.resetExclusions()
            smartReel = nil
            mostRecentExclusion = nil
            curationPhase = .idle
            refreshSmartReel()
        } catch {
            curationPhase = .failed(error.localizedDescription)
        }
    }

    func importSelectedItems(_ items: [PhotoImportItem]) {
        guard !items.isEmpty else { return }
        startImport(items)
    }

    func cancelImport() {
        guard case .importing(let progress) = importPhase else { return }
        importPhase = .cancelling(progress)
        importTask?.cancel()
    }

    func retryImport() {
        guard !retryItems.isEmpty else { return }
        startImport(retryItems)
    }

    func dismissImportStatus() {
        importPhase = .idle
        retryItems = []
    }

#if DEBUG
    func debugBeginInitialPersonalImport() {
        guard importedPhotos.isEmpty else { return }
        importPhase = .importing(
            ImportProgress(completedCount: 0, totalCount: 3)
        )
    }
#endif

    func deleteImportedPhotos() {
        importTask?.cancel()
        curationTask?.cancel()
        do {
            try importer.deleteAllImportedPhotos()
            importedPhotos = []
            retryItems = []
            smartReel = nil
            mostRecentExclusion = nil
            curatedCandidateCount = 0
            pendingCurationCandidateCount = nil
            collectionMode = .samples
            importPhase = .idle
            curationPhase = .idle
        } catch {
            importPhase = .deletionFailed(error.localizedDescription)
        }
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        await imageLoader.image(for: photo)
    }

    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int = 640) async -> UIImage? {
        await imageLoader.thumbnail(for: photo, maxPixelDimension: maxPixelDimension)
    }

    private func startImport(_ items: [PhotoImportItem]) {
        importTask?.cancel()
        retryItems = []
        importPhase = .importing(
            ImportProgress(
                completedCount: 0,
                totalCount: min(items.count, remainingPhotoCapacity)
            )
        )

        importTask = Task { [weak self] in
            guard let self = self else { return }
            let report = await importer.importPhotos(
                from: items,
                maxPixelDimension: 2_560
            ) { [weak self] progress in
                guard let self = self else { return }
                if case .cancelling = self.importPhase {
                    self.importPhase = .cancelling(progress)
                } else {
                    self.importPhase = .importing(progress)
                }
            } checkpoint: { [weak self] photos in
                self?.receiveImportCheckpoint(photos)
            }

            importedPhotos = (try? importer.loadImportedPhotos()) ?? importedPhotos
            if !report.imported.isEmpty {
                collectionMode = .personal
            }

            let retryIDs = Set(report.failures.map(\.sourceID) + report.remainingSourceIDs)
            retryItems = items.filter { retryIDs.contains($0.id) }
            importPhase = .finished(report)
            if !report.imported.isEmpty {
                requestCuration(
                    candidateCount: importedPhotos.count,
                    supersedesActiveCuration: false
                )
            }
        }
    }

    private func receiveImportCheckpoint(_ photos: [ImportedPhoto]) {
        importedPhotos = photos
        guard !photos.isEmpty else { return }
        collectionMode = .personal
        guard let candidateCount = ManualPhotoCollectionPolicy.curationCandidateCount(
            for: photos.count
        ) else {
            return
        }
        requestCuration(
            candidateCount: candidateCount,
            supersedesActiveCuration: false
        )
    }

}
