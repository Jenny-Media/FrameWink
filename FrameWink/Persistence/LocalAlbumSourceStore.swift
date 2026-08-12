import Foundation
import ImageIO
import UIKit

protocol AlbumSourceStoring: ImportedPhotoImageLoading {
    func loadConfiguration() -> AutomaticAlbumConfiguration
    func saveConfiguration(_ configuration: AutomaticAlbumConfiguration) throws
    func loadRecords() throws -> [CachedAlbumAsset]
    func replaceRecords(
        _ records: [CachedAlbumAsset],
        removingFilenames: [String]
    ) throws
    func temporaryURL(pathExtension: String) throws -> URL
    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws
    func removeImage(filename: String)
    func deleteAllCachedData() throws
}

final class LocalAlbumSourceStore: AlbumSourceStoring {
    let directory: URL
    let imagesDirectory: URL
    let metadataDirectory: URL
    let configurationURL: URL
    let recordsURL: URL

    private let fileManager: FileManager

    init(baseURL: URL, fileManager: FileManager = .default) {
        directory = baseURL.appendingPathComponent("AutomaticAlbum", isDirectory: true)
        imagesDirectory = directory.appendingPathComponent("Images", isDirectory: true)
        metadataDirectory = directory.appendingPathComponent("Metadata", isDirectory: true)
        configurationURL = metadataDirectory.appendingPathComponent("configuration.json")
        recordsURL = metadataDirectory.appendingPathComponent("records.json")
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
        try prepareDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(configuration).write(to: configurationURL, options: .atomic)
    }

    func loadRecords() throws -> [CachedAlbumAsset] {
        guard fileManager.fileExists(atPath: recordsURL.path) else {
            try removeOrphanedImages(keeping: [])
            return []
        }

        do {
            let decoded = try JSONDecoder().decode(
                [CachedAlbumAsset].self,
                from: Data(contentsOf: recordsURL)
            )
            let available = decoded.filter {
                fileManager.fileExists(atPath: imageURL(filename: $0.photo.filename).path)
            }
            if available.count != decoded.count {
                try replaceRecords(available, removingFilenames: [])
            } else {
                try removeOrphanedImages(keeping: Set(available.map(\.photo.filename)))
            }
            return available
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
        try prepareDirectories()
        let ordered = records.sorted { $0.assetIdentifier < $1.assetIdentifier }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(ordered).write(to: recordsURL, options: .atomic)

        for filename in removingFilenames where !ordered.contains(where: {
            $0.photo.filename == filename
        }) {
            removeImage(filename: filename)
        }
        try removeOrphanedImages(keeping: Set(ordered.map(\.photo.filename)))
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
    }

    private func imageURL(filename: String) -> URL {
        imagesDirectory.appendingPathComponent(filename)
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
