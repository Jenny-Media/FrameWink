import Foundation
import UIKit

enum SmartReelBuildError: LocalizedError {
    case noUsablePhotos

    var errorDescription: String? {
        "FrameWink couldn’t find a displayable photo in this selection. Try choosing a few clearer, normally exposed photos."
    }
}

protocol SmartReelBuilding {
    func loadSavedReel() throws -> SmartReel?

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel

    func resetExclusions() throws
}

final class SmartReelPipeline: SmartReelBuilding {
    private let analyzer: PhotoAnalyzing
    private let curator: PhotoCurating
    private let store: CurationStoring
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        analyzer: PhotoAnalyzing,
        curator: PhotoCurating,
        store: CurationStoring,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.analyzer = analyzer
        self.curator = curator
        self.store = store
        self.now = now
        self.makeID = makeID
    }

    func loadSavedReel() throws -> SmartReel? {
        guard let reel = try store.loadSmartReel(),
              reel.algorithmRevision == SmartReelCurator.algorithmRevision else {
            return nil
        }
        return reel
    }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await build(
            candidates: Array(
                candidates.prefix(ManualPhotoCollectionPolicy.maximumCandidateCount)
            ),
            maximumSelectionCount: min(
                candidates.count,
                ManualPhotoCollectionPolicy.maximumReelSelectionCount
            ),
            imageProvider: imageProvider,
            progress: progress
        )
    }

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await build(
            candidates: candidates,
            maximumSelectionCount: maximumSelectionCount,
            imageProvider: imageProvider,
            progress: progress
        )
    }

    private func build(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        var cachedSignals = try store.loadSignals(
            algorithmRevision: SmartReelCurator.algorithmRevision
        )
        var analyzed: [AnalyzedPhoto] = []
        var unsavedSignalCount = 0
        let signalSaveBatchSize = max(64, min(512, max(candidates.count / 10, 1)))
        await progress(ImportProgress(completedCount: 0, totalCount: candidates.count))

        do {
            for (index, candidate) in candidates.enumerated() {
                try Task.checkCancellation()
                do {
                    if let cached = cachedSignals[candidate.id],
                       let restored = analyzer.restoredAnalysis(
                           candidate: candidate,
                           cachedSignals: cached
                       ) {
                        analyzed.append(restored)
                        await progress(
                            ImportProgress(
                                completedCount: index + 1,
                                totalCount: candidates.count
                            )
                        )
                        continue
                    }
                    guard let image = await imageProvider(candidate.id) else {
                        await progress(
                            ImportProgress(
                                completedCount: index + 1,
                                totalCount: candidates.count
                            )
                        )
                        continue
                    }

                    let photo = try await analyzer.analyze(
                        candidate: candidate,
                        image: image,
                        cachedSignals: cachedSignals[candidate.id]
                    )
                    analyzed.append(photo)
                    cachedSignals[candidate.id] = photo.signals
                    unsavedSignalCount += 1
                    if unsavedSignalCount >= signalSaveBatchSize {
                        try store.saveSignals(cachedSignals)
                        unsavedSignalCount = 0
                    }
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    // One unreadable candidate must not prevent the remaining chosen photos
                    // from producing a usable local reel.
                }

                await progress(
                    ImportProgress(
                        completedCount: index + 1,
                        totalCount: candidates.count
                    )
                )
            }
        } catch is CancellationError {
            if unsavedSignalCount > 0 {
                try? store.saveSignals(cachedSignals)
            }
            throw CancellationError()
        }
        if unsavedSignalCount > 0 {
            try store.saveSignals(cachedSignals)
        }

        try Task.checkCancellation()
        let exclusions = try store.loadExclusions()
        let displayHistory = try (store as? DisplayHistoryStoring)?
            .loadDisplayHistory() ?? [:]
        let reel = try curator.makeReel(
            from: analyzed,
            exclusions: exclusions,
            displayHistory: displayHistory,
            maximumCount: maximumSelectionCount,
            now: now(),
            reelID: makeID()
        )
        guard !reel.selections.isEmpty else {
            throw SmartReelBuildError.noUsablePhotos
        }
        try store.saveSmartReel(reel)
        return reel
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        var exclusions = try store.loadExclusions()
        exclusions.insert(candidateID)
        try store.saveExclusions(exclusions)

        let updated = SmartReel(
            id: reel.id,
            algorithmRevision: reel.algorithmRevision,
            createdAt: reel.createdAt,
            selections: reel.selections.filter { $0.candidateID != candidateID }
        )
        try store.saveSmartReel(updated)
        return updated
    }

    func resetExclusions() throws {
        try store.saveExclusions([])
    }
}
