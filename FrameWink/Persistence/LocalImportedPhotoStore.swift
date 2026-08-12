import Foundation
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
        guard fileManager.fileExists(atPath: manifestURL.path) else { return [] }
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode([ImportedPhoto].self, from: data)
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
            UIImage(contentsOfFile: url.path)
        }.value
    }
}
