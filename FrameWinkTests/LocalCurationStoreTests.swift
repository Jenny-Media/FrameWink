import UIKit
import XCTest
@testable import FrameWink

final class LocalCurationStoreTests: XCTestCase {
    private var testRoot: URL!
    private var store: LocalCurationStore!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkCurationTests-\(UUID().uuidString)", isDirectory: true)
        store = LocalCurationStore(directory: testRoot)
    }

    override func tearDownWithError() throws {
        if let testRoot = testRoot {
            try? FileManager.default.removeItem(at: testRoot)
        }
        store = nil
        testRoot = nil
    }

    func testSignalsAreRevisionedAndCorruptedCacheIsDisposable() throws {
        let current = signals(id: UUID(), revision: SmartReelCurator.algorithmRevision)
        let old = signals(id: UUID(), revision: 0)
        try store.saveSignals([current.candidateID: current, old.candidateID: old])

        XCTAssertEqual(
            try store.loadSignals(algorithmRevision: SmartReelCurator.algorithmRevision),
            [current.candidateID: current]
        )

        try Data("not-json".utf8).write(to: store.signalsURL)
        XCTAssertTrue(
            try store.loadSignals(algorithmRevision: SmartReelCurator.algorithmRevision).isEmpty
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.signalsURL.path))
    }

    func testNeverShowExclusionsPersistAcrossStoreInstances() throws {
        let excluded = UUID()
        try store.saveExclusions([excluded])

        let reopened = LocalCurationStore(directory: testRoot)
        XCTAssertEqual(try reopened.loadExclusions(), [excluded])
    }

    func testPipelineCancellationStopsAnalysisAndLeavesReusableSignals() async throws {
        let pipeline = SmartReelPipeline(
            analyzer: DelayedFixtureAnalyzer(),
            curator: SmartReelCurator(),
            store: store
        )
        let candidates = (1...20).map { index in
            PhotoCandidate(
                id: UUID(),
                source: .pickerImport,
                pixelWidth: 800,
                pixelHeight: 600,
                creationDate: Date(timeIntervalSince1970: Double(index * 60))
            )
        }

        let task = Task {
            try await pipeline.build(
                candidates: candidates,
                imageProvider: { _ in UIImage() },
                progress: { _ in }
            )
        }
        try await Task.sleep(nanoseconds: 120_000_000)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            let saved = try store.loadSignals(
                algorithmRevision: SmartReelCurator.algorithmRevision
            )
            XCTAssertGreaterThan(saved.count, 0)
            XCTAssertLessThan(saved.count, candidates.count)
        }
    }

    func testPipelineExclusionUpdatesReelAndDurableVetoImmediately() throws {
        let selectedID = UUID()
        let otherID = UUID()
        let reel = SmartReel(
            id: UUID(),
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            selections: [selectedID, otherID].map {
                CuratedPhoto(
                    candidateID: $0,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 0.8,
                    reasons: [.quality]
                )
            }
        )
        let pipeline = SmartReelPipeline(
            analyzer: DelayedFixtureAnalyzer(),
            curator: SmartReelCurator(),
            store: store
        )

        let updated = try pipeline.exclude(candidateID: selectedID, from: reel)

        XCTAssertEqual(updated.selections.map(\.candidateID), [otherID])
        XCTAssertEqual(try store.loadExclusions(), [selectedID])
        XCTAssertEqual(try store.loadSmartReel(), updated)
    }

    func testPipelineDoesNotPersistAnEmptyReelWhenNoPhotoIsUsable() async throws {
        let pipeline = SmartReelPipeline(
            analyzer: DelayedFixtureAnalyzer(sharpness: 0.01),
            curator: SmartReelCurator(),
            store: store
        )
        let candidate = PhotoCandidate(
            id: UUID(),
            source: .pickerImport,
            pixelWidth: 800,
            pixelHeight: 600,
            creationDate: nil
        )

        do {
            _ = try await pipeline.build(
                candidates: [candidate],
                imageProvider: { _ in UIImage() },
                progress: { _ in }
            )
            XCTFail("Expected an actionable no-usable-photos error")
        } catch SmartReelBuildError.noUsablePhotos {
            XCTAssertNil(try store.loadSmartReel())
        }
    }

    func testDisplayHistoryPersistsCountsAndLatestDate() throws {
        let candidateID = UUID()
        try store.recordDisplayed(
            candidateID: candidateID,
            at: Date(timeIntervalSince1970: 100)
        )
        try store.recordDisplayed(
            candidateID: candidateID,
            at: Date(timeIntervalSince1970: 200)
        )
        XCTAssertEqual(
            try store.loadDisplayHistory()[candidateID],
            DisplayHistoryEntry(
                candidateID: candidateID,
                lastDisplayedAt: Date(timeIntervalSince1970: 100),
                displayCount: 1
            )
        )
        try store.recordDisplayed(
            candidateID: candidateID,
            at: Date(timeIntervalSince1970: 22_000)
        )

        XCTAssertEqual(
            try store.loadDisplayHistory()[candidateID],
            DisplayHistoryEntry(
                candidateID: candidateID,
                lastDisplayedAt: Date(timeIntervalSince1970: 22_000),
                displayCount: 2
            )
        )
    }

    func testPaidPipelineAnalyzesBeyondFreeHundredCandidateLimit() async throws {
        let pipeline = SmartReelPipeline(
            analyzer: InstantFixtureAnalyzer(),
            curator: SmartReelCurator(),
            store: store,
            now: { Date(timeIntervalSince1970: 20_000) },
            makeID: UUID.init
        )
        let candidates = (1...120).map { index in
            PhotoCandidate(
                id: UUID(),
                source: .photoLibraryAlbum,
                pixelWidth: 800,
                pixelHeight: 600,
                creationDate: Date(timeIntervalSince1970: Double(index * 60))
            )
        }

        let reel = try await pipeline.buildUnbounded(
            candidates: candidates,
            maximumSelectionCount: 120,
            imageProvider: { _ in UIImage() },
            progress: { _ in }
        )

        XCTAssertEqual(reel.selections.count, 120)
        XCTAssertEqual(
            try store.loadSignals(
                algorithmRevision: SmartReelCurator.algorithmRevision
            ).count,
            120
        )
    }

    private func signals(id: UUID, revision: Int) -> PhotoSignals {
        PhotoSignals(
            candidateID: id,
            algorithmRevision: revision,
            sharpness: 0.7,
            exposure: 0.5,
            contrast: 0.7,
            faceQuality: nil,
            saliencyConfidence: nil,
            layoutFitness: 0.8,
            importantRects: []
        )
    }
}

private struct DelayedFixtureAnalyzer: PhotoAnalyzing {
    var sharpness = 0.7

    func analyze(
        candidate: PhotoCandidate,
        image: UIImage,
        cachedSignals: PhotoSignals?
    ) async throws -> AnalyzedPhoto {
        try await Task.sleep(nanoseconds: 40_000_000)
        let signals = cachedSignals ?? PhotoSignals(
            candidateID: candidate.id,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            sharpness: sharpness,
            exposure: 0.5,
            contrast: 0.7,
            faceQuality: nil,
            saliencyConfidence: nil,
            layoutFitness: 0.8,
            importantRects: []
        )
        return AnalyzedPhoto(candidate: candidate, signals: signals, featurePrint: nil)
    }
}

private struct InstantFixtureAnalyzer: PhotoAnalyzing {
    func analyze(
        candidate: PhotoCandidate,
        image: UIImage,
        cachedSignals: PhotoSignals?
    ) async throws -> AnalyzedPhoto {
        let signals = cachedSignals ?? PhotoSignals(
            candidateID: candidate.id,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            sharpness: 0.7,
            exposure: 0.5,
            contrast: 0.7,
            faceQuality: nil,
            saliencyConfidence: nil,
            layoutFitness: 0.8,
            importantRects: []
        )
        return AnalyzedPhoto(candidate: candidate, signals: signals, featurePrint: nil)
    }
}
