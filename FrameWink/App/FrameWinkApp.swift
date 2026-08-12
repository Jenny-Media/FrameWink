import SwiftUI

@main
struct FrameWinkApp: App {
    @StateObject private var model: AppModel
    @StateObject private var wallMode: WallModeController
    @StateObject private var purchases: PurchaseController
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
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, wallMode: wallMode, purchases: purchases)
                .onAppear {
                    model.prepareSmartReelIfNeeded()
                    purchases.start()
                    wallMode.setEntitled(purchases.isWallModeUnlocked)
                    wallMode.setSceneIsForeground(scenePhase == .active)
                }
                .onChange(of: purchases.entitlement) { _ in
                    wallMode.setEntitled(purchases.isWallModeUnlocked)
                }
                .onChange(of: scenePhase) { phase in
                    wallMode.setSceneIsForeground(phase == .active)
                }
        }
    }
}
