import Foundation
import XCTest
@testable import FrameWink

final class LocalStorageUsageTests: XCTestCase {
    func testAlbumBudgetUsesSharedHeadroomWithoutOscillatingAsCacheChanges() {
        let gib: Int64 = 1_024 * 1_024 * 1_024
        let cached = PhotoStoragePolicy.constrainedAlbumImageBudgetBytes

        XCTAssertEqual(
            PhotoStoragePolicy.automaticAlbumBudget(
                availableStorageBytes: 3 * gib - cached,
                cachedImageBytes: cached
            ),
            gib
        )
        XCTAssertEqual(
            PhotoStoragePolicy.automaticAlbumBudget(
                availableStorageBytes: 3 * gib - cached - 1,
                cachedImageBytes: cached
            ),
            cached
        )
        XCTAssertEqual(
            PhotoStoragePolicy.automaticAlbumBudget(
                availableStorageBytes: 2 * gib,
                cachedImageBytes: gib
            ),
            PhotoStoragePolicy.automaticAlbumBudget(
                availableStorageBytes: 2 * gib + cached,
                cachedImageBytes: cached
            )
        )
        XCTAssertEqual(
            PhotoStoragePolicy.automaticAlbumBudget(
                availableStorageBytes: nil,
                cachedImageBytes: 0
            ),
            cached
        )
    }

    func testMeasurementSeparatesImportedAlbumAndWorkingFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkStorageUsage-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("App")
        let temporary = root.appendingPathComponent("Temporary")
        try writeFile(in: app.appendingPathComponent("ImportedPhotos"), name: "one.jpg")
        try writeFile(in: app.appendingPathComponent("ImportedDerivedData"), name: "signals.json")
        try writeFile(in: app.appendingPathComponent("AutomaticAlbum/Images"), name: "two.jpg")
        try writeFile(in: temporary.appendingPathComponent("FrameWinkPickerStaging"), name: "staged.jpg")

        let usage = LocalStorageUsage.measure(baseURL: app, temporaryDirectory: temporary)

        XCTAssertGreaterThan(usage.importedBytes, 0)
        XCTAssertGreaterThan(usage.albumBytes, 0)
        XCTAssertGreaterThan(usage.temporaryBytes, 0)
        XCTAssertEqual(
            usage.totalBytes,
            usage.importedBytes + usage.albumBytes + usage.temporaryBytes
        )
    }

    func testMaintenanceOnlyRemovesOldWorkingFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkWorkingFiles-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("App")
        let temporary = root.appendingPathComponent("Temporary")
        let imported = app.appendingPathComponent("ImportedPhotos")
        let staged = temporary.appendingPathComponent("FrameWinkPickerStaging")
        let oldStaged = try writeFile(in: staged, name: "old.heic")
        let freshStaged = try writeFile(in: staged, name: "fresh.heic")
        let oldPartial = try writeFile(in: imported, name: ".partial-old.jpg")
        let keptPhoto = try writeFile(in: imported, name: "selected.jpg")
        let old = Date(timeIntervalSince1970: 100)
        for url in [oldStaged, oldPartial, keptPhoto] {
            try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: url.path)
        }

        LocalStorageUsage.removeAbandonedWorkingFiles(
            baseURL: app,
            temporaryDirectory: temporary,
            olderThan: Date(timeIntervalSince1970: 200)
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldStaged.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldPartial.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: freshStaged.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: keptPhoto.path))
    }

    func testFullCleanupRemovesPickerWorkingFilesWithoutTouchingImportedPhotos() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkFullWorkingCleanup-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let imported = try writeFile(
            in: root.appendingPathComponent("ImportedPhotos"),
            name: "selected.jpg"
        )
        let staged = try writeFile(
            in: root.appendingPathComponent("FrameWinkPickerStaging"),
            name: "staged.heic"
        )

        try LocalStorageUsage.removeAllWorkingFiles(temporaryDirectory: root)

        XCTAssertFalse(FileManager.default.fileExists(atPath: staged.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: imported.path))
    }

    @discardableResult
    private func writeFile(in directory: URL, name: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data(repeating: 3, count: 128).write(to: url)
        return url
    }
}
