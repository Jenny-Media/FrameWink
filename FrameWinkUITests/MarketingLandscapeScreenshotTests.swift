import XCTest
import UIKit

final class MarketingLandscapeScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    override func tearDownWithError() throws {
        app?.terminate()
        XCUIDevice.shared.orientation = .portrait
    }

    func testCaptureLandscapeMarketingScreens() throws {
        try capture(
            scenario: "smart-frame",
            name: "01-landscape-frame",
            expectsCleanPlayback: true
        )
        if UIDevice.current.userInterfaceIdiom == .pad {
            try capture(
                scenario: "mosaic-frame",
                name: "02-landscape-mosaic",
                expectsCleanPlayback: true
            )
            try capture(
                scenario: "free-review-grid",
                name: "03-landscape-review"
            )
            try capture(
                scenario: "album-picker",
                name: "04-landscape-album-picker"
            )
            try capture(
                scenario: "frame-controls",
                name: "05-landscape-controls",
                expectsControlsPanel: true
            )
            try capture(
                scenario: "sample",
                name: "06-landscape-sample"
            )
            try capture(
                scenario: "wall-schedule",
                name: "07-landscape-night-schedule"
            )
            try capture(
                scenario: "wall-checklist",
                name: "08-landscape-mounted-tips"
            )
            try capture(
                scenario: "paywall",
                name: "09-landscape-lifetime-purchase"
            )
            try capture(
                scenario: "paywall-features",
                name: "10-landscape-lifetime-features"
            )
            return
        }
        try capture(
            scenario: "frame-controls",
            name: "02-landscape-controls",
            expectsControlsPanel: true
        )
        try capture(
            scenario: "free-review-grid",
            name: "03-landscape-review"
        )
    }

    func testCaptureWebsitePairedPhotoScreen() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("The website pair capture is iPad-specific.")
        }
        try capture(
            scenario: "paired-frame",
            name: "website-landscape-pair",
            expectsCleanPlayback: true,
            expectedVisiblePhotoCount: 2
        )
    }

    private func capture(
        scenario: String,
        name: String,
        expectsCleanPlayback: Bool = false,
        expectsControlsPanel: Bool = false,
        expectedVisiblePhotoCount: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        app?.terminate()
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_SCREENSHOT_SCENARIO"] = scenario
        app.launch()

        XCTAssertTrue(
            waitForLandscape(),
            "FrameWink did not settle into landscape for \(scenario).",
            file: file,
            line: line
        )
        RunLoop.current.run(until: Date().addingTimeInterval(2.5))

        if expectsCleanPlayback {
            XCTAssertFalse(
                app.descendants(matching: .any)["frame-quick-close-control"].exists,
                "Clean playback should not show the exit control.",
                file: file,
                line: line
            )
            XCTAssertFalse(
                app.descendants(matching: .any)["frame-playback-control"].exists,
                "Clean playback should not show the bottom toolbar.",
                file: file,
                line: line
            )
        }
        if expectsControlsPanel {
            XCTAssertTrue(
                app.descendants(matching: .any)["frame-controls-panel"].waitForExistence(timeout: 2),
                "The controls-specific capture should show the duration panel.",
                file: file,
                line: line
            )
        }
        if let expectedVisiblePhotoCount {
            let photoTargets = app.descendants(matching: .any).matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "frame-photo-actions-"
                )
            )
            XCTAssertEqual(
                photoTargets.count,
                expectedVisiblePhotoCount,
                "The capture should expose one action target per visible photo.",
                file: file,
                line: line
            )
        }

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForLandscape(timeout: TimeInterval = 8) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if app.frame.width > app.frame.height { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return app.frame.width > app.frame.height
    }
}
