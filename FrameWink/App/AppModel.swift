import SwiftUI
import UIKit

enum PhotoCollectionMode: String, CaseIterable, Identifiable {
    case samples
    case personal

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .samples:
            return "Samples"
        case .personal:
            return "My Photos"
        }
    }
}

enum ImportPhase: Equatable {
    case idle
    case importing(ImportProgress)
    case cancelling(ImportProgress)
    case finished(PhotoImportReport)
    case deletionFailed(String)
}

enum DisplaySlideSource {
    case bundled(resourceName: String)
    case imported(ImportedPhoto)
}

struct DisplaySlide: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    let accessibilityLabel: LocalizedStringKey
    let source: DisplaySlideSource
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var importedPhotos: [ImportedPhoto] = []
    @Published var collectionMode: PhotoCollectionMode = .samples
    @Published private(set) var importPhase: ImportPhase = .idle

    private let importer: PhotoImporting
    private let imageLoader: ImportedPhotoImageLoading
    private var importTask: Task<Void, Never>?
    private var retryItems: [PhotoImportItem] = []

    init(importer: PhotoImporting, imageLoader: ImportedPhotoImageLoading) {
        self.importer = importer
        self.imageLoader = imageLoader
        importedPhotos = (try? importer.loadImportedPhotos()) ?? []
    }

    var slides: [DisplaySlide] {
        if collectionMode == .personal, !importedPhotos.isEmpty {
            return importedPhotos.map { photo in
                DisplaySlide(
                    id: photo.id.uuidString,
                    title: "Your photo",
                    caption: "Stored privately on this iPad",
                    accessibilityLabel: "A photo you imported",
                    source: .imported(photo)
                )
            }
        }

        return Self.sampleSlides
    }

    var canRetryImport: Bool {
        !retryItems.isEmpty
    }

    func importSelectedItems(_ items: [PhotoImportItem]) {
        guard !items.isEmpty else { return }
        startImport(items)
    }

    func cancelImport() {
        guard case .importing(let progress) = importPhase else { return }
        importPhase = .cancelling(progress)
        importTask?.cancel()
    }

    func retryImport() {
        guard !retryItems.isEmpty else { return }
        startImport(retryItems)
    }

    func dismissImportStatus() {
        importPhase = .idle
        retryItems = []
    }

    func deleteImportedPhotos() {
        importTask?.cancel()
        do {
            try importer.deleteAllImportedPhotos()
            importedPhotos = []
            retryItems = []
            collectionMode = .samples
            importPhase = .idle
        } catch {
            importPhase = .deletionFailed(error.localizedDescription)
        }
    }

    func image(for photo: ImportedPhoto) async -> UIImage? {
        await imageLoader.image(for: photo)
    }

    private func startImport(_ items: [PhotoImportItem]) {
        importTask?.cancel()
        retryItems = []
        importPhase = .importing(
            ImportProgress(completedCount: 0, totalCount: min(items.count, 100))
        )

        importTask = Task { [weak self] in
            guard let self = self else { return }
            let report = await importer.importPhotos(
                from: items,
                maxPixelDimension: 2_560
            ) { [weak self] progress in
                guard let self = self else { return }
                if case .cancelling = self.importPhase {
                    self.importPhase = .cancelling(progress)
                } else {
                    self.importPhase = .importing(progress)
                }
            }

            importedPhotos = (try? importer.loadImportedPhotos()) ?? importedPhotos
            if !report.imported.isEmpty {
                collectionMode = .personal
            }

            let retryIDs = Set(report.failures.map(\.sourceID) + report.remainingSourceIDs)
            retryItems = items.filter { retryIDs.contains($0.id) }
            importPhase = .finished(report)
        }
    }

    private static let sampleSlides = [
        DisplaySlide(
            id: "sample-lakeside",
            title: "Keep the good days close",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of two friends picnicking beside a mountain lake",
            source: .bundled(resourceName: "sample-lakeside")
        ),
        DisplaySlide(
            id: "sample-beach-dog",
            title: "Small moments, beautifully framed",
            caption: "Bundled example · stays on this iPad",
            accessibilityLabel: "Sample photo of a golden retriever running in ocean surf",
            source: .bundled(resourceName: "sample-beach-dog")
        ),
        DisplaySlide(
            id: "sample-kitchen",
            title: "A quieter way to remember",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of flowers and peaches on a wooden kitchen table",
            source: .bundled(resourceName: "sample-kitchen")
        ),
    ]
}
