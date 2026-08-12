import Foundation
import UIKit

enum RootInitialPresentation: Equatable {
    case frameMode
    case mosaicFrame
    case wallModePaywallFeatures
    case wallModePaywallPurchase
    case wallModeSetup(WallModeSetupInitialSection?)
    case automaticAlbumReview
    case freeReview
}

enum WallModeSetupInitialSection: String, Hashable {
    case automaticAlbum
    case savedConfigurations
    case schedule
    case checklist
}

#if DEBUG
enum DebugScreenshotScenario: String {
    case sample
    case smartFrame = "smart-frame"
    case paywall
    case paywallFeatures = "paywall-features"
    case wallModeSetup = "wall-mode-setup"
    case savedConfigurations = "saved-configurations"
    case wallSchedule = "wall-schedule"
    case wallChecklist = "wall-checklist"
    case automaticAlbumReview = "automatic-album-review"
    case mosaicFrame = "mosaic-frame"
    case freeReview = "free-review-grid"
    case personalReel = "personal-reel"

    static var current: Self? {
        guard let value = ProcessInfo.processInfo.environment[
            "FRAMEWINK_SCREENSHOT_SCENARIO"
        ] else {
            return nil
        }
        return Self(rawValue: value)
    }

    var initialPresentation: RootInitialPresentation? {
        switch self {
        case .sample, .personalReel:
            return nil
        case .smartFrame:
            return .frameMode
        case .paywall:
            return .wallModePaywallPurchase
        case .paywallFeatures:
            return .wallModePaywallFeatures
        case .wallModeSetup:
            return .wallModeSetup(.automaticAlbum)
        case .savedConfigurations:
            return .wallModeSetup(.savedConfigurations)
        case .wallSchedule:
            return .wallModeSetup(.schedule)
        case .wallChecklist:
            return .wallModeSetup(.checklist)
        case .automaticAlbumReview:
            return .automaticAlbumReview
        case .mosaicFrame:
            return .mosaicFrame
        case .freeReview:
            return .freeReview
        }
    }

    var requiresWallModeEntitlement: Bool {
        switch self {
        case .wallModeSetup, .savedConfigurations, .wallSchedule, .wallChecklist,
                .automaticAlbumReview, .mosaicFrame:
            return true
        default:
            return false
        }
    }
}

extension DebugScreenshotScenario {
    static let importedPhotoFixtureIDs = [
        UUID(uuidString: "78F4585F-54C5-4360-9C36-34E2C3F82BC4")!,
        UUID(uuidString: "5255CD65-7C11-4EEB-B7F5-85FC76A4D11B")!,
        UUID(uuidString: "37D2AC69-E0DE-4F0C-A769-8668CBD07BE6")!,
    ]

    func seed(
        importedStore: ImportedPhotoStoring,
        wallModeStore: WallModeConfigurationStoring,
        albumStore: AlbumSourceStoring,
        frameConfigurationStore: FrameConfigurationStoring
    ) {
        if self == .freeReview || self == .personalReel {
            seedFreeReview(importedStore: importedStore)
            return
        }
        guard requiresWallModeEntitlement else { return }

        try? wallModeStore.saveConfiguration(
            WallModeConfiguration(
                scheduleEnabled: true,
                dimStartMinute: 20 * 60,
                blackoutStartMinute: 23 * 60,
                blackoutEndMinute: 7 * 60,
                dimOpacity: 0.58,
                completedChecklistItems: [
                    .compatibleOS,
                    .reliablePower,
                    .batteryCondition,
                    .ventilation,
                ]
            )
        )
        try? albumStore.saveConfiguration(
            AutomaticAlbumConfiguration(
                albumIdentifier: "screenshot-family-favorites",
                albumTitle: "Family Favorites",
                automaticRefresh: true,
                strictOffline: true
            )
        )

        let livingRoomID = UUID(uuidString: "7C4E3A23-7EE6-48D5-83C2-BA4692E296F5")!
        let nightstandID = UUID(uuidString: "42D285AF-D0D4-4C5C-AEFC-388DB0A08F13")!
        let galleryID = UUID(uuidString: "F3EBD59A-115B-4D85-90C1-1587C8B0DE05")!
        try? frameConfigurationStore.saveArchive(
            FrameConfigurationArchive(
                configurations: [
                    SavedFrameConfiguration(
                        id: livingRoomID,
                        name: "Living Room",
                        source: .samples,
                        albumIdentifier: nil,
                        albumTitle: nil,
                        layoutPreference: .mosaic,
                        interval: 10
                    ),
                    SavedFrameConfiguration(
                        id: nightstandID,
                        name: "Nightstand",
                        source: .automaticAlbum,
                        albumIdentifier: "screenshot-family-favorites",
                        albumTitle: "Family Favorites",
                        layoutPreference: .fit,
                        interval: 30
                    ),
                    SavedFrameConfiguration(
                        id: galleryID,
                        name: "Gallery Wall",
                        source: .automaticAlbum,
                        albumIdentifier: "screenshot-family-favorites",
                        albumTitle: "Family Favorites",
                        layoutPreference: .mosaic,
                        interval: 10
                    ),
                ],
                activeConfigurationID: self == .mosaicFrame ? galleryID : livingRoomID
            )
        )
    }

    private func seedFreeReview(importedStore: ImportedPhotoStoring) {
        let samples = [
            (
                id: Self.importedPhotoFixtureIDs[0],
                resource: "sample-lakeside"
            ),
            (
                id: Self.importedPhotoFixtureIDs[1],
                resource: "sample-beach-dog"
            ),
            (
                id: Self.importedPhotoFixtureIDs[2],
                resource: "sample-kitchen"
            ),
        ]
        do {
            try importedStore.prepareDirectories()
            let photos = try samples.enumerated().map { index, sample -> ImportedPhoto in
                guard let sourceURL = Bundle.main.url(
                    forResource: sample.resource,
                    withExtension: "png"
                ) else {
                    throw PhotoLibraryClientError.assetUnavailable
                }
                let filename = sample.id.uuidString + ".png"
                try FileManager.default.copyItem(
                    at: sourceURL,
                    to: importedStore.imageURL(filename: filename)
                )
                return ImportedPhoto(
                    id: sample.id,
                    filename: filename,
                    pixelWidth: 1_536,
                    pixelHeight: 1_024,
                    importedAt: Date(timeIntervalSinceReferenceDate: Double(index)),
                    creationDate: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400)
                )
            }
            try importedStore.saveImportedPhotos(photos)
        } catch {
            assertionFailure("Could not seed Free review screenshot: \(error)")
        }
    }
}

@MainActor
final class DebugScreenshotPurchaseClient: PurchaseClient {
    private let isEntitled: Bool

    init(isEntitled: Bool) {
        self.isEntitled = isEntitled
    }

    func loadProduct() async throws -> PurchaseProductInfo? {
        PurchaseProductInfo(
            id: ProductConfiguration.localWallModeProductID,
            displayName: "Wall Mode Lifetime",
            description: "One-time Wall Mode unlock",
            displayPrice: "$9.99",
            isFamilyShareable: false
        )
    }

    func currentEntitlement() async throws -> PurchaseEntitlementEvent {
        isEntitled ? .purchased : .notPurchased
    }

    func purchase() async throws -> PurchaseClientResult {
        .success
    }

    func restore() async throws {}

    func transactionUpdates() -> AsyncStream<PurchaseEntitlementEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

@MainActor
final class DebugScreenshotPhotoLibraryClient: PhotoLibraryClient {
    private let sampleAssets = [
        (id: "sample-lakeside", resource: "sample-lakeside"),
        (id: "sample-beach-dog", resource: "sample-beach-dog"),
        (id: "sample-kitchen", resource: "sample-kitchen"),
        (id: "sample-lakeside-alt", resource: "sample-lakeside"),
    ]

    func authorizationState() -> PhotoLibraryAuthorizationState {
        .authorized
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationState {
        .authorized
    }

    func albums() throws -> [PhotoLibraryAlbum] {
        [
            PhotoLibraryAlbum(
                id: "screenshot-family-favorites",
                title: "Family Favorites",
                photoCount: sampleAssets.count
            ),
        ]
    }

    func assets(in albumIdentifier: String) throws -> [PhotoLibraryAsset] {
        guard albumIdentifier == "screenshot-family-favorites" else {
            throw PhotoLibraryClientError.albumUnavailable
        }
        return sampleAssets.enumerated().map { index, sample in
            PhotoLibraryAsset(
                id: sample.id,
                pixelWidth: 2_048,
                pixelHeight: 2_560,
                creationDate: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400),
                modificationDate: Date(timeIntervalSinceReferenceDate: 1_000 + Double(index)),
                isHidden: false,
                isScreenshot: false,
                burstIdentifier: nil
            )
        }
    }

    func exportCurrentImage(
        assetIdentifier: String,
        to destinationURL: URL,
        networkAccessAllowed: Bool
    ) async throws {
        guard let sample = sampleAssets.first(where: { $0.id == assetIdentifier }),
              let sourceURL = Bundle.main.url(
                forResource: sample.resource,
                withExtension: "png"
              ) else {
            throw PhotoLibraryClientError.assetUnavailable
        }
        if assetIdentifier == "sample-lakeside-alt",
           let image = UIImage(contentsOfFile: sourceURL.path),
           let cgImage = image.cgImage,
           let detail = cgImage.cropping(
            to: CGRect(
                x: cgImage.width / 2,
                y: 0,
                width: cgImage.width / 2,
                height: cgImage.height
            )
           ),
           let data = UIImage(cgImage: detail).pngData() {
            try data.write(to: destinationURL, options: .atomic)
            return
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }

    func changeEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

final class DebugScreenshotSmartReelBuilder: SmartReelBuilding {
    private let savedCandidateIDs: [UUID]

    init(savedCandidateIDs: [UUID] = []) {
        self.savedCandidateIDs = savedCandidateIDs
    }

    func loadSavedReel() throws -> SmartReel? {
        guard !savedCandidateIDs.isEmpty else { return nil }
        return makeReel(
            candidateIDs: savedCandidateIDs,
            maximumSelectionCount: 30
        )
    }

    func build(
        candidates: [PhotoCandidate],
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        try await buildUnbounded(
            candidates: candidates,
            maximumSelectionCount: 30,
            imageProvider: imageProvider,
            progress: progress
        )
    }

    func buildUnbounded(
        candidates: [PhotoCandidate],
        maximumSelectionCount: Int,
        imageProvider: @escaping (UUID) async -> UIImage?,
        progress: @escaping @MainActor (ImportProgress) -> Void
    ) async throws -> SmartReel {
        await progress(
            ImportProgress(
                completedCount: candidates.count,
                totalCount: candidates.count
            )
        )
        return makeReel(
            candidateIDs: candidates.map(\.id),
            maximumSelectionCount: maximumSelectionCount
        )
    }

    private func makeReel(
        candidateIDs: [UUID],
        maximumSelectionCount: Int
    ) -> SmartReel {
        SmartReel(
            id: UUID(uuidString: "1E7EF660-F5E4-4A66-AC52-6C52A6D49F62")!,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            selections: candidateIDs.prefix(maximumSelectionCount).enumerated().map {
                index, candidateID in
                CuratedPhoto(
                    candidateID: candidateID,
                    algorithmRevision: SmartReelCurator.algorithmRevision,
                    finalScore: 1 - Double(index) * 0.01,
                    reasons: [.quality, .layout]
                )
            }
        )
    }

    func exclude(candidateID: UUID, from reel: SmartReel) throws -> SmartReel {
        SmartReel(
            id: reel.id,
            algorithmRevision: reel.algorithmRevision,
            createdAt: reel.createdAt,
            selections: reel.selections.filter { $0.candidateID != candidateID }
        )
    }

    func resetExclusions() throws {}
}
#endif
