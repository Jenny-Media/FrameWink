import ImageIO
import XCTest
@testable import FrameWink

final class BundledSampleImageLoaderTests: XCTestCase {
    func testEveryBundledSampleImageLoadsFromTheAppBundle() {
        XCTAssertEqual(BundledSampleCatalog.photos.count, 20)
        XCTAssertEqual(Set(BundledSampleCatalog.photos.map(\.id)).count, 20)
        XCTAssertEqual(Set(BundledSampleCatalog.photos.map(\.resourceName)).count, 20)

        for photo in BundledSampleCatalog.photos {
            let image = BundledSampleImageLoader.image(named: photo.resourceName)
            XCTAssertEqual(
                image?.cgImage?.width,
                photo.pixelSize.width,
                "Unexpected width for \(photo.resourceName)"
            )
            XCTAssertEqual(
                image?.cgImage?.height,
                photo.pixelSize.height,
                "Unexpected height for \(photo.resourceName)"
            )
        }
    }

    func testBundledSamplesContainNoPrivateMetadata() throws {
        let disallowedProperties: [CFString] = [
            kCGImagePropertyExifDictionary,
            kCGImagePropertyExifAuxDictionary,
            kCGImagePropertyGPSDictionary,
            kCGImagePropertyIPTCDictionary,
            kCGImagePropertyTIFFDictionary,
        ]

        for photo in BundledSampleCatalog.photos {
            let url = try XCTUnwrap(
                BundledSampleImageLoader.url(named: photo.resourceName)
            )
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let properties = try XCTUnwrap(
                CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            )
            for key in disallowedProperties {
                XCTAssertNil(
                    properties[key],
                    "\(photo.resourceName) unexpectedly contains \(key) metadata"
                )
            }
            if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
                let tags = CGImageMetadataCopyTags(metadata) as? [Any] ?? []
                XCTAssertTrue(tags.isEmpty, "\(photo.resourceName) contains XMP metadata")
            }
        }
    }

    func testWaterBirdDeclaresItsFullSubjectAsImportant() throws {
        let bird = try XCTUnwrap(
            BundledSampleCatalog.photos.first { $0.id == "sample-water-bird" }
        )
        let subject = try XCTUnwrap(bird.importantRects.first)

        XCTAssertTrue(subject.isWithinUnitBounds)
        XCTAssertGreaterThan(subject.width, 0.9)
        XCTAssertGreaterThan(subject.height, 0.8)
        XCTAssertEqual(bird.slide.importantRects, bird.importantRects)
    }
}
