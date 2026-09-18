import Foundation
import XCTest
@testable import FrameWink

final class LocalAlbumSourceStoreTests: XCTestCase {
    private var testRoot: URL!
    private var store: LocalAlbumSourceStore!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkAlbumStoreTests-" + UUID().uuidString)
        store = LocalAlbumSourceStore(baseURL: testRoot)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testRoot)
        store = nil
        testRoot = nil
    }

    func testConfigurationPersistsAndAllowsNeededICloudDownloadsByDefault() throws {
        XCTAssertEqual(store.loadConfiguration(), .defaultConfiguration)
        var configuration = AutomaticAlbumConfiguration.defaultConfiguration
        configuration.albumIdentifier = "album-id"
        configuration.albumTitle = "Family"
        configuration.automaticRefresh = false
        try store.saveConfiguration(configuration)

        let reopened = LocalAlbumSourceStore(baseURL: testRoot)
        XCTAssertEqual(reopened.loadConfiguration(), configuration)
        XCTAssertFalse(reopened.loadConfiguration().strictOffline)
    }

    func testCorruptRecordsDiscardOrphanedImagesButPreserveActivePartial() throws {
        let temporary = try store.temporaryURL(pathExtension: "jpg")
        try Data("image".utf8).write(to: temporary)
        let activePartial = try store.temporaryURL(pathExtension: "jpg")
        try Data("partial".utf8).write(to: activePartial)
        try store.commitTemporaryImage(at: temporary, filename: "orphan.jpg")
        try FileManager.default.createDirectory(
            at: store.metadataDirectory,
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: store.recordsURL, options: .atomic)

        XCTAssertTrue(try store.loadRecords().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: store.imagesDirectory.appendingPathComponent("orphan.jpg").path
        ))
        XCTAssertTrue(FileManager.default.fileExists(atPath: activePartial.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.recordsURL.path))
    }

    func testDeleteCacheRemovesConfigurationImagesAndCurationMetadata() throws {
        var configuration = AutomaticAlbumConfiguration.defaultConfiguration
        configuration.albumIdentifier = "album-id"
        try store.saveConfiguration(configuration)
        let temporary = try store.temporaryURL(pathExtension: "jpg")
        try Data("image".utf8).write(to: temporary)
        try store.commitTemporaryImage(at: temporary, filename: "cached.jpg")
        try Data("[]".utf8).write(
            to: store.metadataDirectory.appendingPathComponent("signals.json")
        )

        try store.deleteAllCachedData()

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.directory.path))
        XCTAssertEqual(store.loadConfiguration(), .defaultConfiguration)
        XCTAssertTrue(try store.loadRecords().isEmpty)
    }

    func testAutomaticAlbumCacheIsExcludedFromBackup() throws {
        var configuration = AutomaticAlbumConfiguration.defaultConfiguration
        configuration.albumIdentifier = "album-id"
        try store.saveConfiguration(configuration)

        let values = try store.directory.resourceValues(
            forKeys: [.isExcludedFromBackupKey]
        )

        XCTAssertEqual(values.isExcludedFromBackup, true)
    }

    func testPruningKeepsCurrentReelImageAndCandidateMetadata() throws {
        let selected = cachedRecord(assetID: "selected")
        let unused = cachedRecord(assetID: "unused")
        try store.saveConfiguration(.defaultConfiguration)
        for record in [selected, unused] {
            try Data(repeating: 7, count: 128).write(
                to: store.imagesDirectory.appendingPathComponent(record.photo.filename)
            )
        }
        try store.replaceRecords([selected, unused], removingFilenames: [])

        let removedBytes = try store.pruneCachedImages(keepingPhotoIDs: [selected.photo.id])

        XCTAssertGreaterThan(removedBytes, 0)
        XCTAssertTrue(store.containsImage(filename: selected.photo.filename))
        XCTAssertFalse(store.containsImage(filename: unused.photo.filename))
        XCTAssertEqual(try store.loadRecords().map(\.assetIdentifier), ["selected", "unused"])
    }

    func testSwitchKeepsThreeRecentAlbumsAndReusesSharedAsset() throws {
        let shared = cachedRecord(assetID: "shared")
        let firstOnly = cachedRecord(assetID: "first")
        let secondOnly = cachedRecord(assetID: "second")
        let thirdOnly = cachedRecord(assetID: "third")
        let fourthOnly = cachedRecord(assetID: "fourth")

        try select("first")
        try cache([shared, firstOnly])
        try select("second")
        try cache([shared, secondOnly])
        XCTAssertEqual(Set(try store.loadRecords().map(\.assetIdentifier)), ["shared", "second"])
        XCTAssertEqual(try store.loadRecords(for: "first").count, 2)
        XCTAssertTrue(store.containsImage(filename: firstOnly.photo.filename))

        try select("third")
        try cache([thirdOnly])
        try select("fourth")
        try cache([fourthOnly])
        XCTAssertTrue(try store.loadRecords(for: "first").isEmpty)
        XCTAssertFalse(store.containsImage(filename: firstOnly.photo.filename))
        XCTAssertTrue(store.containsImage(filename: shared.photo.filename))
        XCTAssertEqual(Set(try store.loadReusableRecords().map(\.assetIdentifier)),
                       ["shared", "second", "third", "fourth"])

        try select("second")
        XCTAssertEqual(Set(try store.loadRecords().map(\.assetIdentifier)), ["shared", "second"])
    }

    func testBudgetPrunesOldestAlbumFirstAndManualCleanupPrunesRemainingUnused() throws {
        let old = cachedRecord(assetID: "old")
        let recent = cachedRecord(assetID: "recent")
        let current = cachedRecord(assetID: "current")
        try select("old")
        try cache([old])
        try select("recent")
        try cache([recent])
        try select("current")
        try cache([current])

        let size = store.cachedImageBytes()
        XCTAssertGreaterThan(size, 0)
        _ = try store.pruneCachedImagesToBudget(
            keepingPhotoIDs: [current.photo.id],
            budgetBytes: size - 1
        )
        XCTAssertFalse(store.containsImage(filename: old.photo.filename))
        XCTAssertTrue(store.containsImage(filename: recent.photo.filename))
        XCTAssertTrue(store.containsImage(filename: current.photo.filename))

        _ = try store.pruneCachedImages(keepingPhotoIDs: [current.photo.id])
        XCTAssertFalse(store.containsImage(filename: recent.photo.filename))
        XCTAssertTrue(store.containsImage(filename: current.photo.filename))
        XCTAssertEqual(try store.loadRecords(for: "recent").count, 1)
    }

    func testLegacySingleAlbumCacheSurvivesFirstSwitch() throws {
        let record = cachedRecord(assetID: "legacy")
        var configuration = AutomaticAlbumConfiguration.defaultConfiguration
        configuration.albumIdentifier = "legacy-album"
        try store.saveConfiguration(configuration)
        try cache([record])
        try FileManager.default.removeItem(at: store.recentAlbumsURL)

        try select("new-album")

        XCTAssertEqual(try store.loadRecords(for: "legacy-album").map(\.assetIdentifier),
                       ["legacy"])
        XCTAssertTrue(store.containsImage(filename: record.photo.filename))
    }

    func testSavedReelIsNotRestoredForAnotherAlbum() throws {
        try select("first")
        try Data("{}".utf8).write(
            to: store.metadataDirectory.appendingPathComponent("smart-reel.json")
        )
        try store.markSavedReelForCurrentAlbum()
        XCTAssertTrue(store.savedReelBelongsToCurrentAlbum())

        try select("second")
        XCTAssertFalse(store.savedReelBelongsToCurrentAlbum())
        try select("first")
        XCTAssertTrue(store.savedReelBelongsToCurrentAlbum())
    }

    private func select(_ identifier: String) throws {
        var configuration = store.loadConfiguration()
        configuration.albumIdentifier = identifier
        configuration.albumTitle = identifier
        try store.saveConfiguration(configuration)
    }

    private func cache(_ records: [CachedAlbumAsset]) throws {
        for record in records where !store.containsImage(filename: record.photo.filename) {
            try Data(repeating: 7, count: 128).write(
                to: store.imagesDirectory.appendingPathComponent(record.photo.filename)
            )
        }
        try store.replaceRecords(records, removingFilenames: [])
    }

    private func cachedRecord(assetID: String) -> CachedAlbumAsset {
        CachedAlbumAsset(
            assetIdentifier: assetID,
            assetModificationDate: Date(timeIntervalSince1970: 100),
            photo: ImportedPhoto(
                id: UUID(),
                filename: UUID().uuidString + ".jpg",
                pixelWidth: 1_000,
                pixelHeight: 800,
                importedAt: Date(timeIntervalSince1970: 100)
            )
        )
    }
}
