import XCTest
@testable import FrameWink

final class FrameContentSelectorTests: XCTestCase {
    func testAutomaticAlbumPreparationNeverFallsBackToSampleSlides() {
        let sample = DisplaySlide(
            id: "sample",
            title: "Sample",
            caption: "Sample",
            accessibilityLabel: "Sample",
            source: .bundled(resourceName: "sample-city-skyline")
        )

        let slides = FrameContentSelector.slides(
            for: .automaticAlbum,
            standardSlides: [sample],
            automaticAlbumSlides: []
        )

        XCTAssertTrue(slides.isEmpty)
    }

    func testNonAutomaticSourcesKeepTheirOwnSlides() {
        let sample = DisplaySlide(
            id: "sample",
            title: "Sample",
            caption: "Sample",
            accessibilityLabel: "Sample",
            source: .bundled(resourceName: "sample-city-skyline")
        )

        XCTAssertEqual(
            FrameContentSelector.slides(
                for: .samples,
                standardSlides: [sample],
                automaticAlbumSlides: []
            ).map(\.id),
            ["sample"]
        )
    }

    func testPreparationBackdropNeverCoversFrameModeControls() {
        XCTAssertTrue(
            FramePreparationPresentation.showsBackdrop(
                hasSlides: false,
                isPreparing: true,
                isFrameMode: false
            )
        )
        XCTAssertFalse(
            FramePreparationPresentation.showsBackdrop(
                hasSlides: false,
                isPreparing: true,
                isFrameMode: true
            )
        )
    }

    func testInitialPersonalImportSuppressesSamplesAndShowsPreparation() {
        let progress = ImportProgress(completedCount: 0, totalCount: 3)
        let isPreparing = FramePreparationPresentation.isInitialPersonalImport(
            phase: .importing(progress),
            importedPhotoCount: 0
        )
        let sample = DisplaySlide(
            id: "sample",
            title: "Sample",
            caption: "Sample",
            accessibilityLabel: "Sample",
            source: .bundled(resourceName: "sample-city-skyline")
        )

        XCTAssertTrue(isPreparing)
        XCTAssertTrue(
            FrameContentSelector.slides(
                for: .samples,
                standardSlides: [sample],
                automaticAlbumSlides: [],
                isInitialPersonalImport: isPreparing
            ).isEmpty
        )
        XCTAssertTrue(
            FramePreparationPresentation.showsBackdrop(
                hasSlides: false,
                isPreparing: isPreparing,
                isFrameMode: false
            )
        )
        XCTAssertFalse(
            FramePreparationPresentation.isInitialPersonalImport(
                phase: .importing(progress),
                importedPhotoCount: 1
            )
        )
    }
}
