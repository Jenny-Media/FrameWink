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

    func testChooseWhatPlaysExplainsIndividualPhotosBeforeSystemPicker() {
        launch(scenario: "sample")

        app.buttons["More"].tap()
        app.buttons["Choose What Plays…"].tap()

        XCTAssertTrue(app.navigationBars["Choose What Plays"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Pick Individual Photos"].exists)
        XCTAssertTrue(app.staticTexts["Choose specific photos for this frame"].exists)
        XCTAssertTrue(app.staticTexts["Use an Album"].exists)
        XCTAssertTrue(
            app.staticTexts["Choose an album and keep this frame up to date"].exists
        )

        app.buttons["photo-source-personal"].tap()

        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(
            cancel.waitForExistence(timeout: 8),
            "Pick Individual Photos must open PHPicker after the explanatory choice."
        )
        cancel.tap()
        XCTAssertTrue(app.buttons["Choose Photos"].waitForExistence(timeout: 8))
    }

    func testLockedAlbumChoiceExplainsLifetimeBeforeRequestingPhotosAccess() {
        launch(scenario: "sample")

        app.buttons["More"].tap()
        app.buttons["Choose What Plays…"].tap()
        XCTAssertTrue(app.navigationBars["Choose What Plays"].waitForExistence(timeout: 4))

        app.buttons["photo-source-automatic"].tap()

        XCTAssertTrue(
            app.navigationBars["FrameWink Lifetime"].waitForExistence(timeout: 8),
            "The locked album choice must explain Lifetime before requesting Photos access."
        )
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
        XCTAssertFalse(app.staticTexts["Selected privately on this device"].exists)

        app.terminate()
        launch(scenario: "personal-reel")

        let more = app.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 8))
        more.tap()
        app.buttons["Privacy & Data"].tap()
        XCTAssertTrue(app.navigationBars["Privacy & Data"].waitForExistence(timeout: 4))
        let deleteImportedPhotos = app.buttons["delete-imported-photos"]
        if !deleteImportedPhotos.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
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

    func testReadyHomePreviewCanSwipeBeforeStartingFrame() {
        launch(scenario: "personal-reel")

        let firstPhoto = app.descendants(matching: .any)[
            "frame-photo-78F4585F-54C5-4360-9C36-34E2C3F82BC4"
        ].firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Start Frame"].exists)

        app.swipeLeft()

        let secondPhoto = app.descendants(matching: .any)[
            "frame-photo-5255CD65-7C11-4EEB-B7F5-85FC76A4D11B"
        ].firstMatch
        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 4))
        XCTAssertFalse(firstPhoto.exists)
        XCTAssertTrue(app.buttons["Start Frame"].exists)
        XCTAssertFalse(app.buttons["frame-close-control"].exists)
    }

    func testLongPressPhotoOffersNativeShareAction() {
        launch(scenario: "personal-reel")

        let actionTarget = app.descendants(matching: .any)[
            "frame-photo-actions-78F4585F-54C5-4360-9C36-34E2C3F82BC4"
        ].firstMatch
        XCTAssertTrue(actionTarget.waitForExistence(timeout: 8))

        actionTarget.press(forDuration: 1)

        XCTAssertTrue(
            app.buttons["Share Photo"].waitForExistence(timeout: 4),
            "Long-pressing a displayed photo must reveal its native share action."
        )
    }

    func testChangingPlaybackSettingsKeepsTheSelectedPhotoSource() {
        launch(scenario: "source-integrity")

        XCTAssertTrue(
            app.staticTexts["Bundled sample photos"].waitForExistence(timeout: 8)
        )
        app.buttons["More"].tap()
        app.buttons["Choose What Plays…"].tap()
        XCTAssertTrue(app.navigationBars["Choose What Plays"].waitForExistence(timeout: 4))
        app.buttons["photo-source-personal"].tap()

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(startFrame.waitForExistence(timeout: 8))
        startFrame.tap()

        let personalPhotos = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier IN %@",
                [
                    "frame-photo-78F4585F-54C5-4360-9C36-34E2C3F82BC4",
                    "frame-photo-5255CD65-7C11-4EEB-B7F5-85FC76A4D11B",
                    "frame-photo-37D2AC69-E0DE-4F0C-A769-8668CBD07BE6",
                ]
            )
        )
        XCTAssertTrue(personalPhotos.firstMatch.waitForExistence(timeout: 8))

        let playbackControl = app.buttons["frame-playback-control"]
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 3))
        playbackControl.tap()

        let playbackOptions = app.buttons["More playback options"]
        XCTAssertTrue(playbackOptions.waitForExistence(timeout: 3))
        playbackOptions.tap()
        XCTAssertTrue(
            app.navigationBars["Frame Controls"]
                .waitForExistence(timeout: 3)
        )
        let speed = app.segmentedControls["frame-duration-picker"].buttons["10s"]
        XCTAssertTrue(speed.waitForExistence(timeout: 3))
        speed.tap()

        XCTAssertTrue(personalPhotos.firstMatch.waitForExistence(timeout: 4))
        XCTAssertFalse(
            app.descendants(matching: .any)["frame-photo-sample-city-skyline"].exists,
            "Changing speed must not reactivate a stale saved sample source."
        )

        XCTAssertFalse(app.buttons["frame-layout-fit"].exists)
        XCTAssertFalse(app.buttons["frame-layout-fill"].exists)
    }

    func testInitialPersonalImportUsesNeutralPreparationInsteadOfSamples() {
        launch(scenario: "personal-import")

        XCTAssertTrue(
            app.staticTexts["Preparing My Photos on this device"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.navigationBars["Preparing Photos"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["0 of 3 finished"].exists)
        XCTAssertTrue(app.buttons["cancel-photo-import"].isHittable)
        XCTAssertFalse(app.staticTexts["Bundled sample photos"].exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["frame-photo-sample-city-skyline"].exists
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

        let secondPhoto = app.descendants(matching: .any)[
            "frame-photo-5255CD65-7C11-4EEB-B7F5-85FC76A4D11B"
        ].firstMatch
        app.swipeLeft()
        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 4))
        app.swipeRight()
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 4))

        let playbackOptions = app.buttons["More playback options"]
        XCTAssertTrue(playbackOptions.waitForExistence(timeout: 2))
        RunLoop.current.run(until: Date().addingTimeInterval(5))
        XCTAssertTrue(playbackOptions.exists, "Paused playback must keep controls visible.")
        XCTAssertFalse(guidance.exists, "Guidance must recede while playback is paused.")

        app.tap()
        XCTAssertTrue(waitForNonexistence(playbackOptions, timeout: 2))
        app.swipeLeft()

        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 4))
        XCTAssertFalse(firstPhoto.exists, "One swipe must leave the original page.")
        XCTAssertFalse(playbackOptions.exists, "Swipe navigation must keep playback chrome hidden.")

        app.tap()
        XCTAssertTrue(playbackOptions.waitForExistence(timeout: 2))
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 2))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(waitForPortrait())
        XCTAssertTrue(
            secondPhoto.waitForExistence(timeout: 4),
            "The active photo must survive the physical orientation transition."
        )

        playbackControl.tap()
        XCTAssertTrue(
            waitForNonexistence(playbackOptions, timeout: 7),
            "Playing controls must recede automatically."
        )
    }

    func testBlackoutTapRevealsEscapeControl() {
        launch(scenario: "blackout-frame")

        let playbackOptions = app.buttons["More playback options"]
        XCTAssertFalse(
            playbackOptions.waitForExistence(timeout: 1),
            "The clean blackout scenario must begin without playback chrome."
        )

        app.tap()
        XCTAssertTrue(
            playbackOptions.waitForExistence(timeout: 3),
            "A blackout tap must reveal playback controls."
        )
        XCTAssertTrue(
            app.buttons["frame-quick-close-control"].waitForExistence(timeout: 3),
            "A blackout tap must reveal the direct exit control."
        )
    }

    func testFrameControlsPanelOffersTimingAndShare() {
        launch(scenario: "personal-reel")

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(startFrame.waitForExistence(timeout: 8))
        startFrame.tap()

        let playbackOptions = app.buttons["More playback options"]
        XCTAssertTrue(playbackOptions.waitForExistence(timeout: 3))
        let shareAction = app.buttons["frame-share-current-photos"]
        XCTAssertTrue(
            shareAction.isHittable,
            "Frame playback must expose sharing without opening More."
        )
        XCTAssertFalse(app.buttons["Previous photo"].exists)
        XCTAssertFalse(app.buttons["Next photo"].exists)
        XCTAssertTrue(
            app.buttons["frame-quick-close-control"].isHittable,
            "Frame playback must expose a direct one-tap exit when controls are visible."
        )

        playbackOptions.tap()
        XCTAssertTrue(
            app.navigationBars["Frame Controls"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.buttons["frame-close-control"].exists)
        XCTAssertFalse(
            app.buttons["frame-share-current-photos"].isHittable,
            "The playback bar must sit behind the open Frame Controls popover."
        )
        let durationPicker = app.segmentedControls["frame-duration-picker"]
        XCTAssertTrue(durationPicker.waitForExistence(timeout: 3))
        XCTAssertTrue(durationPicker.buttons["10s"].exists)
        XCTAssertTrue(durationPicker.buttons["30s"].exists)
        XCTAssertTrue(durationPicker.buttons["1m"].exists)
        XCTAssertTrue(durationPicker.buttons["5m"].exists)
        XCTAssertFalse(durationPicker.buttons["5s"].exists)
        XCTAssertFalse(app.buttons["frame-layout-fit"].exists)
        XCTAssertFalse(app.buttons["frame-layout-fill"].exists)
        XCTAssertTrue(app.staticTexts["Photo Duration"].exists)

        let tenSeconds = durationPicker.buttons["10s"]
        XCTAssertFalse(tenSeconds.isSelected)
        tenSeconds.tap()
        XCTAssertTrue(
            tenSeconds.isSelected,
            "A duration must become selected on the first tap."
        )
        XCTAssertFalse(durationPicker.buttons["30s"].isSelected)

        let panelScreenshot = XCTAttachment(screenshot: app.screenshot())
        panelScreenshot.name = "Frame Controls panel"
        panelScreenshot.lifetime = .keepAlways
        add(panelScreenshot)
    }

    func testFrameDurationRespondsToEverySingleTap() {
        launch(scenario: "frame-controls")

        XCTAssertTrue(
            app.navigationBars["Frame Controls"]
                .waitForExistence(timeout: 8)
        )

        let durationPicker = app.segmentedControls["frame-duration-picker"]
        XCTAssertTrue(durationPicker.waitForExistence(timeout: 3))
        let labels = [
            "10s",
            "5m",
            "1m",
            "30s",
            "10s",
        ]
        for label in labels {
            let duration = durationPicker.buttons[label]
            XCTAssertTrue(duration.isHittable, "\(label) must accept a direct tap.")
            duration.tap()
            XCTAssertTrue(
                duration.isSelected,
                "\(label) must become selected after one tap."
            )
        }
    }

    func testSampleCaptionStaysAboveTheCompactSetupCard() {
        launch(scenario: "sample")

        let caption = app.staticTexts["sample-caption-title"]
        let setupCard = app.descendants(matching: .any)["home-setup-card"]
        XCTAssertTrue(caption.waitForExistence(timeout: 8))
        XCTAssertTrue(setupCard.waitForExistence(timeout: 3))
        XCTAssertLessThanOrEqual(
            caption.frame.maxY,
            setupCard.frame.minY,
            "The sample title must not be hidden beneath the setup card."
        )
    }

    func testSceneOffersOneShareActionMatchingTheResponsiveLayout() {
        launch(scenario: "mosaic-frame")

        let shareAction = app.buttons["frame-share-current-photos"]
        XCTAssertFalse(
            shareAction.waitForExistence(timeout: 1),
            "The clean Mosaic scenario must begin without playback chrome."
        )
        app.tap()
        XCTAssertTrue(shareAction.waitForExistence(timeout: 8))
        let visiblePhotoActions = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'frame-photo-actions-'")
        )
        XCTAssertGreaterThanOrEqual(visiblePhotoActions.count, 1)
        XCTAssertEqual(
            shareAction.label,
            visiblePhotoActions.count == 1 ? "Share Photo" : "Share Photos",
            "The stable share action must match the photos in the responsive scene."
        )
        XCTAssertFalse(app.buttons["frame-share-photo-menu"].exists)
        XCTAssertFalse(app.buttons["Share Featured"].exists)
        XCTAssertFalse(app.buttons["Other Photos"].exists)
    }

    func testReviewNeverShowUsesNativeActionAndCanUndo() {
        launch(scenario: "free-review-grid")

        XCTAssertTrue(app.navigationBars["Photos in This Frame"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["review-frame-summary"].exists)
        let neverShowButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'never-show-'")
        )
        XCTAssertTrue(waitForCount(neverShowButtons, count: 3, timeout: 8))
        let actionIdentifiers = (0..<neverShowButtons.count).map {
            neverShowButtons.element(boundBy: $0).identifier
        }
        for identifier in actionIdentifiers {
            let action = app.buttons[identifier]
            var scrollAttempts = 0
            while !action.isHittable && scrollAttempts < 4 {
                app.swipeUp()
                scrollAttempts += 1
            }
            XCTAssertTrue(
                action.isHittable,
                "Every review card must expose Never Show Again when scrolled into view."
            )
            XCTAssertGreaterThanOrEqual(
                action.frame.height,
                43.5,
                "The rendered control must remain within half a point of the 44-point target."
            )
        }
        guard let visibleActionIdentifier = actionIdentifiers.last else {
            XCTFail("Expected at least one Never Show Again action.")
            return
        }
        let neverShow = app.buttons[visibleActionIdentifier]
        let countBefore = neverShowButtons.count

        neverShow.tap()

        let undo = app.buttons["undo-never-show"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        XCTAssertEqual(neverShowButtons.count, countBefore - 1)
        XCTAssertTrue(app.staticTexts["Removed from this frame"].exists)
        undo.tap()
        XCTAssertTrue(waitForNonexistence(undo, timeout: 3))
        XCTAssertEqual(neverShowButtons.count, countBefore)
    }

    func testReviewHiddenPhotosRemainAboveUndo() {
        assertHiddenPhotosRemainAboveUndo(scenario: "free-review-grid")
    }

    func testReviewHiddenPhotosRemainAboveUndoInLandscape() {
        assertHiddenPhotosRemainAboveUndo(scenario: "free-review-grid", landscape: true)
    }

    func testAutomaticReviewHiddenPhotosRemainAboveUndo() {
        assertHiddenPhotosRemainAboveUndo(scenario: "automatic-album-review")
    }

    func testAutomaticReviewHiddenPhotosRemainAboveUndoInLandscape() {
        assertHiddenPhotosRemainAboveUndo(scenario: "automatic-album-review", landscape: true)
    }

    private func assertHiddenPhotosRemainAboveUndo(scenario: String, landscape: Bool = false) {
        launch(scenario: scenario)
        XCTAssertTrue(app.navigationBars["Photos in This Frame"].waitForExistence(timeout: 8))
        if landscape {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(waitForLandscape())
        }
        let actions = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'never-show-'")
        )
        XCTAssertTrue(actions.firstMatch.waitForExistence(timeout: 8))
        let lastAction = actions.element(boundBy: actions.count - 1)
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<8 {
            // Off-screen SwiftUI buttons can make XCTest's isHittable query
            // fail instead of returning false on compact landscape workers.
            let actionFrame = lastAction.frame
            let visibleFrame = scrollView.frame.intersection(app.frame)
            if !actionFrame.isEmpty && visibleFrame.contains(actionFrame) { break }
            scrollView.swipeUp()
        }
        XCTAssertTrue(lastAction.isHittable)
        lastAction.tap()

        let undo = app.buttons["undo-never-show"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        app.scrollViews.firstMatch.swipeUp(velocity: .fast)

        let hiddenPhotos = app.buttons["manage-hidden-photos"]
        XCTAssertTrue(undo.exists, "Check the layout while the five-second Undo is still showing.")
        XCTAssertTrue(hiddenPhotos.isHittable)
        XCTAssertLessThanOrEqual(
            hiddenPhotos.frame.maxY,
            undo.frame.minY,
            "The entire Hidden from Frame control must scroll above Undo."
        )
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Hidden from Frame above Undo - " + scenario
        screenshot.lifetime = .keepAlways
        add(screenshot)
        hiddenPhotos.tap()
        XCTAssertTrue(app.navigationBars["Hidden from Frame"].waitForExistence(timeout: 3))
    }

    func testReviewCanRestoreAnOlderNeverShowChoice() {
        launch(scenario: "free-review-grid")

        let neverShowButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'never-show-'")
        )
        XCTAssertTrue(waitForCount(neverShowButtons, count: 3, timeout: 8))
        neverShowButtons.firstMatch.tap()

        let hiddenPhotos = app.buttons["manage-hidden-photos"]
        XCTAssertTrue(hiddenPhotos.waitForExistence(timeout: 3))
        hiddenPhotos.tap()

        XCTAssertTrue(app.navigationBars["Hidden from Frame"].waitForExistence(timeout: 3))
        let allowAgain = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'allow-again-'")
        ).firstMatch
        XCTAssertTrue(allowAgain.isHittable)
        allowAgain.tap()

        XCTAssertTrue(waitForNonexistence(app.navigationBars["Hidden from Frame"], timeout: 3))
        XCTAssertTrue(waitForCount(neverShowButtons, count: 3, timeout: 8))
        XCTAssertFalse(app.buttons["manage-hidden-photos"].exists)
    }

    func testReadyFrameOffersClearPhotoChoiceAndReviewActions() {
        launch(scenario: "personal-reel")

        XCTAssertTrue(app.buttons["More"].waitForExistence(timeout: 8))
        app.buttons["More"].tap()

        XCTAssertTrue(app.buttons["Choose What Plays…"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Review Photos in This Frame…"].exists)
        XCTAssertFalse(app.buttons["Add Photos…"].exists)
        XCTAssertFalse(app.buttons["Choose an Album…"].exists)
        XCTAssertFalse(app.buttons["Switch Photo Source…"].exists)

        app.buttons["Review Photos in This Frame…"].tap()
        XCTAssertTrue(app.navigationBars["Photos in This Frame"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["review-frame-summary"].exists)
    }

    func testReviewEmptyStateCanRestoreExcludedPhotos() {
        launch(scenario: "free-review-grid")

        let neverShowButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'never-show-'")
        )
        XCTAssertTrue(waitForCount(neverShowButtons, count: 3, timeout: 8))

        for remainingCount in stride(from: 2, through: 0, by: -1) {
            neverShowButtons.firstMatch.tap()
            XCTAssertTrue(waitForCount(neverShowButtons, count: remainingCount, timeout: 3))
        }

        XCTAssertTrue(app.staticTexts["No photos in this frame"].exists)
        let hiddenPhotos = app.buttons["manage-hidden-photos"]
        XCTAssertTrue(hiddenPhotos.isHittable)
        hiddenPhotos.tap()

        XCTAssertTrue(app.navigationBars["Hidden from Frame"].waitForExistence(timeout: 3))
        let restoreExcluded = app.buttons["restore-excluded-photos"]
        XCTAssertTrue(restoreExcluded.isHittable)
        restoreExcluded.tap()

        XCTAssertTrue(app.alerts["Allow All Photos Again?"].waitForExistence(timeout: 3))
        app.alerts["Allow All Photos Again?"].buttons["Allow All"].tap()

        XCTAssertTrue(waitForCount(neverShowButtons, count: 3, timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any)["review-frame-summary"].exists)
    }

    func testFrameQuickCloseExitsWithoutOpeningMore() {
        launch(scenario: "personal-reel")

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(startFrame.waitForExistence(timeout: 8))
        startFrame.tap()

        let quickClose = app.buttons["frame-quick-close-control"]
        XCTAssertTrue(quickClose.waitForExistence(timeout: 3))
        quickClose.tap()

        XCTAssertTrue(
            startFrame.waitForExistence(timeout: 3),
            "The top-right close control must exit Frame Mode directly."
        )
        XCTAssertFalse(app.descendants(matching: .any)["frame-controls-panel"].exists)
    }

    func testAuthorizedPhysicalPhotoLibraryLoadsAlbumPicker() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("Real PhotoKit album discovery requires a physical iPhone or iPad.")
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
            albumList.waitForExistence(timeout: 3),
            "Album metadata did not replace the loading state within three seconds."
        )
        XCTAssertFalse(app.descendants(matching: .any)["album-picker-error"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["album-picker-empty"].exists)
#endif
    }

    func testAuthorizedPhysicalPhotoLibraryLoadsAnAlbumCover() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("Real PhotoKit album covers require a physical iPhone or iPad.")
#else
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_PHYSICAL_ACCEPTANCE"] = "1"
        app.launch()

        let chooseAlbum = app.buttons["album-picker-action"]
        XCTAssertTrue(chooseAlbum.waitForExistence(timeout: 8))
        chooseAlbum.tap()

        let albumList = app.descendants(matching: .any)["album-picker-list"]
        XCTAssertTrue(albumList.waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.buttons["album-cover-ready"].firstMatch.waitForExistence(timeout: 20),
            "No real PhotoKit album cover became visible within twenty seconds."
        )
#endif
    }

    func testAuthorizedPhysicalPhotoLibraryReopensAlbumPickerFromCache() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("Real PhotoKit album-cover caching requires a physical iPhone or iPad.")
#else
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_PHYSICAL_ACCEPTANCE"] = "1"
        app.launch()

        let chooseAlbum = app.buttons["album-picker-action"]
        XCTAssertTrue(chooseAlbum.waitForExistence(timeout: 8))
        chooseAlbum.tap()

        let albumList = app.descendants(matching: .any)["album-picker-list"]
        XCTAssertTrue(albumList.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["album-cover-ready"].firstMatch.waitForExistence(timeout: 20))

        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 2))
        cancel.tap()
        XCTAssertTrue(chooseAlbum.waitForExistence(timeout: 3))

        let reopenStartedAt = Date()
        chooseAlbum.tap()
        XCTAssertTrue(
            albumList.waitForExistence(timeout: 2),
            "The cached album catalog did not reappear within two seconds."
        )
        XCTAssertTrue(
            app.buttons["album-cover-ready"].firstMatch.waitForExistence(timeout: 2),
            "A cached visible cover did not reappear within two seconds."
        )
        XCTAssertLessThan(
            Date().timeIntervalSince(reopenStartedAt),
            2.5,
            "Closing and reopening the picker should reuse the in-memory catalog and covers."
        )
#endif
    }

    func testConfiguredPhysicalAlbumFrameNavigatesBetweenDistinctPhotos() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("A configured real PhotoKit album requires a physical iPhone or iPad.")
#else
        app = XCUIApplication()
        app.launchEnvironment["FRAMEWINK_PHYSICAL_ACCEPTANCE"] = "1"
        app.launch()

        let startFrame = app.buttons["Start Frame"]
        XCTAssertTrue(
            startFrame.waitForExistence(timeout: 8),
            "Configure and prepare a real automatic album before this check."
        )
        startFrame.tap()

        let albumPhotos = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'frame-photo-album-'")
        )
        let firstPhoto = albumPhotos.firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 8))
        let firstIdentifier = firstPhoto.identifier
        XCTAssertFalse(firstIdentifier.isEmpty)

        app.swipeLeft()

        let nextPhoto = albumPhotos.matching(
            NSPredicate(format: "identifier != %@", firstIdentifier)
        ).firstMatch
        XCTAssertTrue(nextPhoto.waitForExistence(timeout: 4))
        XCTAssertNotEqual(nextPhoto.identifier, firstIdentifier)

        let secondPageIdentifiers = albumPhotos.allElementsBoundByIndex.map(\.identifier)
        app.swipeLeft()
        let thirdPagePhoto = albumPhotos.matching(
            NSPredicate(
                format: "NOT (identifier IN %@)",
                [firstIdentifier] + secondPageIdentifiers
            )
        ).firstMatch
        XCTAssertTrue(
            thirdPagePhoto.waitForExistence(timeout: 4),
            "A second swipe must replace every photo from the preceding real-album page."
        )
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

        XCTAssertTrue(app.buttons["Choose What Plays…"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Privacy & Data"].exists)
        XCTAssertTrue(app.buttons["More Frame Features"].exists)
        XCTAssertFalse(app.buttons["Sample Photos"].exists)
        XCTAssertFalse(app.buttons["Switch Photo Source…"].exists)
        XCTAssertFalse(app.buttons["Review Photos in This Frame…"].exists)

        app.buttons["Choose What Plays…"].tap()
        XCTAssertTrue(app.navigationBars["Choose What Plays"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["photo-source-personal"].exists)
        XCTAssertTrue(app.buttons["photo-source-automatic"].exists)
        XCTAssertTrue(app.buttons["photo-source-samples"].exists)

        let photosScreenshot = XCTAttachment(screenshot: app.screenshot())
        photosScreenshot.name = "Choose What Plays"
        photosScreenshot.lifetime = .keepAlways
        add(photosScreenshot)
    }

    func testPaywallKeepsPurchaseActionWhenProductDetailsAreUnavailable() {
        launch(scenario: "paywall-unavailable")

        XCTAssertTrue(app.navigationBars["FrameWink Lifetime"].waitForExistence(timeout: 8))
        let purchase = app.buttons["purchase-framewink-lifetime"]
        XCTAssertTrue(purchase.waitForExistence(timeout: 4))
        XCTAssertEqual(purchase.label, "Purchase FrameWink Lifetime")
        XCTAssertTrue(purchase.isHittable)
        XCTAssertTrue(app.buttons["Restore Purchases"].exists)

        purchase.tap()
        let unavailableStatus = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "temporarily unavailable from the App Store")
        ).firstMatch
        XCTAssertTrue(unavailableStatus.waitForExistence(timeout: 4))
    }

    func testFrameSettingsKeepsOnlyDisplayGuidanceAndLocalDataControls() {
        launch(scenario: "wall-mode-setup")

        XCTAssertTrue(app.navigationBars["Frame Settings"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.switches["Night Schedule"].exists)
        let mountedDisplayTips = app.buttons["Mounted Display Tips"]
        if !mountedDisplayTips.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(mountedDisplayTips.waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts["Data & Privacy"].exists)
        XCTAssertFalse(app.staticTexts["Photos"].exists)
        XCTAssertFalse(app.staticTexts["Slideshow"].exists)
        XCTAssertFalse(app.buttons["Refresh Album Now"].exists)
        XCTAssertFalse(app.buttons["Review Photos"].exists)
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

    private func waitForValueContaining(
        _ element: XCUIElement,
        text: String,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS %@", text),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForCount(
        _ query: XCUIElementQuery,
        count: Int,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if query.count == count { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return query.count == count
    }
}
