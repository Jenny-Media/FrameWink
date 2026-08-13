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
        let choosePhotos = app.buttons["Choose Photos"]
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

        XCTAssertTrue(
            app.staticTexts["3 photos are ready."]
                .waitForExistence(timeout: 8)
        )

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(startFrame.waitForExistence(timeout: 8))
        startFrame.tap()
        let firstPhoto = app.descendants(matching: .any)[
            "frame-photo-78F4585F-54C5-4360-9C36-34E2C3F82BC4"
        ].firstMatch
        XCTAssertTrue(
            firstPhoto.waitForExistence(timeout: 8)
        )
        XCTAssertFalse(app.staticTexts["Selected privately on this iPad"].exists)

        app.terminate()
        launch(scenario: "personal-reel")

        let more = app.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 8))
        more.tap()
        let deleteImportedPhotos = app.buttons["delete-imported-photos"]
        XCTAssertTrue(deleteImportedPhotos.waitForExistence(timeout: 8))
        deleteImportedPhotos.tap()

        let confirmDelete = app.buttons["confirm-delete-imported-photos"].firstMatch
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 8))
        confirmDelete.tap()

        XCTAssertTrue(
            app.staticTexts["Bundled sample photos"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.buttons["Choose Photos"].exists)
        XCTAssertFalse(app.buttons["Delete Imported Photos"].exists)
    }

    func testInitialPersonalImportUsesNeutralPreparationInsteadOfSamples() {
        launch(scenario: "personal-import")

        XCTAssertTrue(
            app.staticTexts["Preparing My Photos on this iPad"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertFalse(app.staticTexts["Bundled sample photos"].exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["frame-photo-sample-lakeside"].exists
        )
    }

    func testPersonalFrameRotatesAndSwipeAdvancesToTheNextPhoto() {
        launch(scenario: "personal-reel")

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(waitForLandscape())

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(startFrame.waitForExistence(timeout: 8))
        startFrame.tap()

        let guidance = app.staticTexts["Tap for controls · Swipe to navigate"]
        XCTAssertTrue(guidance.waitForExistence(timeout: 2))
        let playbackControl = app.buttons["frame-playback-control"]
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 2))
        playbackControl.tap()
        let firstPhoto = app.descendants(matching: .any)[
            "frame-photo-78F4585F-54C5-4360-9C36-34E2C3F82BC4"
        ].firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 8))

        let closeControl = app.buttons["frame-close-control"]
        XCTAssertTrue(closeControl.waitForExistence(timeout: 2))
        RunLoop.current.run(until: Date().addingTimeInterval(5))
        XCTAssertTrue(closeControl.exists, "Paused playback must keep controls visible.")
        XCTAssertFalse(guidance.exists, "Guidance must recede while playback is paused.")

        app.tap()
        XCTAssertTrue(waitForNonexistence(closeControl, timeout: 2))
        app.swipeLeft()

        let secondPhoto = app.descendants(matching: .any)[
            "frame-photo-5255CD65-7C11-4EEB-B7F5-85FC76A4D11B"
        ].firstMatch
        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 4))
        XCTAssertFalse(firstPhoto.exists, "One swipe must leave the original page.")
        XCTAssertFalse(closeControl.exists, "Swipe navigation must keep playback chrome hidden.")

        app.tap()
        XCTAssertTrue(closeControl.waitForExistence(timeout: 2))
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 2))
        playbackControl.tap()
        XCTAssertTrue(
            waitForNonexistence(closeControl, timeout: 7),
            "Playing controls must recede automatically."
        )
        app.tap()
        XCTAssertTrue(closeControl.waitForExistence(timeout: 2))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(waitForPortrait())
        XCTAssertTrue(secondPhoto.exists)
    }

    func testBlackoutTapRevealsEscapeControl() {
        launch(scenario: "blackout-frame")

        let closeControl = app.buttons["frame-close-control"]
        XCTAssertTrue(closeControl.waitForExistence(timeout: 8))
        XCTAssertTrue(waitForNonexistence(closeControl, timeout: 7))

        app.tap()
        XCTAssertTrue(
            closeControl.waitForExistence(timeout: 3),
            "A blackout tap must reveal the visible Frame Mode escape control."
        )
    }

    func testAuthorizedPhysicalPhotoLibraryLoadsAlbumPicker() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("Real PhotoKit album discovery requires a physical iPad.")
#else
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_PHYSICAL_ACCEPTANCE"] = "1"
        app.launch()

        let chooseAlbum = app.buttons["album-picker-action"]
        XCTAssertTrue(chooseAlbum.waitForExistence(timeout: 8))

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(
            springboard.alerts.firstMatch.exists,
            "Authorize Photos manually before running physical album verification."
        )

        chooseAlbum.tap()

        let albumList = app.descendants(matching: .any)["album-picker-list"]
        XCTAssertTrue(
            albumList.waitForExistence(timeout: 10),
            "The real PhotoKit album list did not replace the loading state."
        )
        XCTAssertFalse(app.descendants(matching: .any)["album-picker-error"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["album-picker-empty"].exists)
#endif
    }

    func testHomeUsesOnePrimaryActionAndMovesMaintenanceBehindMore() {
        launch(scenario: "sample")

        XCTAssertTrue(app.buttons["Choose Photos"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Start Sample Frame"].exists)
        XCTAssertTrue(app.buttons["More"].exists)
        XCTAssertFalse(app.buttons["Wall Mode Setup"].exists)
        XCTAssertFalse(app.buttons["Privacy"].exists)
        XCTAssertFalse(app.buttons["Review Suggestions"].exists)

        app.buttons["More"].tap()

        XCTAssertTrue(app.buttons["Privacy"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["More Frame Features"].exists)
    }

    func testFrameSettingsHidesLegacyWallModeAndStrictOfflineControls() {
        launch(scenario: "wall-mode-setup")

        XCTAssertTrue(app.navigationBars["Frame Settings"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Photos"].exists)
        XCTAssertTrue(app.staticTexts["Slideshow"].exists)
        XCTAssertTrue(app.switches["Night Schedule"].exists)
        XCTAssertFalse(app.navigationBars["Wall Mode Setup"].exists)
        XCTAssertFalse(app.switches["Strict Offline"].exists)
        XCTAssertFalse(app.staticTexts["Saved frame configurations"].exists)
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

    private func waitForNonexistence(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
