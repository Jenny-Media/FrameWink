import ImageIO
import UIKit
import XCTest
@testable import FrameWink

final class LocalImportedPhotoStoreTests: XCTestCase {
    private var testRoot: URL!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkImportedStoreTests-" + UUID().uuidString)
    }

    override func tearDownWithError() throws {
        if let testRoot = testRoot {
            try? FileManager.default.removeItem(at: testRoot)
        }
    }

    func testCorruptManifestRebuildsFromValidImportedJPEG() throws {
        let store = LocalImportedPhotoStore(baseURL: testRoot)
        try store.prepareDirectories()
        let id = UUID()
        let filename = id.uuidString + ".jpg"
        try jpegData(width: 120, height: 80).write(
            to: store.imageURL(filename: filename),
            options: .atomic
        )
        try Data("not-json".utf8).write(
            to: store.derivedDataDirectory.appendingPathComponent("import-manifest.json"),
            options: .atomic
        )

        let recovered = try store.loadImportedPhotos()

        XCTAssertEqual(recovered.map(\.id), [id])
        XCTAssertEqual(recovered.first?.pixelWidth, 120)
        XCTAssertEqual(recovered.first?.pixelHeight, 80)
        XCTAssertEqual(try store.loadImportedPhotos(), recovered)
    }

    func testMissingImportedFileIsRemovedFromManifest() throws {
        let store = LocalImportedPhotoStore(baseURL: testRoot)
        let missing = ImportedPhoto(
            id: UUID(),
            filename: "missing.jpg",
            pixelWidth: 100,
            pixelHeight: 100,
            importedAt: Date(timeIntervalSince1970: 100)
        )
        try store.saveImportedPhotos([missing])

        XCTAssertEqual(try store.loadImportedPhotos(), [])
        XCTAssertEqual(try store.loadImportedPhotos(), [])
    }

    func testReviewThumbnailIsDecodedAtBoundedSize() async throws {
        let store = LocalImportedPhotoStore(baseURL: testRoot)
        try store.prepareDirectories()
        let photo = ImportedPhoto(
            id: UUID(),
            filename: "thumbnail.jpg",
            pixelWidth: 1_200,
            pixelHeight: 800,
            importedAt: Date(timeIntervalSince1970: 100)
        )
        try jpegData(width: 1_200, height: 800).write(
            to: store.imageURL(filename: photo.filename),
            options: .atomic
        )

        let thumbnail = await store.thumbnail(for: photo, maxPixelDimension: 160)
        let cgImage = try XCTUnwrap(thumbnail?.cgImage)

        XCTAssertLessThanOrEqual(max(cgImage.width, cgImage.height), 160)
    }

    func testPhotoAndDerivedDirectoriesAreExcludedFromBackup() throws {
        let store = LocalImportedPhotoStore(baseURL: testRoot)
        try store.prepareDirectories()

        let photoValues = try store.importedPhotosDirectory.resourceValues(
            forKeys: [.isExcludedFromBackupKey]
        )
        let derivedValues = try store.derivedDataDirectory.resourceValues(
            forKeys: [.isExcludedFromBackupKey]
        )

        XCTAssertEqual(photoValues.isExcludedFromBackup, true)
        XCTAssertEqual(derivedValues.isExcludedFromBackup, true)
    }

    private func jpegData(width: Int, height: Int) throws -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
    }
}
