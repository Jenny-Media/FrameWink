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
        let baseURL = (try? LocalImportedPhotoStore.defaultBaseURL(fileManager: fileManager))
            ?? fileManager.temporaryDirectory.appendingPathComponent("FrameWink", isDirectory: true)
        let store = LocalImportedPhotoStore(baseURL: baseURL, fileManager: fileManager)
        let importer = PhotoImportService(
            store: store,
            downsampler: ImageIODownsampler()
        )
        let curationStore = LocalCurationStore(directory: store.derivedDataDirectory)
        let smartReelBuilder = SmartReelPipeline(
            analyzer: VisionPhotoAnalyzer(),
            curator: SmartReelCurator(),
            store: curationStore
        )
        let wallModeStore = LocalWallModeStore(
            directory: baseURL.appendingPathComponent("Settings", isDirectory: true)
        )
        let frameConfigurationStore = LocalFrameConfigurationStore(
            directory: baseURL.appendingPathComponent("Settings", isDirectory: true)
        )
        let photoLibraryClient = PhotoKitLibraryClient()
        let albumStore = LocalAlbumSourceStore(baseURL: baseURL, fileManager: fileManager)
        let albumSynchronizer = AlbumSyncService(
            client: photoLibraryClient,
            store: albumStore,
            downsampler: ImageIODownsampler()
        )
        let albumCurationStore = LocalCurationStore(directory: albumStore.metadataDirectory)
        _model = StateObject(
            wrappedValue: AppModel(
                importer: importer,
                imageLoader: store,
                smartReelBuilder: smartReelBuilder
            )
        )
        _wallMode = StateObject(
            wrappedValue: WallModeController(
                idleTimer: ApplicationIdleTimerController(),
                store: wallModeStore
            )
        )
        _purchases = StateObject(
            wrappedValue: PurchaseController(
                client: StoreKitPurchaseClient(
                    productID: ProductConfiguration.wallModeProductID()
                )
            )
        )
        _automaticAlbum = StateObject(
            wrappedValue: AutomaticAlbumController(
                client: photoLibraryClient,
                store: albumStore,
                synchronizer: albumSynchronizer,
                smartReelBuilder: SmartReelPipeline(
                    analyzer: VisionPhotoAnalyzer(),
                    curator: SmartReelCurator(),
                    store: albumCurationStore
                ),
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
                frameConfigurations: frameConfigurations
            )
                .onAppear {
                    model.prepareSmartReelIfNeeded()
                    purchases.start()
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
                    if phase == .active {
                        automaticAlbum.refreshAuthorizationAfterForegrounding()
                    }
                }
        }
    }
}
