import XCTest
@testable import FrameWink

final class BundledSampleImageLoaderTests: XCTestCase {
    func testEveryBundledSampleImageLoadsFromTheAppBundle() {
        let resourceNames = [
            "sample-lakeside",
            "sample-beach-dog",
            "sample-kitchen",
        ]

        for resourceName in resourceNames {
            XCTAssertNotNil(
                BundledSampleImageLoader.image(named: resourceName),
                "Expected bundled sample image \(resourceName).png to decode"
            )
        }
    }
}
