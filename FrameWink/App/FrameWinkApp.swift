import SwiftUI

@main
struct FrameWinkApp: App {
    @StateObject private var model: AppModel
    @StateObject private var wallMode: WallModeController
    @StateObject private var purchases: PurchaseController
    @StateObject private var automaticAlbum: AutomaticAlbumController
    @StateObject private var frameConfigurations: FrameConfigurationController
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let fileManager = FileManager.default
#if DEBUG
        let screenshotScenario = DebugScreenshotScenario.current
        let physicalAcceptanceMode = DebugPhysicalAcceptanceMode.isEnabled
#endif
        let baseURL: URL
#if DEBUG
        if screenshotScenario != nil {
            baseURL = fileManager.temporaryDirectory
                .appendingPathComponent("FrameWinkScreenshotState", isDirectory: true)
            try? fileManager.removeItem(at: baseURL)
        } else {
            baseURL = (try? LocalImportedPhotoStore.defaultBaseURL(fileManager: fileManager))
                ?? fileManager.temporaryDirectory.appendingPathComponent("FrameWink", isDirectory: true)
        }
#else
        baseURL = (try? LocalImportedPhotoStore.defaultBaseURL(fileManager: fileManager))
            ?? fileManager.temporaryDirectory.appendingPathComponent("FrameWink", isDirectory: true)
#endif
        let store = LocalImportedPhotoStore(baseURL: baseURL, fileManager: fileManager)
        let importer = PhotoImportService(
            store: store,
            downsampler: ImageIODownsampler()
        )
        let curationStore = LocalCurationStore(directory: store.derivedDataDirectory)
        let smartReelBuilder: SmartReelBuilding
#if DEBUG
        if screenshotScenario == .freeReview
            || screenshotScenario == .personalReel
            || screenshotScenario == .sourceIntegrity {
            smartReelBuilder = DebugScreenshotSmartReelBuilder(
                savedCandidateIDs: DebugScreenshotScenario.importedPhotoFixtureIDs
            )
        } else {
            smartReelBuilder = SmartReelPipeline(
                analyzer: VisionPhotoAnalyzer(),
                curator: SmartReelCurator(),
                store: curationStore
            )
        }
#else
        smartReelBuilder = SmartReelPipeline(
            analyzer: VisionPhotoAnalyzer(),
            curator: SmartReelCurator(),
            store: curationStore
        )
#endif
        let wallModeStore = LocalWallModeStore(
            directory: baseURL.appendingPathComponent("Settings", isDirectory: true)
        )
        let frameConfigurationStore = LocalFrameConfigurationStore(
            directory: baseURL.appendingPathComponent("Settings", isDirectory: true)
        )
        let photoLibraryClient: PhotoLibraryClient
#if DEBUG
        if screenshotScenario?.requiresWallModeEntitlement == true {
            photoLibraryClient = DebugScreenshotPhotoLibraryClient()
        } else {
            photoLibraryClient = PhotoKitLibraryClient()
        }
#else
        photoLibraryClient = PhotoKitLibraryClient()
#endif
        let albumStore = LocalAlbumSourceStore(baseURL: baseURL, fileManager: fileManager)
#if DEBUG
        screenshotScenario?.seed(
            importedStore: store,
            wallModeStore: wallModeStore,
            albumStore: albumStore,
            frameConfigurationStore: frameConfigurationStore
        )
#endif
        let purchaseClient: PurchaseClient
#if DEBUG
        if let screenshotScenario {
            purchaseClient = DebugScreenshotPurchaseClient(
                isEntitled: screenshotScenario.requiresWallModeEntitlement
            )
        } else if physicalAcceptanceMode {
            purchaseClient = DebugScreenshotPurchaseClient(isEntitled: true)
        } else {
            purchaseClient = StoreKitPurchaseClient(
                productID: ProductConfiguration.wallModeProductID()
            )
        }
#else
        purchaseClient = StoreKitPurchaseClient(
            productID: ProductConfiguration.wallModeProductID()
        )
#endif
        let albumSynchronizer = AlbumSyncService(
            client: photoLibraryClient,
            store: albumStore,
            downsampler: ImageIODownsampler()
        )
        let albumCurationStore = LocalCurationStore(directory: albumStore.metadataDirectory)
        let automaticAlbumSmartReelBuilder: SmartReelBuilding
#if DEBUG
        if screenshotScenario?.requiresWallModeEntitlement == true {
            automaticAlbumSmartReelBuilder = DebugScreenshotSmartReelBuilder()
        } else {
            automaticAlbumSmartReelBuilder = SmartReelPipeline(
                analyzer: VisionPhotoAnalyzer(),
                curator: SmartReelCurator(),
                store: albumCurationStore
            )
        }
#else
        automaticAlbumSmartReelBuilder = SmartReelPipeline(
            analyzer: VisionPhotoAnalyzer(),
            curator: SmartReelCurator(),
            store: albumCurationStore
        )
#endif
        let appModel = AppModel(
            importer: importer,
            imageLoader: store,
            smartReelBuilder: smartReelBuilder
        )
#if DEBUG
        if screenshotScenario == .personalReel {
            appModel.collectionMode = .personal
        } else if screenshotScenario == .personalImport {
            appModel.debugBeginInitialPersonalImport()
        }
#endif
        _model = StateObject(wrappedValue: appModel)
        _wallMode = StateObject(
            wrappedValue: WallModeController(
                idleTimer: ApplicationIdleTimerController(),
                store: wallModeStore
            )
        )
        _purchases = StateObject(
            wrappedValue: PurchaseController(
                client: purchaseClient
            )
        )
        _automaticAlbum = StateObject(
            wrappedValue: AutomaticAlbumController(
                client: photoLibraryClient,
                store: albumStore,
                synchronizer: albumSynchronizer,
                smartReelBuilder: automaticAlbumSmartReelBuilder,
                displayHistoryStore: albumCurationStore
            )
        )
        _frameConfigurations = StateObject(
            wrappedValue: FrameConfigurationController(
                store: frameConfigurationStore
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                model: model,
                wallMode: wallMode,
                purchases: purchases,
                automaticAlbum: automaticAlbum,
                frameConfigurations: frameConfigurations,
                initialPresentation: initialPresentation
            )
                .onAppear {
#if DEBUG
                    PhysicalAcceptanceRecorder.shared.start()
#endif
                    model.prepareSmartReelIfNeeded()
                    if shouldStartPurchases {
                        purchases.start()
                    }
                    wallMode.setEntitled(purchases.isWallModeUnlocked)
                    automaticAlbum.setEntitled(purchases.isWallModeUnlocked)
                    frameConfigurations.setEntitled(purchases.isWallModeUnlocked)
                    wallMode.setSceneIsForeground(scenePhase == .active)
                }
                .onChange(of: purchases.entitlement) { _ in
                    wallMode.setEntitled(purchases.isWallModeUnlocked)
                    automaticAlbum.setEntitled(purchases.isWallModeUnlocked)
                    frameConfigurations.setEntitled(purchases.isWallModeUnlocked)
                }
                .onChange(of: scenePhase) { phase in
                    wallMode.setSceneIsForeground(phase == .active)
#if DEBUG
                    PhysicalAcceptanceRecorder.shared.recordStateChange()
#endif
                    if phase == .active {
                        automaticAlbum.refreshAuthorizationAfterForegrounding()
                    }
                }
        }
    }

    private var initialPresentation: RootInitialPresentation? {
#if DEBUG
        return DebugScreenshotScenario.current?.initialPresentation
#else
        return nil
#endif
    }

    private var shouldStartPurchases: Bool {
#if DEBUG
        // Hosted unit tests configure StoreKitTest after the app process starts.
        // Avoid opening the production StoreKit connection before their local
        // SKTestSession has a chance to install its configuration.
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
#else
        return true
#endif
    }
}
