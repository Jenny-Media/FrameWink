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

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel
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
        let boundedCandidates = Array(candidates.prefix(100))
        var cachedSignals = try store.loadSignals(
            algorithmRevision: SmartReelCurator.algorithmRevision
        )
        var analyzed: [AnalyzedPhoto] = []
        await progress(ImportProgress(completedCount: 0, totalCount: boundedCandidates.count))

        for (index, candidate) in boundedCandidates.enumerated() {
            do {
                try Task.checkCancellation()
                guard let image = await imageProvider(candidate.id) else {
                    await progress(
                        ImportProgress(
                            completedCount: index + 1,
                            totalCount: boundedCandidates.count
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
                try store.saveSignals(cachedSignals)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // One unreadable candidate must not prevent the remaining chosen photos
                // from producing a usable local reel.
            }

            await progress(
                ImportProgress(
                    completedCount: index + 1,
                    totalCount: boundedCandidates.count
                )
            )
        }

        try Task.checkCancellation()
        let exclusions = try store.loadExclusions()
        let reel = try curator.makeReel(
            from: analyzed,
            exclusions: exclusions,
            maximumCount: 30,
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
}
