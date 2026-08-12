import XCTest

final class FirstLaunchPrivacyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
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

    private func launch(scenario: String) {
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_SCREENSHOT_SCENARIO"] = scenario
        app.launch()
    }
}
