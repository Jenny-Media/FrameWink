import XCTest
@testable import FrameWink

final class FrameSessionControllerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testTimerAdvancesAndWrapsWithoutDrift() {
        var controller = FrameSessionController(
            pageCount: 3,
            interval: 5,
            startedAt: start
        )

        controller.tick(at: start.addingTimeInterval(16))
        XCTAssertEqual(controller.currentPageIndex, 0)

        controller.tick(at: start.addingTimeInterval(21))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testPauseAndResumeDoNotDuplicateTimerAdvances() {
        var controller = FrameSessionController(
            pageCount: 4,
            interval: 5,
            startedAt: start
        )

        controller.pause()
        controller.tick(at: start.addingTimeInterval(30))
        XCTAssertEqual(controller.currentPageIndex, 0)

        controller.resume(at: start.addingTimeInterval(30))
        controller.tick(at: start.addingTimeInterval(35))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testManualPreviousAndNextWrapAtReelEnds() {
        var controller = FrameSessionController(pageCount: 3, startedAt: start)

        controller.previous(at: start)
        XCTAssertEqual(controller.currentPageIndex, 2)
        controller.next(at: start)
        XCTAssertEqual(controller.currentPageIndex, 0)
    }

    func testThirtyPhotoFixtureReplaysStably() {
        var controller = FrameSessionController(pageCount: 30, startedAt: start)

        for offset in 1...90 {
            controller.next(at: start.addingTimeInterval(Double(offset)))
        }

        XCTAssertEqual(controller.currentPageIndex, 0)
        XCTAssertEqual(controller.pageCount, 30)
    }

    func testPageCountChangeKeepsIndexInBounds() {
        var controller = FrameSessionController(
            pageCount: 5,
            currentPageIndex: 4,
            startedAt: start
        )

        controller.updatePageCount(2)
        XCTAssertEqual(controller.currentPageIndex, 1)
        controller.updatePageCount(0)
        XCTAssertEqual(controller.currentPageIndex, 0)
    }

    func testChangingIntervalResetsTheAdvanceDeadline() {
        var controller = FrameSessionController(
            pageCount: 3,
            interval: 5,
            startedAt: start
        )

        controller.setInterval(10, at: start.addingTimeInterval(4))
        controller.tick(at: start.addingTimeInterval(13))
        XCTAssertEqual(controller.currentPageIndex, 0)
        controller.tick(at: start.addingTimeInterval(14))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testTickReportsOnlyVisiblePageChanges() {
        var controller = FrameSessionController(
            pageCount: 3,
            interval: 5,
            startedAt: start
        )

        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(4)))
        XCTAssertEqual(controller.currentPageIndex, 0)
        XCTAssertTrue(controller.tick(at: start.addingTimeInterval(5)))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testTickDoesNotReportAnAdvanceThatReturnsToTheSamePage() {
        var controller = FrameSessionController(
            pageCount: 3,
            interval: 5,
            startedAt: start
        )

        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(15)))
        XCTAssertEqual(controller.currentPageIndex, 0)
        XCTAssertTrue(controller.tick(at: start.addingTimeInterval(20)))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testTickDoesNotReportAVisibleChangeForOnePage() {
        var controller = FrameSessionController(
            pageCount: 1,
            interval: 5,
            startedAt: start
        )

        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(5)))
        XCTAssertEqual(controller.currentPageIndex, 0)
    }
}
