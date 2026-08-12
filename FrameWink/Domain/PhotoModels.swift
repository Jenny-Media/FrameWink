import Foundation

enum PhotoSource: String, Codable {
    case bundledSample
    case pickerImport
}

struct PhotoCandidate: Identifiable, Codable, Equatable {
    let id: UUID
    let source: PhotoSource
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?
}

struct ImportedPhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let pixelWidth: Int
    let pixelHeight: Int
    let importedAt: Date

    var candidate: PhotoCandidate {
        PhotoCandidate(
            id: id,
            source: .pickerImport,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            creationDate: nil
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
}
