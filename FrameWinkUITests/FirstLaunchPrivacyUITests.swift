import XCTest

final class FirstLaunchPrivacyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    func testSampleModeDoesNotPromptUntilPickerActionAndPickerCancelsCleanly() {
        launch(scenario: "sample")

        XCTAssertTrue(
            app.staticTexts["Bundled sample photos"].waitForExistence(timeout: 8)
        )
        let choosePhotos = app.buttons["Choose My Photos"]
        XCTAssertTrue(choosePhotos.waitForExistence(timeout: 8))

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(springboard.alerts.firstMatch.exists)

        choosePhotos.tap()
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        XCTAssertFalse(springboard.alerts.firstMatch.exists)

        cancel.tap()

        XCTAssertTrue(choosePhotos.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Bundled sample photos"].exists)
    }

    func testPersonalReelPlaysFromLocalCopiesAndDeleteAllReturnsToSamples() {
        launch(scenario: "personal-reel")

        let myPhotos = app.buttons["My Photos"]
        XCTAssertTrue(myPhotos.waitForExistence(timeout: 8))
        XCTAssertTrue(myPhotos.isSelected)
        XCTAssertTrue(
            app.staticTexts["3 Smart Reel suggestions are ready to review."]
                .waitForExistence(timeout: 8)
        )

        let playFullScreen = app.buttons["Play Full Screen"]
        XCTAssertTrue(playFullScreen.waitForExistence(timeout: 8))
        playFullScreen.tap()
        XCTAssertTrue(
            app.staticTexts["Curated privately on this iPad"]
                .waitForExistence(timeout: 8)
        )

        app.terminate()
        launch(scenario: "personal-reel")

        let deleteImportedPhotos = app.buttons["delete-imported-photos"]
        XCTAssertTrue(deleteImportedPhotos.waitForExistence(timeout: 8))
        deleteImportedPhotos.tap()

        let confirmDelete = app.buttons["confirm-delete-imported-photos"].firstMatch
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 8))
        confirmDelete.tap()

        XCTAssertTrue(
            app.staticTexts["Bundled sample photos"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.buttons["Choose My Photos"].exists)
        XCTAssertFalse(app.buttons["Delete Imported Photos"].exists)
    }

    func testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto() {
        launch(scenario: "personal-reel")

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(waitForLandscape())

        let playFullScreen = app.buttons["Play Full Screen"]
        XCTAssertTrue(playFullScreen.waitForExistence(timeout: 8))
        playFullScreen.tap()

        let firstPhoto = app.descendants(matching: .any)[
            "frame-photo-78F4585F-54C5-4360-9C36-34E2C3F82BC4"
        ].firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 8))

        app.swipeLeft()

        let secondPhoto = app.descendants(matching: .any)[
            "frame-photo-5255CD65-7C11-4EEB-B7F5-85FC76A4D11B"
        ].firstMatch
        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 8))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(waitForPortrait())
        XCTAssertTrue(secondPhoto.exists)
    }

    private func launch(scenario: String) {
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_SCREENSHOT_SCENARIO"] = scenario
        app.launch()
    }

    private func waitForLandscape(timeout: TimeInterval = 8) -> Bool {
        waitForOrientation(timeout: timeout) { $0.width > $0.height }
    }

    private func waitForPortrait(timeout: TimeInterval = 8) -> Bool {
        waitForOrientation(timeout: timeout) { $0.height > $0.width }
    }

    private func waitForOrientation(
        timeout: TimeInterval,
        matches: (CGSize) -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if matches(app.frame.size) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return matches(app.frame.size)
    }
}
