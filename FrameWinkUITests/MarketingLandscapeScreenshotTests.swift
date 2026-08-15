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
            name: "01-landscape-frame"
        )
        if UIDevice.current.userInterfaceIdiom == .pad {
            try capture(
                scenario: "mosaic-frame",
                name: "02-landscape-mosaic"
            )
        }
        try capture(
            scenario: "frame-controls",
            name: "03-landscape-controls"
        )
        try capture(
            scenario: "free-review-grid",
            name: "04-landscape-review"
        )
    }

    private func capture(
        scenario: String,
        name: String,
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
