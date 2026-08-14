import UIKit
import XCTest
@testable import FrameWink

@MainActor
final class AppModelRecoveryTests: XCTestCase {
    func testResetNeverShowPreservesImportedPhotosAndRebuildsReel() async throws {
        let photo = ImportedPhoto(
            id: UUID(),
            filename: "kept.jpg",
            pixelWidth: 1_200,
            pixelHeight: 800,
            importedAt: Date(timeIntervalSince1970: 100)
        )
        let importer = RecoveryPhotoImporter(photos: [photo])
        let builder = RecoverySmartReelBuilder(photoID: photo.id)
        let model = AppModel(
            importer: importer,
            imageLoader: RecoveryImageLoader(),
            smartReelBuilder: builder
        )

        XCTAssertEqual(model.importedPhotos, [photo])
        XCTAssertNotNil(model.smartReel)

        model.resetNeverShowChoices()
        try await waitUntil {
            builder.resetCount == 1 && builder.buildCount == 1
                && model.curationPhase == .ready(1)
        }

        XCTAssertEqual(model.importedPhotos, [photo])
        XCTAssertEqual(importer.deleteCount, 0)
        XCTAssertEqual(model.smartReel?.selections.map(\.candidateID), [photo.id])
    }

    func testBackgroundCurationCompletionPreservesTheSelectedPhotoSource() async throws {
        let photo = ImportedPhoto(
            id: UUID(),
            filename: "background.jpg",
            pixelWidth: 1_200,
            pixelHeight: 800,
            importedAt: Date(timeIntervalSince1970: 100)
        )
        let builder = DelayedRecoverySmartReelBuilder(photoID: photo.id)
        let model = AppModel(
            importer: RecoveryPhotoImporter(photos: [photo]),
            imageLoader: RecoveryImageLoader(),
            smartReelBuilder: builder
        )

        model.collectionMode = .personal
        model.refreshSmartReel()
        model.collectionMode = .samples

        try await waitUntil {
            model.curationPhase == .ready(1)
        }

        XCTAssertEqual(model.collectionMode, .samples)
        XCTAssertEqual(model.smartReel?.selections.map(\.candidateID), [photo.id])
    }

    func testLargeManualImportPublishesAPlayableReelBeforeImportFinishes() async throws {
        let photos = (0..<40).map { index in
            ImportedPhoto(
                id: UUID(),
                filename: "progressive-\(index).jpg",
                pixelWidth: 1_200,
                pixelHeight: 800,
                importedAt: Date(timeIntervalSince1970: Double(index))
            )
        }
        let importer = ProgressiveRecoveryPhotoImporter(photos: photos)
        let builder = ProgressiveRecoverySmartReelBuilder()
        let model = AppModel(
            importer: importer,
            imageLoader: RecoveryImageLoader(),
            smartReelBuilder: builder
        )

        model.importSelectedItems([RecoveryImportItem()])

        try await waitUntil {
            model.isImporting && model.smartReel?.selections.count == 10
        }
        XCTAssertEqual(model.importedPhotos.count, 10)
        XCTAssertEqual(builder.candidateCounts.first, 10)

        try await waitUntil {
            !model.isImporting && model.smartReel?.selections.count == 40
        }
        XCTAssertEqual(model.importedPhotos.count, 40)
        XCTAssertEqual(builder.candidateCounts, [10, 30, 40])
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "Timed out waiting for AppModel state")
    }
}

private final class RecoveryPhotoImporter: PhotoImporting {
    var photos: [ImportedPhoto]
    var deleteCount = 0

    init(photos: [ImportedPhoto]) {
        self.photos = photos
    }

    func loadImportedPhotos() throws -> [ImportedPhoto] { photos }

    func importPhotos(
        from items: [PhotoImportItem],
        maxPixelDimension: Int,
        progress: @escaping @MainActor (ImportProgress) -> Void,
        checkpoint: @escaping @MainActor ([ImportedPhoto]) -> Void
    ) async -> PhotoImportReport {
        PhotoImportReport(
            imported: [],
            failures: [],
            remainingSourceIDs: [],
            wasCancelled: false
        )
    }

    func deleteAllImportedPhotos() throws {
        deleteCount += 1
        photos = []
    }
}

private final class ProgressiveRecoveryPhotoImporter: PhotoImporting {
    private let photos: [ImportedPhoto]
    private var storedPhotos: [ImportedPhoto] = []

    init(photos: [ImportedPhoto]) {
        self.photos = photos
    }

    func loadImportedPhotos() throws -> [ImportedPhoto] { storedPhotos }

    func importPhotos(
        from items: [PhotoImportItem],
        maxPixelDimension: Int,
        progress: @escaping @MainActor (ImportProgress) -> Void,
        checkpoint: @escaping @MainActor ([ImportedPhoto]) -> Void
    ) async -> PhotoImportReport {
        await progress(ImportProgress(completedCount: 0, totalCount: photos.count))
        storedPhotos = Array(photos.prefix(10))
        await checkpoint(storedPhotos)
        await progress(ImportProgress(completedCount: 10, totalCount: photos.count))
        try? await Task.sleep(nanoseconds: 300_000_000)
        storedPhotos = photos
        await checkpoint(storedPhotos)
        await progress(
            ImportProgress(completedCount: photos.count, totalCount: photos.count)
        )
        return PhotoImportReport(
            imported: photos,
            failures: [],
            remainingSourceIDs: [],
            wasCancelled: false
        )
    }

    func deleteAllImportedPhotos() throws {
        storedPhotos = []
    }
}

private struct RecoveryImportItem: PhotoImportItem {
    let id = UUID()

    func loadFile() async throws -> LoadedImportFile {
        throw TestRecoveryError.unused
    }
}

private enum TestRecoveryError: Error {
    case unused
}

private struct RecoveryImageLoader: ImportedPhotoImageLoading {
    func image(for photo: ImportedPhoto) async -> UIImage? { UIImage() }

    func thumbnail(
        for photo: ImportedPhoto,
        maxPixelDimension: Int
    ) async -> UIImage? {
        UIImage()
    }
}

private final class RecoverySmartReelBuilder: SmartReelBuilding {
    let photoID: UUID
    var resetCount = 0
    var buildCount = 0

    init(photoID: UUID) {
        self.photoID = photoID
    }

    func loadSavedReel() throws -> SmartReel? { reel() }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        buildCount += 1
        await progress(
            ImportProgress(
                completedCount: candidates.count,
                totalCount: candidates.count
            )
        )
        return reel()
    }

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await build(
            candidates: candidates,
            imageProvider: imageProvider,
            progress: progress
        )
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        reel
    }

    func resetExclusions() throws {
        resetCount += 1
    }

    private func reel() -> SmartReel {
        SmartReel(
            id: UUID(uuidString: "06813F9A-BB15-4611-8E30-0CA11AE96854")!,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(timeIntervalSince1970: 100),
            selections: [
                CuratedPhoto(
                    candidateID: photoID,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 0.9,
                    reasons: [.quality]
                ),
            ]
        )
    }
}

private final class DelayedRecoverySmartReelBuilder: SmartReelBuilding {
    let photoID: UUID

    init(photoID: UUID) {
        self.photoID = photoID
    }

    func loadSavedReel() throws -> SmartReel? { nil }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await Task.sleep(nanoseconds: 100_000_000)
        await progress(
            ImportProgress(
                completedCount: candidates.count,
                totalCount: candidates.count
            )
        )
        return reel()
    }

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await build(
            candidates: candidates,
            imageProvider: imageProvider,
            progress: progress
        )
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        reel
    }

    func resetExclusions() throws {}

    private func reel() -> SmartReel {
        SmartReel(
            id: UUID(uuidString: "6B70938D-4CA2-43E4-BBCB-F2C69E2420C8")!,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(timeIntervalSince1970: 100),
            selections: [
                CuratedPhoto(
                    candidateID: photoID,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 0.9,
                    reasons: [.quality]
                ),
            ]
        )
    }
}

private final class ProgressiveRecoverySmartReelBuilder: SmartReelBuilding {
    var candidateCounts: [Int] = []

    func loadSavedReel() throws -> SmartReel? { nil }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await buildUnbounded(
            candidates: candidates,
            maximumSelectionCount: ManualPhotoCollectionPolicy.maximumReelSelectionCount,
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
        candidateCounts.append(candidates.count)
        try await Task.sleep(nanoseconds: 20_000_000)
        await progress(
            ImportProgress(
                completedCount: candidates.count,
                totalCount: candidates.count
            )
        )
        return SmartReel(
            id: UUID(),
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(),
            selections: candidates.prefix(maximumSelectionCount).map {
                CuratedPhoto(
                    candidateID: $0.id,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 0.9,
                    reasons: [.quality]
                )
            }
        )
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        reel
    }

    func resetExclusions() throws {}
}
