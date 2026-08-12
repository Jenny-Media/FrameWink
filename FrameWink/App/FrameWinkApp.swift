import SwiftUI

@main
struct FrameWinkApp: App {
    @StateObject private var model: AppModel
    @StateObject private var wallMode: WallModeController
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
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, wallMode: wallMode)
                .onAppear {
                    model.prepareSmartReelIfNeeded()
                    wallMode.setSceneIsForeground(scenePhase == .active)
                }
                .onChange(of: scenePhase) { phase in
                    wallMode.setSceneIsForeground(phase == .active)
                }
        }
    }
}
