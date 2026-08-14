import XCTest
@testable import FrameWink

@MainActor
final class FrameConfigurationControllerTests: XCTestCase {
    func testPaidConfigurationsPersistActivateUpdateAndDelete() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkConfigurationTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalFrameConfigurationStore(directory: root)
        let controller = FrameConfigurationController(store: store)

        XCTAssertEqual(controller.availableLayoutPreferences, [.automatic])
        controller.create(
            name: "Ignored while free",
            source: .samples,
            layoutPreference: .mosaic,
            interval: 10
        )
        XCTAssertTrue(controller.configurations.isEmpty)

        controller.setEntitled(true)
        controller.create(
            name: "  Kitchen  ",
            source: .automaticAlbum,
            albumIdentifier: "kitchen-album",
            albumTitle: "Kitchen Album",
            layoutPreference: .mosaic,
            interval: 30
        )
        let first = try XCTUnwrap(controller.activeConfiguration)
        controller.create(
            name: "Family",
            source: .freeSmartReel,
            layoutPreference: .fit,
            interval: 10
        )
        let second = try XCTUnwrap(controller.activeConfiguration)

        XCTAssertEqual(controller.configurations.count, 2)
        XCTAssertEqual(first.name, "Kitchen")
        XCTAssertEqual(first.albumIdentifier, "kitchen-album")
        XCTAssertEqual(first.albumTitle, "Kitchen Album")
        XCTAssertEqual(first.layoutPreference, .automatic)
        XCTAssertEqual(controller.availableLayoutPreferences, [.automatic])

        controller.activate(first.id)
        controller.updateActive(layoutPreference: .fill, interval: 60)
        XCTAssertEqual(controller.activeConfiguration?.layoutPreference, .automatic)
        XCTAssertEqual(controller.activeConfiguration?.interval, 60)

        let reopened = FrameConfigurationController(store: store)
        reopened.setEntitled(true)
        XCTAssertEqual(reopened.configurations, controller.configurations)
        XCTAssertEqual(reopened.activeConfigurationID, first.id)

        reopened.delete(first.id)
        XCTAssertEqual(reopened.activeConfigurationID, second.id)
        XCTAssertEqual(reopened.configurations.map(\.id), [second.id])
    }

    func testCorruptArchiveFallsBackWithoutDeletingOtherSettings() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkConfigurationTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalFrameConfigurationStore(directory: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let otherSetting = root.appendingPathComponent("wall-mode.json")
        try Data("wall".utf8).write(to: otherSetting)
        try Data("not-json".utf8).write(to: store.archiveURL)

        let controller = FrameConfigurationController(store: store)

        XCTAssertTrue(controller.configurations.isEmpty)
        XCTAssertNil(controller.activeConfigurationID)
        XCTAssertTrue(FileManager.default.fileExists(atPath: otherSetting.path))
    }

    func testSaveCurrentCreatesOneSimpleFrameAndUpdatesItInPlace() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkSimpleSettingsTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalFrameConfigurationStore(directory: root)
        let controller = FrameConfigurationController(store: store)
        controller.setEntitled(true)

        controller.saveCurrent(
            source: .automaticAlbum,
            albumIdentifier: "family",
            albumTitle: "Family",
            layoutPreference: .automatic,
            interval: 10
        )
        let originalID = try XCTUnwrap(controller.activeConfigurationID)

        controller.saveCurrent(
            source: .freeSmartReel,
            layoutPreference: .fit,
            interval: 30
        )

        XCTAssertEqual(controller.configurations.count, 1)
        XCTAssertEqual(controller.activeConfigurationID, originalID)
        XCTAssertEqual(controller.activeConfiguration?.name, "My Frame")
        XCTAssertEqual(controller.activeConfiguration?.source, .freeSmartReel)
        XCTAssertNil(controller.activeConfiguration?.albumIdentifier)
        XCTAssertNil(controller.activeConfiguration?.albumTitle)
        XCTAssertEqual(controller.activeConfiguration?.layoutPreference, .automatic)
        XCTAssertEqual(controller.activeConfiguration?.interval, 30)
    }

    func testLegacyPresentationChoicesMigrateWithoutLosingSourceData() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkPresentationMigrationTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalFrameConfigurationStore(directory: root)
        let configurationID = UUID()
        try store.saveArchive(
            FrameConfigurationArchive(
                configurations: [
                    SavedFrameConfiguration(
                        id: configurationID,
                        name: "Family",
                        source: .automaticAlbum,
                        albumIdentifier: "family-album",
                        albumTitle: "Family",
                        layoutPreference: .mosaic,
                        interval: 7
                    ),
                ],
                activeConfigurationID: configurationID
            )
        )

        let controller = FrameConfigurationController(store: store)
        controller.setEntitled(true)

        XCTAssertEqual(controller.activeConfiguration?.source, .automaticAlbum)
        XCTAssertEqual(controller.activeConfiguration?.albumIdentifier, "family-album")
        XCTAssertEqual(controller.activeConfiguration?.layoutPreference, .automatic)
        XCTAssertEqual(controller.activeConfiguration?.interval, 30)
        XCTAssertEqual(store.loadArchive().configurations, controller.configurations)
    }
}
