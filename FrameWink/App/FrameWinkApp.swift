import SwiftUI

@main
struct FrameWinkApp: App {
    @StateObject private var model: AppModel

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
        _model = StateObject(
            wrappedValue: AppModel(
                importer: importer,
                imageLoader: store,
                smartReelBuilder: smartReelBuilder
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .onAppear {
                    model.prepareSmartReelIfNeeded()
                }
        }
    }
}
