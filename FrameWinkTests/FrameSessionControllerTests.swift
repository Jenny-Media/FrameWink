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

    func testSelectingPageForAResizeDoesNotResetThePlaybackDeadline() {
        var controller = FrameSessionController(
            pageCount: 5,
            currentPageIndex: 1,
            interval: 10,
            startedAt: start
        )

        controller.selectPage(3)
        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(9)))
        XCTAssertTrue(controller.tick(at: start.addingTimeInterval(10)))
        XCTAssertEqual(controller.currentPageIndex, 4)
    }

    func testInteractiveResizePreservesRemainingPlaybackTime() {
        var controller = FrameSessionController(
            pageCount: 4,
            interval: 10,
            startedAt: start
        )

        controller.suspendAdvancement(at: start.addingTimeInterval(4))
        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(14)))
        XCTAssertEqual(controller.currentPageIndex, 0)
        controller.resumeAdvancement(at: start.addingTimeInterval(14))
        XCTAssertFalse(controller.tick(at: start.addingTimeInterval(19)))
        XCTAssertTrue(controller.tick(at: start.addingTimeInterval(20)))
        XCTAssertEqual(controller.currentPageIndex, 1)
    }

    func testResizeCoordinatorPreservesAnchorTimingPlaybackAndHistory() throws {
        func page(_ id: String, photos: [String]) -> FramePage {
            FramePage(
                id: id,
                kind: photos.count == 1 ? .singleFill : .pairedPortraits,
                placements: photos.enumerated().map { index, photoID in
                    FrameLayoutPlacement(
                        id: "\(id)-\(photoID)",
                        photoID: photoID,
                        screenFrame: NormalizedRect(
                            x: Double(index) / Double(photos.count),
                            y: 0,
                            width: 1 / Double(photos.count),
                            height: 1
                        ),
                        sourceCrop: .unit,
                        contentMode: .fit
                    )
                }
            )
        }

        var coordinator = FramePlaybackCoordinator(
            session: FrameSessionController(
                pageCount: 2,
                interval: 10,
                startedAt: start
            )
        )
        let initialPages = [page("wide-a", photos: ["a"]), page("wide-b", photos: ["b"])]
        coordinator.synchronizePages(initialPages, signature: "wide")
        XCTAssertEqual(coordinator.featuredPhotoID, "a")

        var historyPageIDs: [String] = []
        coordinator.setInteractiveResize(true, at: start.addingTimeInterval(4))
        let pairedPages = [page("pair", photos: ["a", "b"])]
        coordinator.synchronizePages(pairedPages, signature: "paired")
        if let page = coordinator.pageChangeRequiringHistory(in: pairedPages) {
            historyPageIDs.append(page.id)
        }
        let compactPages = [page("compact-a", photos: ["a"]), page("compact-b", photos: ["b"])]
        coordinator.synchronizePages(compactPages, signature: "compact")
        if let page = coordinator.pageChangeRequiringHistory(in: compactPages) {
            historyPageIDs.append(page.id)
        }

        XCTAssertFalse(coordinator.tick(at: start.addingTimeInterval(14)))
        XCTAssertTrue(coordinator.isPlaying)
        XCTAssertEqual(coordinator.featuredPhotoID, "a")
        XCTAssertTrue(historyPageIDs.isEmpty)

        coordinator.setInteractiveResize(false, at: start.addingTimeInterval(14))
        XCTAssertFalse(coordinator.tick(at: start.addingTimeInterval(19)))
        XCTAssertTrue(coordinator.tick(at: start.addingTimeInterval(20)))
        if let page = coordinator.pageChangeRequiringHistory(in: compactPages) {
            historyPageIDs.append(page.id)
        }

        XCTAssertEqual(coordinator.currentPageIndex, 1)
        XCTAssertEqual(coordinator.featuredPhotoID, "b")
        XCTAssertEqual(historyPageIDs, ["compact-b"])
    }

    func testProvisionalReelNavigationSynchronizesBeforeViewCallback() {
        let pages = (0..<30).map { index in
            FramePage(
                id: "provisional-\(index)",
                kind: .singleFit,
                placements: [
                    FrameLayoutPlacement(
                        id: "provisional-placement-\(index)",
                        photoID: "photo-\(index)",
                        screenFrame: .unit,
                        sourceCrop: .unit,
                        contentMode: .fit
                    ),
                ]
            )
        }
        let signature = pages.map(\.id).joined(separator: "|")
        var manualCoordinator = FramePlaybackCoordinator(
            session: FrameSessionController(pageCount: 0, startedAt: start)
        )
        manualCoordinator.synchronizePages([], signature: signature)
        XCTAssertEqual(manualCoordinator.pageCount, 0)

        manualCoordinator.next(in: pages, signature: signature, at: start)
        XCTAssertEqual(manualCoordinator.pageCount, 30)
        XCTAssertEqual(manualCoordinator.currentPageIndex, 1)
        XCTAssertEqual(manualCoordinator.featuredPhotoID, "photo-1")

        let reflowedPages = pages.map { page in
            FramePage(
                id: "reflowed-" + page.id,
                kind: .singleFit,
                placements: page.placements
            )
        }
        manualCoordinator.synchronizePages(
            reflowedPages,
            signature: reflowedPages.map(\.id).joined(separator: "|")
        )
        XCTAssertEqual(manualCoordinator.currentPageIndex, 1)
        XCTAssertEqual(
            manualCoordinator.activePage(in: reflowedPages)?.placements.first?.photoID,
            "photo-1"
        )

        manualCoordinator.previous(in: pages, signature: signature, at: start)
        XCTAssertEqual(manualCoordinator.currentPageIndex, 0)

        var timerCoordinator = FramePlaybackCoordinator(
            session: FrameSessionController(
                pageCount: 0,
                interval: 5,
                startedAt: start
            )
        )
        XCTAssertTrue(
            timerCoordinator.tick(
                in: pages,
                signature: signature,
                at: start.addingTimeInterval(5)
            )
        )
        XCTAssertEqual(timerCoordinator.currentPageIndex, 1)
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

    func testVoiceOverAndPauseKeepFrameControlsVisible() {
        XCTAssertFalse(
            FrameOverlayVisibilityPolicy.shouldAutomaticallyHideControls(
                isFrameMode: true,
                isPlaying: true,
                voiceOverEnabled: true
            )
        )
        XCTAssertFalse(
            FrameOverlayVisibilityPolicy.shouldAutomaticallyHideControls(
                isFrameMode: true,
                isPlaying: false,
                voiceOverEnabled: false
            )
        )
        XCTAssertTrue(
            FrameOverlayVisibilityPolicy.shouldAutomaticallyHideControls(
                isFrameMode: true,
                isPlaying: true,
                voiceOverEnabled: false
            )
        )
    }
}
