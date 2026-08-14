import Foundation

enum ManualPhotoCollectionPolicy {
    static let maximumCandidateCount = 500
    static let initialPlayableCandidateCount = 10
    static let maximumReelSelectionCount = 100
    static let minimumFreeStorageBytes: Int64 = 512 * 1_024 * 1_024

    private static let refinementCandidateCounts = [10, 30, 100, 250, 500]

    static func remainingCapacity(after importedPhotoCount: Int) -> Int {
        max(maximumCandidateCount - max(importedPhotoCount, 0), 0)
    }

    static func shouldPublishCheckpoint(
        previousCount: Int,
        currentCount: Int,
        isFinal: Bool
    ) -> Bool {
        guard currentCount > previousCount else { return false }
        if isFinal { return true }
        return refinementCandidateCounts.contains { threshold in
            previousCount < threshold && currentCount >= threshold
        }
    }

    static func curationCandidateCount(for availableCount: Int) -> Int? {
        guard availableCount >= initialPlayableCandidateCount else { return nil }
        return refinementCandidateCounts.last { $0 <= availableCount }
            ?? initialPlayableCandidateCount
    }
}

enum PhotoSource: String, Codable {
    case bundledSample
    case pickerImport
    case photoLibraryAlbum
}

struct PhotoCandidate: Identifiable, Codable, Equatable {
    let id: UUID
    let source: PhotoSource
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?
    let isHidden: Bool
    let isScreenshot: Bool
    let burstIdentifier: String?
    let contentRevision: String?

    init(
        id: UUID,
        source: PhotoSource,
        pixelWidth: Int,
        pixelHeight: Int,
        creationDate: Date?,
        isHidden: Bool = false,
        isScreenshot: Bool = false,
        burstIdentifier: String? = nil,
        contentRevision: String? = nil
    ) {
        self.id = id
        self.source = source
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.creationDate = creationDate
        self.isHidden = isHidden
        self.isScreenshot = isScreenshot
        self.burstIdentifier = burstIdentifier
        self.contentRevision = contentRevision
    }
}

struct ImportedPhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let pixelWidth: Int
    let pixelHeight: Int
    let importedAt: Date
    let creationDate: Date?

    init(
        id: UUID,
        filename: String,
        pixelWidth: Int,
        pixelHeight: Int,
        importedAt: Date,
        creationDate: Date? = nil
    ) {
        self.id = id
        self.filename = filename
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.importedAt = importedAt
        self.creationDate = creationDate
    }

    var candidate: PhotoCandidate {
        PhotoCandidate(
            id: id,
            source: .pickerImport,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            creationDate: creationDate
        )
    }
}

struct ImportProgress: Equatable {
    let completedCount: Int
    let totalCount: Int

    var fractionCompleted: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}

struct PhotoImportFailure: Identifiable, Equatable {
    let sourceID: UUID
    let message: String

    var id: UUID { sourceID }
}

struct PhotoImportReport: Equatable {
    let imported: [ImportedPhoto]
    let failures: [PhotoImportFailure]
    let remainingSourceIDs: [UUID]
    let wasCancelled: Bool
    let limitReachedCount: Int

    init(
        imported: [ImportedPhoto],
        failures: [PhotoImportFailure],
        remainingSourceIDs: [UUID],
        wasCancelled: Bool,
        limitReachedCount: Int = 0
    ) {
        self.imported = imported
        self.failures = failures
        self.remainingSourceIDs = remainingSourceIDs
        self.wasCancelled = wasCancelled
        self.limitReachedCount = limitReachedCount
    }
}
