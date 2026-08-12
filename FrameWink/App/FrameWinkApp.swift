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
        _model = StateObject(
            wrappedValue: AppModel(importer: importer, imageLoader: store)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
