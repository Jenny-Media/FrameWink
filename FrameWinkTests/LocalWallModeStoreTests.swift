import XCTest
@testable import FrameWink

final class LocalWallModeStoreTests: XCTestCase {
    private var testRoot: URL!
    private var store: LocalWallModeStore!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkWallTests-\(UUID().uuidString)", isDirectory: true)
        store = LocalWallModeStore(directory: testRoot)
    }

    override func tearDownWithError() throws {
        if let testRoot = testRoot {
            try? FileManager.default.removeItem(at: testRoot)
        }
        store = nil
        testRoot = nil
    }

    func testConfigurationAndChecklistPersistAcrossRelaunch() throws {
        var configuration = WallModeConfiguration.defaultConfiguration
        configuration.scheduleEnabled = true
        configuration.dimStartMinute = 19 * 60 + 30
        configuration.completedChecklistItems = [.batteryCondition, .ventilation]
        try store.saveConfiguration(configuration)

        let reopened = LocalWallModeStore(directory: testRoot)
        XCTAssertEqual(reopened.loadConfiguration(), configuration)
    }

    func testCorruptedConfigurationFallsBackSafely() throws {
        try FileManager.default.createDirectory(at: testRoot, withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: store.configurationURL)

        XCTAssertEqual(store.loadConfiguration(), .defaultConfiguration)
    }

    func testOutOfRangeValuesAreNormalizedBeforePersistence() throws {
        var configuration = WallModeConfiguration.defaultConfiguration
        configuration.dimStartMinute = -1
        configuration.blackoutStartMinute = 1_500
        configuration.dimOpacity = 4
        try store.saveConfiguration(configuration)

        let loaded = store.loadConfiguration()
        XCTAssertEqual(loaded.dimStartMinute, 1_439)
        XCTAssertEqual(loaded.blackoutStartMinute, 60)
        XCTAssertEqual(loaded.dimOpacity, 0.9)
    }
}
