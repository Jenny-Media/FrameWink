import XCTest
@testable import FrameWink

final class FrameViewportRegionsTests: XCTestCase {
    func testUnfoldedPhotoFillsBoundsAndControlsUseEachSafeInset() {
        let regions = FrameViewportRegions(
            size: CGSize(width: 800, height: 550),
            safeArea: CGRect(x: 72, y: 18, width: 700, height: 498),
            divisions: []
        )
        XCTAssertEqual(regions.photo, CGRect(x: 0, y: 0, width: 800, height: 550))
        XCTAssertEqual(regions.controls, CGRect(x: 72, y: 18, width: 700, height: 498))
        XCTAssertFalse(regions.isDivided)
    }

    func testBookFoldKeepsPhotoAndControlsOnSeparateSides() {
        let fold = CGRect(x: 380, y: 0, width: 40, height: 550)
        let regions = FrameViewportRegions(
            size: CGSize(width: 800, height: 550),
            safeArea: CGRect(x: 0, y: 0, width: 738, height: 530),
            divisions: [fold]
        )
        XCTAssertEqual(regions.photo, CGRect(x: 0, y: 0, width: 380, height: 550))
        XCTAssertEqual(regions.controls, CGRect(x: 420, y: 0, width: 318, height: 530))
        XCTAssertFalse(regions.photo.intersects(fold))
        XCTAssertFalse(regions.controls.intersects(fold))
        XCTAssertTrue(regions.isDivided)
    }

    func testTabletopFoldKeepsPhotoAboveAndControlsBelow() {
        let regions = FrameViewportRegions(
            size: CGSize(width: 550, height: 800),
            safeArea: CGRect(x: 12, y: 24, width: 520, height: 750),
            divisions: [CGRect(x: 0, y: 380, width: 550, height: 40)]
        )
        XCTAssertEqual(regions.photo, CGRect(x: 0, y: 0, width: 550, height: 380))
        XCTAssertEqual(regions.controls, CGRect(x: 12, y: 420, width: 520, height: 354))
        XCTAssertTrue(regions.isDivided)
    }

    func testInactiveAndOutsideDivisionsDoNotDisplaceContent() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 550)
        for fold in [CGRect(x: 400, y: 0, width: 0, height: 550),
                     CGRect(x: 900, y: 0, width: 20, height: 550)] {
            let regions = FrameViewportRegions(size: bounds.size, safeArea: bounds, divisions: [fold])
            XCTAssertEqual(regions.photo, bounds)
            XCTAssertFalse(regions.isDivided)
        }
    }

    func testEdgeDivisionDoesNotCollapsePhotoToAnEmptyRegion() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 550)
        let regions = FrameViewportRegions(
            size: bounds.size, safeArea: bounds,
            divisions: [CGRect(x: -10, y: 0, width: 30, height: 550)]
        )
        XCTAssertEqual(regions.photo, bounds)
        XCTAssertFalse(regions.isDivided)
    }

    func testTinyOcclusionLikeRectangleIsNotTreatedAsAFold() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 550)
        let regions = FrameViewportRegions(
            size: bounds.size, safeArea: bounds,
            divisions: [CGRect(x: 350, y: 200, width: 30, height: 30)]
        )
        XCTAssertEqual(regions.photo, bounds)
        XCTAssertFalse(regions.isDivided)
    }
}
