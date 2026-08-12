import XCTest
@testable import FrameWink

@MainActor
final class WallModeControllerTests: XCTestCase {
    func testIdleTimerIsOwnedOnlyWhileFrameModeIsActiveAndForeground() {
        let idleTimer = FakeIdleTimerController(initialValue: false)
        let store = FakeWallModeStore()
        let controller = WallModeController(idleTimer: idleTimer, store: store)

        controller.setEntitled(true)
        controller.setFrameModeActive(true)
        XCTAssertTrue(idleTimer.isIdleTimerDisabled)
        XCTAssertTrue(controller.ownsIdleTimerState)
        XCTAssertEqual(idleTimer.setCount, 1)

        controller.setFrameModeActive(true)
        XCTAssertEqual(idleTimer.setCount, 1)

        controller.setSceneIsForeground(false)
        XCTAssertFalse(idleTimer.isIdleTimerDisabled)
        XCTAssertFalse(controller.ownsIdleTimerState)
        XCTAssertEqual(idleTimer.setCount, 2)

        controller.setSceneIsForeground(false)
        XCTAssertEqual(idleTimer.setCount, 2)

        controller.setSceneIsForeground(true)
        XCTAssertTrue(idleTimer.isIdleTimerDisabled)
        controller.setFrameModeActive(false)
        XCTAssertFalse(idleTimer.isIdleTimerDisabled)
        XCTAssertFalse(controller.ownsIdleTimerState)
    }

    func testPreexistingIdleTimerValueIsRestored() {
        let idleTimer = FakeIdleTimerController(initialValue: true)
        let controller = WallModeController(
            idleTimer: idleTimer,
            store: FakeWallModeStore()
        )

        controller.setEntitled(true)
        controller.setFrameModeActive(true)
        controller.restoreOwnedDisplayState()

        XCTAssertTrue(idleTimer.isIdleTimerDisabled)
        XCTAssertFalse(controller.frameModeIsActive)
        XCTAssertEqual(controller.visualState, .normal)
    }

    func testConfigurationPersistsAndImmediatelyRefreshesVisualState() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let store = FakeWallModeStore()
        let controller = WallModeController(
            idleTimer: FakeIdleTimerController(initialValue: false),
            store: store,
            calendar: calendar
        )
        let blackoutDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 11, hour: 23))
        )
        var configuration = WallModeConfiguration.defaultConfiguration
        configuration.scheduleEnabled = true

        controller.setEntitled(true, at: blackoutDate)
        controller.setFrameModeActive(true, at: blackoutDate)
        controller.updateConfiguration(configuration, at: blackoutDate)

        XCTAssertEqual(store.savedConfiguration, configuration)
        XCTAssertEqual(controller.visualState, .blackout)
    }

    func testLosingEntitlementImmediatelyRestoresIdleTimerAndVisualState() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var configuration = WallModeConfiguration.defaultConfiguration
        configuration.scheduleEnabled = true
        let store = FakeWallModeStore()
        store.configuration = configuration
        let idleTimer = FakeIdleTimerController(initialValue: false)
        let controller = WallModeController(
            idleTimer: idleTimer,
            store: store,
            calendar: calendar
        )
        let blackoutDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 11, hour: 23))
        )

        controller.setEntitled(true, at: blackoutDate)
        controller.setFrameModeActive(true, at: blackoutDate)
        XCTAssertTrue(idleTimer.isIdleTimerDisabled)
        XCTAssertEqual(controller.visualState, .blackout)

        controller.setEntitled(false, at: blackoutDate)
        XCTAssertFalse(idleTimer.isIdleTimerDisabled)
        XCTAssertEqual(controller.visualState, .normal)
    }
}

@MainActor
private final class FakeIdleTimerController: IdleTimerControlling {
    private var value: Bool
    private(set) var setCount = 0

    init(initialValue: Bool) {
        value = initialValue
    }

    var isIdleTimerDisabled: Bool {
        get { value }
        set {
            value = newValue
            setCount += 1
        }
    }
}

private final class FakeWallModeStore: WallModeConfigurationStoring {
    var configuration = WallModeConfiguration.defaultConfiguration
    private(set) var savedConfiguration: WallModeConfiguration?

    func loadConfiguration() -> WallModeConfiguration {
        configuration
    }

    func saveConfiguration(_ configuration: WallModeConfiguration) throws {
        savedConfiguration = configuration
        self.configuration = configuration
    }
}
