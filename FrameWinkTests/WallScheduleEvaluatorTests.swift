import XCTest
@testable import FrameWink

final class WallScheduleEvaluatorTests: XCTestCase {
    private let evaluator = WallScheduleEvaluator()
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    func testEveningDimAndOvernightBlackoutCrossMidnight() throws {
        let configuration = WallModeConfiguration(
            scheduleEnabled: true,
            dimStartMinute: 20 * 60,
            blackoutStartMinute: 23 * 60,
            blackoutEndMinute: 7 * 60,
            dimOpacity: 0.6,
            completedChecklistItems: []
        )

        XCTAssertEqual(state(hour: 19, configuration: configuration), .normal)
        XCTAssertEqual(state(hour: 21, configuration: configuration), .dimmed(opacity: 0.6))
        XCTAssertEqual(state(hour: 23, configuration: configuration), .blackout)
        XCTAssertEqual(state(hour: 2, configuration: configuration), .blackout)
        XCTAssertEqual(state(hour: 7, configuration: configuration), .normal)
    }

    func testScheduleIsInactiveOutsideForegroundFrameMode() throws {
        let configuration = WallModeConfiguration(
            scheduleEnabled: true,
            dimStartMinute: 20 * 60,
            blackoutStartMinute: 23 * 60,
            blackoutEndMinute: 7 * 60,
            dimOpacity: 0.6,
            completedChecklistItems: []
        )
        let blackoutDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 11, hour: 23))
        )

        XCTAssertEqual(
            evaluator.visualState(
                at: blackoutDate,
                calendar: calendar,
                configuration: configuration,
                frameModeIsActive: false,
                sceneIsForeground: true
            ),
            .normal
        )
        XCTAssertEqual(
            evaluator.visualState(
                at: blackoutDate,
                calendar: calendar,
                configuration: configuration,
                frameModeIsActive: true,
                sceneIsForeground: false
            ),
            .normal
        )
    }

    func testDisabledScheduleNeverDims() throws {
        var configuration = WallModeConfiguration.defaultConfiguration
        configuration.scheduleEnabled = false

        XCTAssertEqual(state(hour: 23, configuration: configuration), .normal)
    }

    func testCommissioningChecklistCoversAllRequiredSafetyTopics() {
        XCTAssertEqual(WallChecklistItem.allCases.count, 10)
        XCTAssertTrue(WallChecklistItem.allCases.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(WallChecklistItem.allCases.allSatisfy { !$0.detail.isEmpty })
        XCTAssertTrue(
            WallChecklistItem.allCases.contains { $0 == .batteryCondition }
        )
        XCTAssertTrue(WallChecklistItem.allCases.contains { $0 == .rebootRecovery })
    }

    private func state(
        hour: Int,
        minute: Int = 0,
        configuration: WallModeConfiguration
    ) -> WallVisualState {
        let date = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 11, hour: hour, minute: minute)
        )!
        return evaluator.visualState(
            at: date,
            calendar: calendar,
            configuration: configuration,
            frameModeIsActive: true,
            sceneIsForeground: true
        )
    }
}
