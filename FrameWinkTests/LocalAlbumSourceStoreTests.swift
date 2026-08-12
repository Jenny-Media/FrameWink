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

    func testConfigurationPersistsAndDefaultsToStrictOffline() throws {
        XCTAssertEqual(store.loadConfiguration(), .defaultConfiguration)
        var configuration = AutomaticAlbumConfiguration.defaultConfiguration
        configuration.albumIdentifier = "album-id"
        configuration.albumTitle = "Family"
        configuration.automaticRefresh = false
        try store.saveConfiguration(configuration)

        let reopened = LocalAlbumSourceStore(baseURL: testRoot)
        XCTAssertEqual(reopened.loadConfiguration(), configuration)
        XCTAssertTrue(reopened.loadConfiguration().strictOffline)
    }

    func testCorruptRecordsAreDiscardedWithOrphanedImages() throws {
        let temporary = try store.temporaryURL(pathExtension: "jpg")
        try Data("image".utf8).write(to: temporary)
        let abandonedPartial = try store.temporaryURL(pathExtension: "jpg")
        try Data("partial".utf8).write(to: abandonedPartial)
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
        XCTAssertFalse(FileManager.default.fileExists(atPath: abandonedPartial.path))
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
}
