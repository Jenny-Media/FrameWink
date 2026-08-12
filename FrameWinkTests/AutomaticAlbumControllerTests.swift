import UIKit
import XCTest
@testable import FrameWink

@MainActor
final class AutomaticAlbumControllerTests: XCTestCase {
    func testPhotoAuthorizationIsRequestedOnlyAfterExplicitAlbumAction() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .notDetermined)
        client.albumsValue = [PhotoLibraryAlbum(id: "family", title: "Family", photoCount: 12)]
        let store = ControllerAlbumStore()
        let controller = makeController(client: client, store: store)

        controller.setEntitled(true)
        XCTAssertEqual(client.authorizationRequestCount, 0)
        XCTAssertTrue(controller.albums.isEmpty)

        controller.requestAccessAndLoadAlbums()
        try await waitUntil { controller.albums.count == 1 }

        XCTAssertEqual(client.authorizationRequestCount, 1)
        XCTAssertEqual(controller.authorization, .authorized)
    }

    func testLimitedAuthorizationLoadsVisibleAlbumsAndPermitsConfiguredDisplay() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .limited)
        client.albumsValue = [
            PhotoLibraryAlbum(id: "visible", title: "Visible Album", photoCount: 2)
        ]
        let store = ControllerAlbumStore()
        let controller = makeController(client: client, store: store)

        controller.setEntitled(true)
        controller.requestAccessAndLoadAlbums()
        try await waitUntil { controller.albums.count == 1 }
        controller.selectAlbum(client.albumsValue[0])
        try await waitUntil { controller.canDisplay }

        XCTAssertEqual(client.authorizationRequestCount, 0)
        XCTAssertEqual(controller.authorization, .limited)
        XCTAssertEqual(controller.selectedAlbumTitle, "Visible Album")
        XCTAssertTrue(controller.canDisplay)
    }

    func testDeniedAuthorizationLeavesAutomaticSourceUnavailableAndRecoverable() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .notDetermined)
        client.authorizationAfterRequest = .denied
        client.albumsValue = [
            PhotoLibraryAlbum(id: "hidden", title: "Hidden Album", photoCount: 2)
        ]
        let controller = makeController(client: client, store: ControllerAlbumStore())

        controller.setEntitled(true)
        controller.requestAccessAndLoadAlbums()
        try await waitUntil { controller.phase == .accessDenied }

        XCTAssertEqual(client.authorizationRequestCount, 1)
        XCTAssertEqual(controller.authorization, .denied)
        XCTAssertTrue(controller.albums.isEmpty)
        XCTAssertFalse(controller.canDisplay)
    }

    func testAlbumLoadingFailureLeavesRecoverableErrorState() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        client.albumsError = ControllerPhotoLibraryError.expectedFailure
        let controller = makeController(client: client, store: ControllerAlbumStore())

        controller.setEntitled(true)
        controller.requestAccessAndLoadAlbums()
        try await waitUntil {
            controller.phase == .failed("Albums could not be loaded.")
        }

        XCTAssertTrue(controller.albums.isEmpty)
        client.albumsError = nil
        client.albumsValue = [
            PhotoLibraryAlbum(id: "family", title: "Family", photoCount: nil)
        ]
        controller.requestAccessAndLoadAlbums()
        try await waitUntil { controller.albums.count == 1 }
        XCTAssertEqual(controller.phase, .idle)
    }

    func testSelectedAlbumSyncsCuratesAndRefreshesAfterLibraryChange() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        client.albumsValue = [PhotoLibraryAlbum(id: "family", title: "Family", photoCount: 2)]
        let store = ControllerAlbumStore()
        let synchronizer = ControllerAlbumSynchronizer()
        let builder = ControllerSmartReelBuilder()
        let controller = AutomaticAlbumController(
            client: client,
            store: store,
            synchronizer: synchronizer,
            smartReelBuilder: builder,
            changeRefreshDelayNanoseconds: 10_000_000
        )

        controller.setEntitled(true)
        controller.requestAccessAndLoadAlbums()
        try await waitUntil { controller.albums.count == 1 }
        controller.selectAlbum(client.albumsValue[0])
        try await waitUntil {
            if case .ready = controller.phase { return true }
            return false
        }

        XCTAssertEqual(synchronizer.syncCount, 1)
        XCTAssertEqual(synchronizer.lastStrictOffline, true)
        XCTAssertEqual(controller.reviewPhotos.count, 2)
        XCTAssertEqual(controller.slides.count, 2)
        XCTAssertTrue(controller.canDisplay)

        controller.selectAlbum(
            PhotoLibraryAlbum(id: "travel", title: "Travel", photoCount: 2)
        )
        XCTAssertNil(controller.smartReel)
        XCTAssertFalse(controller.canDisplay)
        try await waitUntil {
            if case .ready = controller.phase { return true }
            return false
        }
        XCTAssertEqual(synchronizer.lastAlbumIdentifier, "travel")

        client.sendChange()
        try await waitUntil { synchronizer.syncCount == 3 }
    }

    func testNeverShowPersistsAsHardVetoAndRevocationHidesPaidSource() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        let store = ControllerAlbumStore()
        store.configuration.albumIdentifier = "family"
        store.configuration.albumTitle = "Family"
        let synchronizer = ControllerAlbumSynchronizer()
        let builder = ControllerSmartReelBuilder()
        let controller = AutomaticAlbumController(
            client: client,
            store: store,
            synchronizer: synchronizer,
            smartReelBuilder: builder,
            changeRefreshDelayNanoseconds: 1
        )
        controller.setEntitled(true)
        try await waitUntil { controller.smartReel != nil }
        let excluded = try XCTUnwrap(controller.smartReel?.selections.first?.candidateID)

        controller.neverShow(candidateID: excluded)

        XCTAssertEqual(builder.exclusions, [excluded])
        XCTAssertFalse(controller.smartReel?.selections.contains {
            $0.candidateID == excluded
        } ?? true)
        client.authorization = .denied
        controller.refreshAuthorizationAfterForegrounding()
        XCTAssertEqual(controller.authorization, .denied)
        XCTAssertEqual(controller.phase, .accessDenied)
        XCTAssertFalse(controller.canDisplay)
        XCTAssertFalse(controller.records.isEmpty)

        client.authorization = .authorized
        controller.refreshAuthorizationAfterForegrounding()
        try await waitUntil {
            if case .ready = controller.phase { return true }
            return false
        }
        XCTAssertTrue(controller.canDisplay)

        controller.setEntitled(false)
        XCTAssertFalse(controller.canDisplay)
    }

    func testResetNeverShowPreservesCachedPhotosAndRefreshesSuggestions() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        let store = ControllerAlbumStore()
        store.configuration.albumIdentifier = "family"
        store.configuration.albumTitle = "Family"
        let synchronizer = ControllerAlbumSynchronizer()
        let builder = ControllerSmartReelBuilder()
        let controller = AutomaticAlbumController(
            client: client,
            store: store,
            synchronizer: synchronizer,
            smartReelBuilder: builder,
            changeRefreshDelayNanoseconds: 1
        )
        controller.setEntitled(true)
        try await waitUntil { controller.smartReel != nil }
        let cachedBeforeReset = controller.records
        builder.exclusions = [try XCTUnwrap(controller.smartReel?.selections.first?.candidateID)]

        controller.resetNeverShowChoices()
        try await waitUntil { builder.resetExclusionsCount == 1 && synchronizer.syncCount == 2 }
        try await waitUntil {
            if case .ready = controller.phase { return true }
            return false
        }

        XCTAssertEqual(builder.exclusions, [])
        XCTAssertEqual(controller.records.map(\.photo.id), cachedBeforeReset.map(\.photo.id))
        XCTAssertTrue(controller.canDisplay)
    }

    func testAlbumSelectionWriteFailurePreservesActiveConfigurationAndReel() async throws {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        let store = ControllerAlbumStore()
        store.configuration.albumIdentifier = "family"
        store.configuration.albumTitle = "Family"
        let synchronizer = ControllerAlbumSynchronizer()
        let controller = AutomaticAlbumController(
            client: client,
            store: store,
            synchronizer: synchronizer,
            smartReelBuilder: ControllerSmartReelBuilder(),
            changeRefreshDelayNanoseconds: 1
        )
        controller.setEntitled(true)
        try await waitUntil { controller.canDisplay }
        let priorSelections = try XCTUnwrap(controller.smartReel?.selections)
        store.configurationSaveError = ControllerStoreError.expectedFailure

        controller.selectAlbum(
            PhotoLibraryAlbum(id: "travel", title: "Travel", photoCount: 2)
        )

        XCTAssertEqual(controller.configuration.albumIdentifier, "family")
        XCTAssertEqual(controller.selectedAlbumTitle, "Family")
        XCTAssertEqual(controller.smartReel?.selections, priorSelections)
        XCTAssertTrue(controller.canDisplay)
        XCTAssertEqual(synchronizer.syncCount, 1)
        XCTAssertEqual(controller.phase, .failed("Expected configuration write failure"))
    }

    func testSettingWriteFailureKeepsLastPersistedAutomaticAlbumOptions() {
        let client = ControllerPhotoLibraryClient(authorization: .authorized)
        let store = ControllerAlbumStore()
        let controller = makeController(client: client, store: store)
        store.configurationSaveError = ControllerStoreError.expectedFailure

        controller.setAutomaticRefresh(false)
        controller.setStrictOffline(false)

        XCTAssertTrue(controller.configuration.automaticRefresh)
        XCTAssertTrue(controller.configuration.strictOffline)
        XCTAssertEqual(controller.configuration, store.configuration)
        XCTAssertEqual(controller.phase, .failed("Expected configuration write failure"))
    }

    private func makeController(
        client: ControllerPhotoLibraryClient,
        store: ControllerAlbumStore
    ) -> AutomaticAlbumController {
        AutomaticAlbumController(
            client: client,
            store: store,
            synchronizer: ControllerAlbumSynchronizer(),
            smartReelBuilder: ControllerSmartReelBuilder(),
            changeRefreshDelayNanoseconds: 1
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "Timed out waiting for controller state")
    }
}

@MainActor
private final class ControllerPhotoLibraryClient: PhotoLibraryClient {
    var authorization: PhotoLibraryAuthorizationState
    var authorizationAfterRequest: PhotoLibraryAuthorizationState = .authorized
    var authorizationRequestCount = 0
    var albumsValue: [PhotoLibraryAlbum] = []
    var albumsError: Error?
    private var changeContinuation: AsyncStream<Void>.Continuation?

    init(authorization: PhotoLibraryAuthorizationState) {
        self.authorization = authorization
    }

    func authorizationState() -> PhotoLibraryAuthorizationState { authorization }

    func requestAuthorization() async -> PhotoLibraryAuthorizationState {
        authorizationRequestCount += 1
        authorization = authorizationAfterRequest
        return authorization
    }

    func albums() async throws -> [PhotoLibraryAlbum] {
        if let albumsError = albumsError { throw albumsError }
        return albumsValue
    }
    func assets(in albumIdentifier: String) async throws -> [PhotoLibraryAsset] { [] }

    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws {}

    func changeEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            changeContinuation = continuation
        }
    }

    func sendChange() {
        changeContinuation?.yield(())
    }
}

private enum ControllerStoreError: LocalizedError {
    case expectedFailure

    var errorDescription: String? { "Expected configuration write failure" }
}

private enum ControllerPhotoLibraryError: LocalizedError {
    case expectedFailure

    var errorDescription: String? { "Albums could not be loaded." }
}

private final class ControllerAlbumStore: AlbumSourceStoring {
    var configuration = AutomaticAlbumConfiguration.defaultConfiguration
    var records: [CachedAlbumAsset] = []
    var configurationSaveError: Error?

    func loadConfiguration() -> AutomaticAlbumConfiguration { configuration }
    func saveConfiguration(_ configuration: AutomaticAlbumConfiguration) throws {
        if let configurationSaveError = configurationSaveError {
            throw configurationSaveError
        }
        self.configuration = configuration
    }
    func loadRecords() throws -> [CachedAlbumAsset] { records }
    func replaceRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws {
        self.records = records
    }
    func temporaryURL(pathExtension: String) throws -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(pathExtension)
    }
    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws {}
    func removeImage(filename: String) {}
    func deleteAllCachedData() throws {
        configuration = .defaultConfiguration
        records = []
    }
    func image(for photo: ImportedPhoto) async -> UIImage? { UIImage() }
    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int) async -> UIImage? {
        UIImage()
    }
}

private final class ControllerAlbumSynchronizer: AlbumSynchronizing {
    var syncCount = 0
    var lastAlbumIdentifier: String?
    var lastStrictOffline: Bool?

    func synchronize(
        albumIdentifier: String,
        strictOffline: Bool,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> AlbumSyncReport {
        syncCount += 1
        lastAlbumIdentifier = albumIdentifier
        lastStrictOffline = strictOffline
        await progress(ImportProgress(completedCount: 0, totalCount: 2))
        let records = [0, 1].map { index in
            let id = UUID(uuidString: index == 0
                ? "00000000-0000-0000-0000-000000000001"
                : "00000000-0000-0000-0000-000000000002")!
            return CachedAlbumAsset(
                assetIdentifier: "asset-\(index)",
                assetModificationDate: Date(timeIntervalSince1970: 100),
                photo: ImportedPhoto(
                    id: id,
                    filename: id.uuidString + ".jpg",
                    pixelWidth: 1_200,
                    pixelHeight: 800,
                    importedAt: Date(timeIntervalSince1970: 100)
                )
            )
        }
        await progress(ImportProgress(completedCount: 2, totalCount: 2))
        return AlbumSyncReport(
            records: records,
            importedCount: 2,
            refreshedCount: 0,
            removedCount: 0,
            cloudOnlyCount: 0,
            failures: []
        )
    }
}

private final class ControllerSmartReelBuilder: SmartReelBuilding {
    var savedReel: SmartReel?
    var exclusions: Set<UUID> = []
    var resetExclusionsCount = 0

    func loadSavedReel() throws -> SmartReel? { savedReel }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await buildUnbounded(
            candidates: candidates,
            maximumSelectionCount: 30,
            imageProvider: imageProvider,
            progress: progress
        )
    }

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        await progress(
            ImportProgress(completedCount: candidates.count, totalCount: candidates.count)
        )
        let reel = SmartReel(
            id: UUID(),
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(timeIntervalSince1970: 100),
            selections: candidates.prefix(maximumSelectionCount).map {
                CuratedPhoto(
                    candidateID: $0.id,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 0.8,
                    reasons: [.quality]
                )
            }
        )
        savedReel = reel
        return reel
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        exclusions.insert(candidateID)
        let updated = SmartReel(
            id: reel.id,
            algorithmRevision: reel.algorithmRevision,
            createdAt: reel.createdAt,
            selections: reel.selections.filter { $0.candidateID != candidateID }
        )
        savedReel = updated
        return updated
    }

    func resetExclusions() throws {
        exclusions = []
        resetExclusionsCount += 1
    }
}
