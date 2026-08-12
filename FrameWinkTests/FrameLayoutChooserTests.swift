import XCTest
@testable import FrameWink

final class FrameLayoutChooserTests: XCTestCase {
    private let chooser = FrameLayoutChooser()
    private let landscapeViewport = PixelSize(width: 1_366, height: 1_024)

    func testFitKeepsTheWholeLandscapePhoto() throws {
        let item = fixture(id: "landscape", width: 1_500, height: 1_000)
        let page = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fit).first
        )

        XCTAssertEqual(page.kind, .singleFit)
        XCTAssertEqual(page.placements.first?.sourceCrop, .unit)
        XCTAssertEqual(page.placements.first?.contentMode, .fit)
    }

    func testFillProducesAValidCenteredCropForPanorama() throws {
        let item = fixture(id: "panorama", width: 4_000, height: 1_000)
        let placement = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first
        )

        XCTAssertEqual(placement.contentMode, .crop)
        XCTAssertTrue(placement.sourceCrop.isWithinUnitBounds)
        XCTAssertLessThan(placement.sourceCrop.width, 1)
        XCTAssertEqual(placement.sourceCrop.midX, 0.5, accuracy: 0.000_001)
    }

    func testSquarePhotoFillUsesAValidCenteredVerticalCrop() throws {
        let item = fixture(id: "square", width: 1_200, height: 1_200)
        let crop = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first?.sourceCrop
        )

        XCTAssertTrue(crop.isWithinUnitBounds)
        XCTAssertEqual(crop.width, 1, accuracy: 0.000_001)
        XCTAssertLessThan(crop.height, 1)
        XCTAssertEqual(crop.midY, 0.5, accuracy: 0.000_001)
    }

    func testFillMovesCropToProtectAnEdgePositionedFace() throws {
        let face = NormalizedRect(x: 0.88, y: 0.30, width: 0.10, height: 0.22)
        let item = fixture(
            id: "right-edge-face",
            width: 4_000,
            height: 1_000,
            importantRects: [face]
        )
        let crop = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first?.sourceCrop
        )

        XCTAssertGreaterThanOrEqual(crop.maxX, face.maxX)
        XCTAssertLessThanOrEqual(crop.minX, face.minX)
    }

    func testUnsafeMultiFaceFillFallsBackToFit() throws {
        let item = fixture(
            id: "wide-faces",
            width: 4_000,
            height: 1_000,
            importantRects: [
                NormalizedRect(x: 0.02, y: 0.2, width: 0.12, height: 0.2),
                NormalizedRect(x: 0.86, y: 0.2, width: 0.12, height: 0.2),
            ]
        )
        let page = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill).first
        )

        XCTAssertEqual(page.kind, .singleFit)
        XCTAssertEqual(page.placements.first?.sourceCrop, .unit)
    }

    func testAutomaticPairsCompatiblePortraitsWithoutOverlap() throws {
        let first = fixture(
            id: "portrait-a",
            width: 1_000,
            height: 1_500,
            importantRects: [NormalizedRect(x: 0.3, y: 0.1, width: 0.3, height: 0.25)]
        )
        let second = fixture(
            id: "portrait-b",
            width: 1_000,
            height: 1_500,
            importantRects: [NormalizedRect(x: 0.4, y: 0.2, width: 0.3, height: 0.25)]
        )
        let page = try XCTUnwrap(
            chooser.pages(
                for: [first, second],
                viewport: landscapeViewport,
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.kind, .pairedPortraits)
        XCTAssertEqual(page.placements.count, 2)
        XCTAssertEqual(page.placements[0].screenFrame.maxX, page.placements[1].screenFrame.minX)
        XCTAssertTrue(page.placements.allSatisfy { $0.sourceCrop.isWithinUnitBounds })
    }

    func testRotationReflowsPortraitPairIntoSinglePages() {
        let items = [
            fixture(id: "portrait-a", width: 1_000, height: 1_500),
            fixture(id: "portrait-b", width: 1_000, height: 1_500),
        ]

        let landscapePages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .automatic
        )
        let portraitPages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 1_024, height: 1_366),
            preference: .automatic
        )

        XCTAssertEqual(landscapePages.count, 1)
        XCTAssertEqual(landscapePages.first?.kind, .pairedPortraits)
        XCTAssertEqual(portraitPages.count, 2)
        XCTAssertTrue(portraitPages.allSatisfy { $0.kind != .pairedPortraits })
    }

    private func fixture(
        id: String,
        width: Int,
        height: Int,
        importantRects: [NormalizedRect] = []
    ) -> FrameLayoutItem {
        FrameLayoutItem(
            id: id,
            pixelSize: PixelSize(width: width, height: height),
            importantRects: importantRects
        )
    }
}
