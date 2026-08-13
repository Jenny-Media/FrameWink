import CoreGraphics
import Foundation
import ImageIO
import Photos
import UniformTypeIdentifiers
import XCTest
@testable import FrameWink

@MainActor
final class AlbumSyncServiceTests: XCTestCase {
    private var testRoot: URL!
    private var store: LocalAlbumSourceStore!
    private var client: FixturePhotoLibraryClient!
    private var service: AlbumSyncService!

    override func setUpWithError() throws {
        testRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrameWinkAlbumSyncTests-" + UUID().uuidString)
        store = LocalAlbumSourceStore(baseURL: testRoot)
        client = FixturePhotoLibraryClient()
        service = AlbumSyncService(
            client: client,
            store: store,
            downsampler: ImageIODownsampler(),
            now: { Date(timeIntervalSince1970: 2_000) },
            makeID: UUID.init
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testRoot)
        service = nil
        client = nil
        store = nil
        testRoot = nil
    }

    func testSyncFiltersUnsafeAssetsAndSkipsCloudOnlyInStrictOffline() async throws {
        client.fixtureAssets = [
            asset("local"),
            asset("cloud"),
            asset("hidden", isHidden: true),
            asset("screenshot", isScreenshot: true),
        ]
        client.cloudOnlyAssetIDs = ["cloud"]
        var progress: [ImportProgress] = []

        let report = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: true,
            progress: { progress.append($0) }
        )

        XCTAssertEqual(report.records.map(\.assetIdentifier), ["local"])
        XCTAssertEqual(report.importedCount, 1)
        XCTAssertEqual(report.cloudOnlyCount, 1)
        XCTAssertTrue(report.failures.isEmpty)
        XCTAssertEqual(progress.last, ImportProgress(completedCount: 2, totalCount: 2))
        XCTAssertEqual(client.requestedNetworkAccess, ["cloud": false, "local": false])
    }

    func testPhotoKitNetworkRequiredErrorIsClassifiedAsCloudOnlyOffline() {
        let networkRequired = NSError(
            domain: PHPhotosErrorDomain,
            code: PHPhotosError.networkAccessRequired.rawValue
        )

        let failure = PhotoKitLibraryClient.exportFailure(
            error: networkRequired,
            isInCloud: false,
            networkAccessAllowed: false
        )

        XCTAssertEqual(failure as? PhotoLibraryClientError, .cloudAssetUnavailable)
    }

    func testPhotoKitNetworkErrorRemainsVisibleWhenDownloadsAreAllowed() {
        let networkError = NSError(
            domain: PHPhotosErrorDomain,
            code: PHPhotosError.networkError.rawValue
        )

        let failure = PhotoKitLibraryClient.exportFailure(
            error: networkError,
            isInCloud: true,
            networkAccessAllowed: true
        ) as NSError?

        XCTAssertEqual(failure?.domain, PHPhotosErrorDomain)
        XCTAssertEqual(failure?.code, PHPhotosError.networkError.rawValue)
    }

    func testUnchangedAssetIsReusedAndModifiedAssetReplacesFileWithStableID() async throws {
        client.fixtureAssets = [
            asset("one", modification: 10, burstIdentifier: "burst-one")
        ]
        let first = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )
        let original = try XCTUnwrap(first.records.first)
        XCTAssertEqual(original.burstIdentifier, "burst-one")
        XCTAssertEqual(original.candidate().burstIdentifier, "burst-one")
        let originalRevision = try XCTUnwrap(original.candidate().contentRevision)
        let originalURL = store.imagesDirectory.appendingPathComponent(
            original.photo.filename
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))

        client.exportCount = 0
        let unchanged = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )
        XCTAssertEqual(client.exportCount, 0)
        XCTAssertEqual(unchanged.records, first.records)

        client.fixtureAssets = [asset("one", modification: 20)]
        let refreshed = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )
        let replacement = try XCTUnwrap(refreshed.records.first)
        XCTAssertEqual(replacement.photo.id, original.photo.id)
        XCTAssertNotEqual(replacement.photo.filename, original.photo.filename)
        XCTAssertEqual(refreshed.refreshedCount, 1)
        XCTAssertNotEqual(replacement.candidate().contentRevision, originalRevision)
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
    }

    func testRemovingAlbumAssetDeletesOnlyItsCachedCopy() async throws {
        client.fixtureAssets = [asset("one"), asset("two")]
        let first = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )
        let removed = try XCTUnwrap(first.records.first { $0.assetIdentifier == "one" })
        let kept = try XCTUnwrap(first.records.first { $0.assetIdentifier == "two" })

        client.fixtureAssets = [asset("two")]
        let second = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )

        XCTAssertEqual(second.removedCount, 1)
        XCTAssertEqual(second.records.map(\.assetIdentifier), ["two"])
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: store.imagesDirectory.appendingPathComponent(
                removed.photo.filename
            ).path
        ))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: store.imagesDirectory.appendingPathComponent(
                kept.photo.filename
            ).path
        ))
    }

    func testModifiedCloudOnlyAssetKeepsItsLastUsableLocalCopy() async throws {
        client.fixtureAssets = [asset("one", modification: 10)]
        let first = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: true,
            progress: { _ in }
        )
        let original = try XCTUnwrap(first.records.first)
        let originalURL = store.imagesDirectory.appendingPathComponent(
            original.photo.filename
        )

        client.fixtureAssets = [asset("one", modification: 20)]
        client.cloudOnlyAssetIDs = ["one"]
        let second = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: true,
            progress: { _ in }
        )

        XCTAssertEqual(second.records, [original])
        XCTAssertEqual(second.refreshedCount, 0)
        XCTAssertEqual(second.cloudOnlyCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))
    }

    func testLargeSyncPrioritizesARepresentativeBatchAndPersistsCheckpoints() async throws {
        client.fixtureAssets = (0..<65).map { index in
            asset(String(format: "asset-%03d", index))
        }
        var checkpointRecordCounts: [Int] = []
        var preparedRecordCounts: [Int] = []
        var durableRecordCounts: [Int] = []

        let report = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in },
            checkpoint: { checkpoint in
                checkpointRecordCounts.append(checkpoint.records.count)
                preparedRecordCounts.append(checkpoint.preparedRecords.count)
                durableRecordCounts.append((try? self.store.loadRecords().count) ?? -1)
            }
        )

        XCTAssertEqual(checkpointRecordCounts, [30, 60])
        XCTAssertEqual(preparedRecordCounts, [30, 60])
        XCTAssertEqual(durableRecordCounts, [30, 60])
        XCTAssertEqual(report.records.count, 65)
        XCTAssertEqual(try store.loadRecords().count, 65)
        XCTAssertEqual(client.requestedAssetIDs.first, "asset-000")
        XCTAssertEqual(client.requestedAssetIDs[29], "asset-064")
        XCTAssertEqual(Set(client.requestedAssetIDs).count, 65)

        var reusedCheckpointCounts: [(durable: Int, prepared: Int)] = []
        client.requestedAssetIDs = []
        _ = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in },
            checkpoint: { checkpoint in
                reusedCheckpointCounts.append(
                    (checkpoint.records.count, checkpoint.preparedRecords.count)
                )
            }
        )

        XCTAssertEqual(reusedCheckpointCounts.map { $0.durable }, [65, 65])
        XCTAssertEqual(reusedCheckpointCounts.map { $0.prepared }, [30, 60])
        XCTAssertTrue(client.requestedAssetIDs.isEmpty)
    }

    func testMetadataWriteFailureRollsBackNewImagesAndPreservesPriorCache() async throws {
        client.fixtureAssets = [asset("one")]
        let first = try await service.synchronize(
            albumIdentifier: "album",
            strictOffline: false,
            progress: { _ in }
        )
        let original = try XCTUnwrap(first.records.first)
        let faultingStore = FaultingAlbumSourceStore(store: store)
        let faultingService = AlbumSyncService(
            client: client,
            store: faultingStore,
            downsampler: ImageIODownsampler(),
            now: { Date(timeIntervalSince1970: 3_000) },
            makeID: UUID.init
        )
        client.fixtureAssets = [asset("one"), asset("two")]

        do {
            _ = try await faultingService.synchronize(
                albumIdentifier: "album",
                strictOffline: false,
                progress: { _ in }
            )
            XCTFail("Expected metadata persistence to fail")
        } catch FaultingAlbumStoreError.expectedFailure {
            XCTAssertTrue(true)
        }

        let imageFilenames = try FileManager.default.contentsOfDirectory(
            atPath: store.imagesDirectory.path
        ).filter { !$0.hasPrefix(".partial-") }
        XCTAssertEqual(imageFilenames, [original.photo.filename])
        XCTAssertEqual(try store.loadRecords(), first.records)
    }

    private func asset(
        _ id: String,
        modification: TimeInterval = 10,
        isHidden: Bool = false,
        isScreenshot: Bool = false,
        burstIdentifier: String? = nil
    ) -> PhotoLibraryAsset {
        PhotoLibraryAsset(
            id: id,
            pixelWidth: 1_200,
            pixelHeight: 800,
            creationDate: Date(timeIntervalSince1970: 1_000),
            modificationDate: Date(timeIntervalSince1970: modification),
            isHidden: isHidden,
            isScreenshot: isScreenshot,
            burstIdentifier: burstIdentifier
        )
    }
}

private enum FaultingAlbumStoreError: LocalizedError {
    case expectedFailure

    var errorDescription: String? { "Expected album metadata write failure" }
}

private final class FaultingAlbumSourceStore: AlbumSourceStoring {
    let store: LocalAlbumSourceStore

    init(store: LocalAlbumSourceStore) {
        self.store = store
    }

    func loadConfiguration() -> AutomaticAlbumConfiguration {
        store.loadConfiguration()
    }

    func saveConfiguration(_ configuration: AutomaticAlbumConfiguration) throws {
        try store.saveConfiguration(configuration)
    }

    func loadRecords() throws -> [CachedAlbumAsset] {
        try store.loadRecords()
    }

    func replaceRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws {
        throw FaultingAlbumStoreError.expectedFailure
    }

    func temporaryURL(pathExtension: String) throws -> URL {
        try store.temporaryURL(pathExtension: pathExtension)
    }

    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws {
        try store.commitTemporaryImage(at: temporaryURL, filename: filename)
    }

    func removeImage(filename: String) {
        store.removeImage(filename: filename)
    }

    func deleteAllCachedData() throws {
        try store.deleteAllCachedData()
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        await store.image(for: photo)
    }

    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int) async -> UIImage? {
        await store.thumbnail(for: photo, maxPixelDimension: maxPixelDimension)
    }
}

@MainActor
private final class FixturePhotoLibraryClient: PhotoLibraryClient {
    var fixtureAssets: [PhotoLibraryAsset] = []
    var cloudOnlyAssetIDs: Set<String> = []
    var requestedNetworkAccess: [String: Bool] = [:]
    var requestedAssetIDs: [String] = []
    var exportCount = 0

    func authorizationState() -> PhotoLibraryAuthorizationState { .authorized }
    func requestAuthorization() async -> PhotoLibraryAuthorizationState { .authorized }
    func albums() async throws -> [PhotoLibraryAlbum] { [] }
    func assets(in albumIdentifier: String) async throws -> [PhotoLibraryAsset] {
        fixtureAssets
    }

    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws {
        requestedNetworkAccess[assetIdentifier] = networkAccessAllowed
        requestedAssetIDs.append(assetIdentifier)
        exportCount += 1
        if cloudOnlyAssetIDs.contains(assetIdentifier), !networkAccessAllowed {
            throw PhotoLibraryClientError.cloudAssetUnavailable
        }
        try fixtureJPEGData().write(to: destinationURL, options: .atomic)
    }

    func changeEvents() -> AsyncStream<Void> {
        AsyncStream { _ in }
    }

    private func fixtureJPEGData() throws -> Data {
        let data = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: 120,
                height: 80,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        CGImageDestinationAddImage(destination, try XCTUnwrap(context.makeImage()), nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
