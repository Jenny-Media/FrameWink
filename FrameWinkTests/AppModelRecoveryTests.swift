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
        progress: @escaping @MainActor (ImportProgress) -> Void
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
