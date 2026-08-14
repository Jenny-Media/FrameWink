import Foundation

struct LoadedImportFile {
    let url: URL
    let cleanup: () -> Void
}

protocol PhotoImportItem {
    var id: UUID { get }
    func loadFile() async throws -> LoadedImportFile
}

protocol PhotoImporting {
    func loadImportedPhotos() throws -> [ImportedPhoto]

    func importPhotos(
        from items: [PhotoImportItem],
        maxPixelDimension: Int,
        progress: @escaping @MainActor (ImportProgress) -> Void,
        checkpoint: @escaping @MainActor ([ImportedPhoto]) -> Void
    ) async -> PhotoImportReport

    func deleteAllImportedPhotos() throws
}

protocol ImageDownsampling {
    func downsampleImage(
        at sourceURL: URL,
        to destinationURL: URL,
        maxPixelDimension: Int
    ) throws -> PixelSize
}
