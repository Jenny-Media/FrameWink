import Foundation
import PhotosUI
import UniformTypeIdentifiers

private final class CancellableProgressBox: @unchecked Sendable {
    private let lock = NSLock()
    private var progress: Progress?
    private var cancelled = false

    func set(_ progress: Progress) {
        lock.lock()
        self.progress = progress
        let shouldCancel = cancelled
        lock.unlock()

        if shouldCancel {
            progress.cancel()
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let progress = progress
        lock.unlock()
        progress?.cancel()
    }

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }
}

final class PHPickerImportItem: PhotoImportItem {
    let id = UUID()

    private let itemProvider: NSItemProvider

    init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
    }

    func loadFile() async throws -> LoadedImportFile {
        let progressBox = CancellableProgressBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let progress = itemProvider.loadFileRepresentation(
                    forTypeIdentifier: UTType.image.identifier
                ) { url, error in
                    let fileManager = FileManager.default
                    if let error = error {
                        continuation.resume(
                            throwing: progressBox.isCancelled ? CancellationError() : error
                        )
                        return
                    }

                    guard let sourceURL = url else {
                        continuation.resume(throwing: ImageDownsampleError.unreadableSource)
                        return
                    }

                    let stagingDirectory = fileManager.temporaryDirectory
                        .appendingPathComponent("FrameWinkPickerStaging", isDirectory: true)
                    let extensionName = sourceURL.pathExtension.isEmpty
                        ? "image"
                        : sourceURL.pathExtension
                    let stagedURL = stagingDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(extensionName)

                    do {
                        try fileManager.createDirectory(
                            at: stagingDirectory,
                            withIntermediateDirectories: true
                        )
                        try fileManager.copyItem(at: sourceURL, to: stagedURL)

                        if progressBox.isCancelled {
                            try? fileManager.removeItem(at: stagedURL)
                            continuation.resume(throwing: CancellationError())
                            return
                        }

                        continuation.resume(
                            returning: LoadedImportFile(
                                url: stagedURL,
                                cleanup: { try? fileManager.removeItem(at: stagedURL) }
                            )
                        )
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                progressBox.set(progress)
            }
        } onCancel: {
            progressBox.cancel()
        }
    }
}
