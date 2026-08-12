import Foundation
import ImageIO
import UIKit

protocol ImportedPhotoStoring {
    var importedPhotosDirectory: URL { get }
    var derivedDataDirectory: URL { get }

    func prepareDirectories() throws
    func loadImportedPhotos() throws -> [ImportedPhoto]
    func saveImportedPhotos(_ photos: [ImportedPhoto]) throws
    func temporaryImageURL() throws -> URL
    func imageURL(filename: String) -> URL
    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws
    func removeImage(filename: String)
    func deleteAllImportedData() throws
}

protocol ImportedPhotoImageLoading {
    func image(for photo: ImportedPhoto) async -> UIImage?
    func thumbnail(for photo: ImportedPhoto, maxPixelDimension: Int) async -> UIImage?
}

final class LocalImportedPhotoStore: ImportedPhotoStoring, ImportedPhotoImageLoading {
    let baseURL: URL
    let importedPhotosDirectory: URL
    let derivedDataDirectory: URL

    private let fileManager: FileManager
    private var manifestURL: URL {
        derivedDataDirectory.appendingPathComponent("import-manifest.json")
    }

    init(baseURL: URL, fileManager: FileManager = .default) {
        self.baseURL = baseURL
        self.fileManager = fileManager
        importedPhotosDirectory = baseURL.appendingPathComponent("ImportedPhotos", isDirectory: true)
        derivedDataDirectory = baseURL.appendingPathComponent("ImportedDerivedData", isDirectory: true)
    }

    static func defaultBaseURL(fileManager: FileManager = .default) throws -> URL {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return applicationSupport.appendingPathComponent("FrameWink", isDirectory: true)
    }

    func prepareDirectories() throws {
        try fileManager.createDirectory(
            at: importedPhotosDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: derivedDataDirectory,
            withIntermediateDirectories: true
        )
    }

    func loadImportedPhotos() throws -> [ImportedPhoto] {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return try rebuildManifestFromImages()
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let decoded = try JSONDecoder().decode([ImportedPhoto].self, from: data)
            let available = decoded.filter {
                fileManager.fileExists(atPath: imageURL(filename: $0.filename).path)
            }
            if available.count != decoded.count {
                try saveImportedPhotos(available)
            }
            return available
        } catch {
            return try rebuildManifestFromImages()
        }
    }

    func saveImportedPhotos(_ photos: [ImportedPhoto]) throws {
        try prepareDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(photos)
        try data.write(to: manifestURL, options: .atomic)
    }

    func temporaryImageURL() throws -> URL {
        try prepareDirectories()
        return importedPhotosDirectory
            .appendingPathComponent(".partial-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
    }

    func imageURL(filename: String) -> URL {
        importedPhotosDirectory.appendingPathComponent(filename)
    }

    func commitTemporaryImage(at temporaryURL: URL, filename: String) throws {
        let destination = imageURL(filename: filename)
        try fileManager.moveItem(at: temporaryURL, to: destination)
    }

    func removeImage(filename: String) {
        try? fileManager.removeItem(at: imageURL(filename: filename))
    }

    func deleteAllImportedData() throws {
        if fileManager.fileExists(atPath: importedPhotosDirectory.path) {
            try fileManager.removeItem(at: importedPhotosDirectory)
        }
        if fileManager.fileExists(atPath: derivedDataDirectory.path) {
            try fileManager.removeItem(at: derivedDataDirectory)
        }
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

    private func rebuildManifestFromImages() throws -> [ImportedPhoto] {
        guard fileManager.fileExists(atPath: importedPhotosDirectory.path) else {
            return []
        }

        let imageURLs = try fileManager.contentsOfDirectory(
            at: importedPhotosDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let recovered = imageURLs.compactMap(Self.recoveredPhoto)
            .sorted { $0.id.uuidString < $1.id.uuidString }
        try saveImportedPhotos(recovered)
        return recovered
    }

    private static func recoveredPhoto(at url: URL) -> ImportedPhoto? {
        guard url.pathExtension.lowercased() == "jpg",
              let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent),
              let source = CGImageSourceCreateWithURL(
                  url as CFURL,
                  [kCGImageSourceShouldCache: false] as CFDictionary
              ),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0,
              height > 0 else {
            return nil
        }

        return ImportedPhoto(
            id: id,
            filename: url.lastPathComponent,
            pixelWidth: width,
            pixelHeight: height,
            importedAt: Date(),
            creationDate: imageCreationDate(from: properties)
        )
    }

    private static func imageCreationDate(from properties: [CFString: Any]) -> Date? {
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        guard let value = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? tiff?[kCGImagePropertyTIFFDateTime] as? String else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: value)
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
