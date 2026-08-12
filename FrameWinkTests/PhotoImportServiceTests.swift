import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FrameWink

final class PhotoImportServiceTests: XCTestCase {
    private var testRoot: URL!
    private var store: LocalImportedPhotoStore!
    private var service: PhotoImportService!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: testRoot, withIntermediateDirectories: true)
        store = LocalImportedPhotoStore(baseURL: testRoot)
        service = PhotoImportService(
            store: store,
            downsampler: ImageIODownsampler(),
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )
    }

    override func tearDownWithError() throws {
        if let testRoot = testRoot {
            try? FileManager.default.removeItem(at: testRoot)
        }
        service = nil
        store = nil
        testRoot = nil
    }

    func testImportDownsamplesAndPersistsDisplaySizedCopy() async throws {
        let sourceURL = testRoot.appendingPathComponent("large-source.jpg")
        try makeJPEG(at: sourceURL, width: 3_200, height: 1_800)

        let report = await service.importPhotos(
            from: [FileImportItem(sourceURL: sourceURL)],
            maxPixelDimension: 800,
            progress: { _ in }
        )

        XCTAssertEqual(report.imported.count, 1)
        XCTAssertTrue(report.failures.isEmpty)
        let photo = try XCTUnwrap(report.imported.first)
        XCTAssertLessThanOrEqual(max(photo.pixelWidth, photo.pixelHeight), 800)

        let outputURL = store.imageURL(filename: photo.filename)
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertLessThanOrEqual(max(image.width, image.height), 800)
        XCTAssertEqual(try store.loadImportedPhotos(), [photo])
    }

    func testPartialFailurePreservesSuccessfulImports() async throws {
        let sourceURL = testRoot.appendingPathComponent("valid.jpg")
        try makeJPEG(at: sourceURL, width: 1_200, height: 900)
        let goodOne = FileImportItem(sourceURL: sourceURL)
        let bad = FailingImportItem()
        let goodTwo = FileImportItem(sourceURL: sourceURL)

        let report = await service.importPhotos(
            from: [goodOne, bad, goodTwo],
            maxPixelDimension: 600,
            progress: { _ in }
        )

        XCTAssertEqual(report.imported.count, 2)
        XCTAssertEqual(report.failures.map(\.sourceID), [bad.id])
        XCTAssertEqual(try store.loadImportedPhotos().count, 2)
        XCTAssertNotEqual(report.imported[0].id, report.imported[1].id)
    }

    func testCancellationLeavesNoOrphanedImportFiles() async throws {
        let sourceURL = testRoot.appendingPathComponent("valid.jpg")
        try makeJPEG(at: sourceURL, width: 800, height: 600)
        let delayed = DelayedImportItem(sourceURL: sourceURL)

        let task = Task {
            await service.importPhotos(
                from: [delayed],
                maxPixelDimension: 600,
                progress: { _ in }
            )
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()
        let report = await task.value

        XCTAssertTrue(report.wasCancelled)
        XCTAssertEqual(report.remainingSourceIDs, [delayed.id])
        XCTAssertTrue(try store.loadImportedPhotos().isEmpty)
        let files = (try? FileManager.default.contentsOfDirectory(
            at: store.importedPhotosDirectory,
            includingPropertiesForKeys: nil
        )) ?? []
        XCTAssertTrue(files.isEmpty)
    }

    func testDeleteAllRemovesImagesManifestAndDerivedRecords() async throws {
        let sourceURL = testRoot.appendingPathComponent("valid.jpg")
        try makeJPEG(at: sourceURL, width: 800, height: 600)
        let report = await service.importPhotos(
            from: [FileImportItem(sourceURL: sourceURL)],
            maxPixelDimension: 600,
            progress: { _ in }
        )
        XCTAssertEqual(report.imported.count, 1)

        try store.prepareDirectories()
        let signals = store.derivedDataDirectory.appendingPathComponent("signals.json")
        let reel = store.derivedDataDirectory.appendingPathComponent("smart-reel.json")
        let exclusions = store.derivedDataDirectory.appendingPathComponent("exclusions.json")
        try Data("{}".utf8).write(to: signals)
        try Data("{}".utf8).write(to: reel)
        try Data("{}".utf8).write(to: exclusions)

        try service.deleteAllImportedPhotos()

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.importedPhotosDirectory.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.derivedDataDirectory.path))
        XCTAssertTrue(try store.loadImportedPhotos().isEmpty)
    }

    private func makeJPEG(at url: URL, width: Int, height: Int) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.18, green: 0.52, blue: 0.72, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.95, green: 0.72, blue: 0.24, alpha: 1))
        context.fillEllipse(in: CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }
}

private struct FileImportItem: PhotoImportItem {
    let id = UUID()
    let sourceURL: URL

    func loadFile() async throws -> LoadedImportFile {
        LoadedImportFile(url: sourceURL, cleanup: {})
    }
}

private struct FailingImportItem: PhotoImportItem {
    let id = UUID()

    func loadFile() async throws -> LoadedImportFile {
        throw TestImportError.expectedFailure
    }
}

private struct DelayedImportItem: PhotoImportItem {
    let id = UUID()
    let sourceURL: URL

    func loadFile() async throws -> LoadedImportFile {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return LoadedImportFile(url: sourceURL, cleanup: {})
    }
}

private enum TestImportError: LocalizedError {
    case expectedFailure

    var errorDescription: String? { "Expected import failure" }
}
