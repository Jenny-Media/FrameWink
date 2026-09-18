import Foundation
import ImageIO
import UIKit

protocol AlbumSourceStoring: ImportedPhotoImageLoading {
    func loadConfiguration() -> AutomaticAlbumConfiguration
    func saveConfiguration(_ configuration: AutomaticAlbumConfiguration) throws
    func loadRecords() throws -> [CachedAlbumAsset]
    func loadRecords(for albumIdentifier: String) throws -> [CachedAlbumAsset]
    func loadReusableRecords() throws -> [CachedAlbumAsset]
    func replaceRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws
    func replaceRecords(
        _ records: [CachedAlbumAsset],
        for albumIdentifier: String,
        removingFilenames: [String]
    ) throws
    func temporaryURL(pathExtension: String) throws -> URL
    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws
    func removeImage(filename: String)
    func containsImage(filename: String) -> Bool
    func cachedImageBytes() -> Int64
    func pruneCachedImages(keepingPhotoIDs: Set<UUID>) throws -> Int64
    func pruneCachedImagesToBudget(keepingPhotoIDs: Set<UUID>, budgetBytes: Int64) throws -> Int64
    func savedReelBelongsToCurrentAlbum() -> Bool
    func markSavedReelForCurrentAlbum() throws
    func deleteAllCachedData() throws
}

extension AlbumSourceStoring {
    func loadRecords(for albumIdentifier: String) throws -> [CachedAlbumAsset] {
        try loadRecords()
    }
    func loadReusableRecords() throws -> [CachedAlbumAsset] { try loadRecords() }
    func replaceRecords(
        _ records: [CachedAlbumAsset],
        for albumIdentifier: String,
        removingFilenames: [String]
    ) throws {
        try replaceRecords(records, removingFilenames: removingFilenames)
    }
    func containsImage(filename: String) -> Bool { true }
    func cachedImageBytes() -> Int64 { 0 }
    func pruneCachedImages(keepingPhotoIDs: Set<UUID>) throws -> Int64 { 0 }
    func pruneCachedImagesToBudget(keepingPhotoIDs: Set<UUID>, budgetBytes: Int64) throws -> Int64 {
        guard cachedImageBytes() > budgetBytes else { return 0 }
        return try pruneCachedImages(keepingPhotoIDs: keepingPhotoIDs)
    }
    func savedReelBelongsToCurrentAlbum() -> Bool { true }
    func markSavedReelForCurrentAlbum() throws {}
}

private struct AlbumCacheEntry: Codable {
    let albumIdentifier: String
    var assetIdentifiers: [String]
}

final class LocalAlbumSourceStore: AlbumSourceStoring {
    let directory: URL
    let imagesDirectory: URL
    let metadataDirectory: URL
    let configurationURL: URL
    let recordsURL: URL
    let recentAlbumsURL: URL
    let savedReelAlbumURL: URL

    private let fileManager: FileManager

    init(baseURL: URL, fileManager: FileManager = .default) {
        directory = baseURL.appendingPathComponent("AutomaticAlbum", isDirectory: true)
        imagesDirectory = directory.appendingPathComponent("Images", isDirectory: true)
        metadataDirectory = directory.appendingPathComponent("Metadata", isDirectory: true)
        configurationURL = metadataDirectory.appendingPathComponent("configuration.json")
        recordsURL = metadataDirectory.appendingPathComponent("records.json")
        recentAlbumsURL = metadataDirectory.appendingPathComponent("recent-albums.json")
        savedReelAlbumURL = metadataDirectory.appendingPathComponent("saved-reel-album.txt")
        self.fileManager = fileManager
    }

    func loadConfiguration() -> AutomaticAlbumConfiguration {
        guard fileManager.fileExists(atPath: configurationURL.path),
              let data = try? Data(contentsOf: configurationURL),
              let configuration = try? JSONDecoder().decode(
                  AutomaticAlbumConfiguration.self,
                  from: data
              ) else {
            return .defaultConfiguration
        }
        return configuration
    }

    func saveConfiguration(_ configuration: AutomaticAlbumConfiguration) throws {
        let previous = loadConfiguration()
        var entries = loadRecentAlbums(legacyConfiguration: previous)
        if let identifier = configuration.albumIdentifier,
           identifier != previous.albumIdentifier {
            if fileManager.fileExists(atPath: metadataDirectory.appendingPathComponent("smart-reel.json").path),
               !fileManager.fileExists(atPath: savedReelAlbumURL.path),
               let oldIdentifier = previous.albumIdentifier {
                try oldIdentifier.write(to: savedReelAlbumURL, atomically: true, encoding: .utf8)
            }
            let previousEntry = entries.first { $0.albumIdentifier == identifier }
            entries.removeAll { $0.albumIdentifier == identifier }
            entries.insert(previousEntry ?? AlbumCacheEntry(
                albumIdentifier: identifier, assetIdentifiers: []
            ), at: 0)
            entries = Array(entries.prefix(PhotoStoragePolicy.recentAlbumLimit))
        }
        try prepareDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if configuration.albumIdentifier != previous.albumIdentifier {
            try writeRecentAlbums(entries)
        }
        try encoder.encode(configuration).write(to: configurationURL, options: .atomic)
    }

    func loadRecords() throws -> [CachedAlbumAsset] {
        let allRecords = try loadReusableRecords()
        guard let identifier = loadConfiguration().albumIdentifier else { return allRecords }
        let entries = loadRecentAlbums(legacyConfiguration: loadConfiguration())
        guard let entry = entries.first(where: { $0.albumIdentifier == identifier }) else {
            return []
        }
        let identifiers = Set(entry.assetIdentifiers)
        return allRecords.filter { identifiers.contains($0.assetIdentifier) }
    }

    func loadRecords(for albumIdentifier: String) throws -> [CachedAlbumAsset] {
        let entries = loadRecentAlbums(legacyConfiguration: loadConfiguration())
        guard let entry = entries.first(where: { $0.albumIdentifier == albumIdentifier }) else {
            return []
        }
        let identifiers = Set(entry.assetIdentifiers)
        return try loadReusableRecords().filter { identifiers.contains($0.assetIdentifier) }
    }

    func loadReusableRecords() throws -> [CachedAlbumAsset] {
        guard fileManager.fileExists(atPath: recordsURL.path) else {
            try removeOrphanedImages(keeping: [])
            return []
        }

        do {
            let decoded = try JSONDecoder().decode(
                [CachedAlbumAsset].self,
                from: Data(contentsOf: recordsURL)
            )
            try removeOrphanedImages(keeping: Set(decoded.map(\.photo.filename)))
            return decoded
        } catch {
            try? fileManager.removeItem(at: recordsURL)
            try removeOrphanedImages(keeping: [])
            return []
        }
    }

    func replaceRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws {
        guard let identifier = loadConfiguration().albumIdentifier else {
            try writeRecords(records, removingFilenames: removingFilenames)
            return
        }
        try replaceRecords(records, for: identifier, removingFilenames: removingFilenames)
    }

    func replaceRecords(
        _ records: [CachedAlbumAsset],
        for albumIdentifier: String,
        removingFilenames: [String]
    ) throws {
        var entries = loadRecentAlbums(legacyConfiguration: loadConfiguration())
        if let index = entries.firstIndex(where: { $0.albumIdentifier == albumIdentifier }) {
            entries[index].assetIdentifiers = records.map(\.assetIdentifier)
        } else {
            entries.append(AlbumCacheEntry(
                albumIdentifier: albumIdentifier,
                assetIdentifiers: records.map(\.assetIdentifier)
            ))
        }
        entries = Array(entries.prefix(PhotoStoragePolicy.recentAlbumLimit))
        let retainedIDs = Set(entries.flatMap(\.assetIdentifiers))
        // Newly downloaded files are not in records.json yet. Reading through
        // loadReusableRecords() here would mistake them for orphans.
        let previous = (try? JSONDecoder().decode(
            [CachedAlbumAsset].self, from: Data(contentsOf: recordsURL)
        )) ?? []
        var byAsset = Dictionary(uniqueKeysWithValues: previous.map {
            ($0.assetIdentifier, $0)
        })
        for record in records { byAsset[record.assetIdentifier] = record }
        let retained = byAsset.values.filter { retainedIDs.contains($0.assetIdentifier) }
        try writeRecords(retained, removingFilenames: removingFilenames)
        try writeRecentAlbums(entries)
    }

    private func writeRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws {
        try prepareDirectories()
        let ordered = records.sorted { $0.assetIdentifier < $1.assetIdentifier }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(ordered).write(to: recordsURL, options: .atomic)

        let retainedFilenames = Set(ordered.map(\.photo.filename))
        for filename in removingFilenames where !retainedFilenames.contains(filename) {
            removeImage(filename: filename)
        }
        // The atomic metadata write above is the commit point. Cleanup after
        // that point is deliberately best-effort: reporting a failure would
        // make the synchronizer roll back newly committed images even though
        // the durable records already reference them. A later load retries
        // orphan cleanup safely.
        try? removeOrphanedImages(keeping: retainedFilenames)
    }

    func savedReelBelongsToCurrentAlbum() -> Bool {
        guard let current = loadConfiguration().albumIdentifier,
              let saved = try? String(contentsOf: savedReelAlbumURL, encoding: .utf8) else {
            return true // Existing single-album installations have no marker.
        }
        return saved == current
    }

    func markSavedReelForCurrentAlbum() throws {
        guard let current = loadConfiguration().albumIdentifier else { return }
        try prepareDirectories()
        try current.write(to: savedReelAlbumURL, atomically: true, encoding: .utf8)
    }

    func temporaryURL(pathExtension: String) throws -> URL {
        try prepareDirectories()
        return imagesDirectory
            .appendingPathComponent(".partial-" + UUID().uuidString)
            .appendingPathExtension(pathExtension)
    }

    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws {
        try fileManager.moveItem(at: temporaryURL, to: imageURL(filename: filename))
    }

    func removeImage(filename: String) {
        try? fileManager.removeItem(at: imageURL(filename: filename))
    }

    func containsImage(filename: String) -> Bool {
        fileManager.fileExists(atPath: imageURL(filename: filename).path)
    }

    func cachedImageBytes() -> Int64 {
        LocalStorageUsage.bytes(in: imagesDirectory, fileManager: fileManager)
    }

    func pruneCachedImages(keepingPhotoIDs: Set<UUID>) throws -> Int64 {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return 0 }
        let records = try JSONDecoder().decode(
            [CachedAlbumAsset].self,
            from: Data(contentsOf: recordsURL)
        )
        var removedBytes: Int64 = 0
        for record in records where !keepingPhotoIDs.contains(record.photo.id) {
            let url = imageURL(filename: record.photo.filename)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let values = try url.resourceValues(forKeys: [
                .totalFileAllocatedSizeKey,
                .fileSizeKey
            ])
            try fileManager.removeItem(at: url)
            removedBytes += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        }
        return removedBytes
    }

    func pruneCachedImagesToBudget(
        keepingPhotoIDs: Set<UUID>,
        budgetBytes: Int64
    ) throws -> Int64 {
        var excess = cachedImageBytes() - budgetBytes
        guard excess > 0 else { return 0 }
        let records = try loadReusableRecords()
        let entries = loadRecentAlbums(legacyConfiguration: loadConfiguration())
        var rankByAsset: [String: Int] = [:]
        for (rank, entry) in entries.enumerated() {
            for identifier in entry.assetIdentifiers where rankByAsset[identifier] == nil {
                rankByAsset[identifier] = rank
            }
        }
        let candidates = records.filter { !keepingPhotoIDs.contains($0.photo.id) }
            .sorted { lhs, rhs in
                let leftRank = rankByAsset[lhs.assetIdentifier] ?? Int.max
                let rightRank = rankByAsset[rhs.assetIdentifier] ?? Int.max
                return leftRank == rightRank
                    ? lhs.assetIdentifier < rhs.assetIdentifier : leftRank > rightRank
            }
        var removed: Int64 = 0
        for record in candidates where excess > 0 {
            let url = imageURL(filename: record.photo.filename)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let values = try url.resourceValues(forKeys: [
                .totalFileAllocatedSizeKey, .fileSizeKey
            ])
            let bytes = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            try fileManager.removeItem(at: url)
            removed += bytes
            excess -= bytes
        }
        return removed
    }

    func deleteAllCachedData() throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        let url = imageURL(filename: photo.filename)
        return await Task.detached(priority: .userInitiated) {
            Self.decodedImage(at: url)
        }.value
    }

    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int) async -> UIImage? {
        let url = imageURL(filename: photo.filename)
        let boundedDimension = min(max(maxPixelDimension, 64), 2_048)
        return await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(
                url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary
            ) else {
                return nil
            }
            let options = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: boundedDimension,
            ] as CFDictionary
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
                return nil
            }
            return UIImage(cgImage: image)
        }.value
    }

    private func prepareDirectories() throws {
        try fileManager.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: metadataDirectory,
            withIntermediateDirectories: true
        )
        try LocalStoragePrivacy.excludeFromBackup(
            directory,
            fileManager: fileManager
        )
    }

    private func imageURL(filename: String) -> URL {
        imagesDirectory.appendingPathComponent(filename)
    }

    private func loadRecentAlbums(
        legacyConfiguration: AutomaticAlbumConfiguration
    ) -> [AlbumCacheEntry] {
        if fileManager.fileExists(atPath: recentAlbumsURL.path) {
            guard let data = try? Data(contentsOf: recentAlbumsURL),
                  let entries = try? JSONDecoder().decode([AlbumCacheEntry].self, from: data) else {
                return [] // Do not assign other albums' records to the chosen album.
            }
            return entries
        }
        guard let identifier = legacyConfiguration.albumIdentifier,
              let data = try? Data(contentsOf: recordsURL),
              let records = try? JSONDecoder().decode([CachedAlbumAsset].self, from: data) else {
            return []
        }
        return [AlbumCacheEntry(
            albumIdentifier: identifier,
            assetIdentifiers: records.map(\.assetIdentifier)
        )]
    }

    private func writeRecentAlbums(_ entries: [AlbumCacheEntry]) throws {
        try prepareDirectories()
        try JSONEncoder().encode(entries).write(to: recentAlbumsURL, options: .atomic)
    }

    private func removeOrphanedImages(keeping filenames: Set<String>) throws {
        guard fileManager.fileExists(atPath: imagesDirectory.path) else { return }
        let files = try fileManager.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil,
            options: []
        )
        for file in files where !filenames.contains(file.lastPathComponent) {
            try? fileManager.removeItem(at: file)
        }
    }

    private static func decodedImage(at url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ),
              let image = CGImageSourceCreateImageAtIndex(
                  source,
                  0,
                  [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
              ) else {
            return nil
        }
        return UIImage(cgImage: image)
    }
}
