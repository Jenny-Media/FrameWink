import Foundation
import ImageIO

final class PhotoImportService: PhotoImporting {
    private let store: ImportedPhotoStoring
    private let downsampler: ImageDownsampling
    private let now: () -> Date

    init(
        store: ImportedPhotoStoring,
        downsampler: ImageDownsampling,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.downsampler = downsampler
        self.now = now
    }

    func loadImportedPhotos() throws -> [ImportedPhoto] {
        try store.loadImportedPhotos()
    }

    func importPhotos(
        from items: [PhotoImportItem],
        maxPixelDimension: Int = 2_560,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async -> PhotoImportReport {
        let selectedItems = Array(items.prefix(100))
        await progress(ImportProgress(completedCount: 0, totalCount: selectedItems.count))

        let storedPhotos: [ImportedPhoto]
        do {
            storedPhotos = try store.loadImportedPhotos()
        } catch {
            let failures = selectedItems.map {
                PhotoImportFailure(sourceID: $0.id, message: error.localizedDescription)
            }
            return PhotoImportReport(
                imported: [],
                failures: failures,
                remainingSourceIDs: [],
                wasCancelled: false
            )
        }

        var allPhotos = storedPhotos
        var importedPhotos: [ImportedPhoto] = []
        var failures: [PhotoImportFailure] = []
        var remainingSourceIDs: [UUID] = []
        var completedCount = 0
        var wasCancelled = false

        for (index, item) in selectedItems.enumerated() {
            do {
                try Task.checkCancellation()
                let loadedFile = try await item.loadFile()
                defer { loadedFile.cleanup() }

                try Task.checkCancellation()
                let temporaryURL = try store.temporaryImageURL()
                var shouldRemoveTemporaryFile = true
                defer {
                    if shouldRemoveTemporaryFile {
                        try? FileManager.default.removeItem(at: temporaryURL)
                    }
                }

                let size = try downsampler.downsampleImage(
                    at: loadedFile.url,
                    to: temporaryURL,
                    maxPixelDimension: maxPixelDimension
                )
                try Task.checkCancellation()

                let id = UUID()
                let filename = "\(id.uuidString).jpg"
                try store.commitTemporaryImage(at: temporaryURL, filename: filename)
                shouldRemoveTemporaryFile = false

                let photo = ImportedPhoto(
                    id: id,
                    filename: filename,
                    pixelWidth: size.width,
                    pixelHeight: size.height,
                    importedAt: now(),
                    creationDate: imageCreationDate(at: loadedFile.url)
                )
                var updatedPhotos = allPhotos
                updatedPhotos.append(photo)

                do {
                    try store.saveImportedPhotos(updatedPhotos)
                } catch {
                    store.removeImage(filename: filename)
                    throw error
                }

                allPhotos = updatedPhotos
                importedPhotos.append(photo)
            } catch is CancellationError {
                wasCancelled = true
                remainingSourceIDs = selectedItems[index...].map(\.id)
                break
            } catch {
                failures.append(
                    PhotoImportFailure(sourceID: item.id, message: error.localizedDescription)
                )
            }

            completedCount += 1
            await progress(
                ImportProgress(completedCount: completedCount, totalCount: selectedItems.count)
            )
        }

        return PhotoImportReport(
            imported: importedPhotos,
            failures: failures,
            remainingSourceIDs: remainingSourceIDs,
            wasCancelled: wasCancelled
        )
    }

    func deleteAllImportedPhotos() throws {
        try store.deleteAllImportedData()
    }

    private func imageCreationDate(at url: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any] else {
            return nil
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let value = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? tiff?[kCGImagePropertyTIFFDateTime] as? String
        guard let value = value else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: value)
    }
}
