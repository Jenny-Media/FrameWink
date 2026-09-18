import Foundation

struct LocalStorageUsage: Equatable {
    let importedBytes: Int64
    let albumBytes: Int64
    let temporaryBytes: Int64

    var totalBytes: Int64 {
        importedBytes + albumBytes + temporaryBytes
    }

    static func measure(
        baseURL: URL,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        fileManager: FileManager = .default
    ) -> LocalStorageUsage {
        let imported = bytes(
            in: baseURL.appendingPathComponent("ImportedPhotos", isDirectory: true),
            fileManager: fileManager
        ) + bytes(
            in: baseURL.appendingPathComponent("ImportedDerivedData", isDirectory: true),
            fileManager: fileManager
        )
        let album = bytes(
            in: baseURL.appendingPathComponent("AutomaticAlbum", isDirectory: true),
            fileManager: fileManager
        )
        let temporary = bytes(
            in: temporaryDirectory.appendingPathComponent(
                "FrameWinkPickerStaging",
                isDirectory: true
            ),
            fileManager: fileManager
        )
        return LocalStorageUsage(
            importedBytes: imported,
            albumBytes: album,
            temporaryBytes: temporary
        )
    }

    static func formatted(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func systemAvailableStorageBytes() -> Int64? {
        let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        )
        return (attributes?[.systemFreeSize] as? NSNumber)?.int64Value
    }

    static func removeAbandonedWorkingFiles(
        baseURL: URL,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        olderThan cutoff: Date = Date().addingTimeInterval(-24 * 60 * 60),
        fileManager: FileManager = .default
    ) {
        removeOldFiles(
            in: temporaryDirectory.appendingPathComponent(
                "FrameWinkPickerStaging",
                isDirectory: true
            ),
            olderThan: cutoff,
            fileManager: fileManager,
            shouldRemove: { _ in true }
        )
        removeOldFiles(
            in: baseURL.appendingPathComponent("ImportedPhotos", isDirectory: true),
            olderThan: cutoff,
            fileManager: fileManager,
            shouldRemove: { $0.lastPathComponent.hasPrefix(".partial-") }
        )
    }

    static func removeAllWorkingFiles(
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        fileManager: FileManager = .default
    ) throws {
        let stagingDirectory = temporaryDirectory.appendingPathComponent(
            "FrameWinkPickerStaging",
            isDirectory: true
        )
        guard fileManager.fileExists(atPath: stagingDirectory.path) else { return }
        try fileManager.removeItem(at: stagingDirectory)
    }

    private static func removeOldFiles(
        in directory: URL,
        olderThan cutoff: Date,
        fileManager: FileManager,
        shouldRemove: (URL) -> Bool
    ) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: []
        ) else { return }
        for file in files where shouldRemove(file) {
            guard let values = try? file.resourceValues(
                forKeys: [.isRegularFileKey, .contentModificationDateKey]
            ), values.isRegularFile == true,
                let modifiedAt = values.contentModificationDate,
                modifiedAt < cutoff else { continue }
            try? fileManager.removeItem(at: file)
        }
    }

    static func bytes(in directory: URL, fileManager: FileManager = .default) -> Int64 {
        guard let files = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey],
            options: [],
            errorHandler: { _, _ in true }
        ) else { return 0 }

        var total: Int64 = 0
        for case let file as URL in files {
            guard let values = try? file.resourceValues(forKeys: [
                .isRegularFileKey,
                .totalFileAllocatedSizeKey,
                .fileSizeKey
            ]), values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        }
        return total
    }
}
