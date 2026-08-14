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
    case schedule
    case checklist
}

#if DEBUG
enum DebugPhysicalAcceptanceMode {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["FRAMEWINK_PHYSICAL_ACCEPTANCE"] == "1"
    }
}

enum DebugScreenshotScenario: String {
    case sample
    case smartFrame = "smart-frame"
    case paywall
    case paywallFeatures = "paywall-features"
    case wallModeSetup = "wall-mode-setup"
    case wallSchedule = "wall-schedule"
    case wallChecklist = "wall-checklist"
    case automaticAlbumReview = "automatic-album-review"
    case mosaicFrame = "mosaic-frame"
    case freeReview = "free-review-grid"
    case personalReel = "personal-reel"
    case sourceIntegrity = "source-integrity"
    case personalImport = "personal-import"
    case blackoutFrame = "blackout-frame"
    case albumPicker = "album-picker"
    case frameControls = "frame-controls"

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
        case .sample, .personalReel, .sourceIntegrity, .personalImport, .albumPicker:
            return nil
        case .smartFrame, .blackoutFrame, .frameControls:
            return .frameMode
        case .paywall:
            return .wallModePaywallPurchase
        case .paywallFeatures:
            return .wallModePaywallFeatures
        case .wallModeSetup:
            return .wallModeSetup(.schedule)
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
        case .wallModeSetup, .wallSchedule, .wallChecklist,
                .automaticAlbumReview, .mosaicFrame, .blackoutFrame, .albumPicker,
                .sourceIntegrity, .frameControls:
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
        if self == .freeReview || self == .personalReel || self == .sourceIntegrity {
            seedFreeReview(importedStore: importedStore)
            if self == .personalReel || self == .sourceIntegrity {
                let configurationID = UUID(
                    uuidString: "B6E10F2B-9C8F-4AE6-B697-ED5AF43F5F11"
                )!
                try? frameConfigurationStore.saveArchive(
                    FrameConfigurationArchive(
                        configurations: [
                            SavedFrameConfiguration(
                                id: configurationID,
                                name: "Personal Reel",
                                source: self == .sourceIntegrity ? .samples : .freeSmartReel,
                                albumIdentifier: nil,
                                albumTitle: nil,
                                layoutPreference: .automatic,
                                interval: 60
                            ),
                        ],
                        activeConfigurationID: configurationID
                    )
                )
            }
            return
        }
        guard requiresWallModeEntitlement else { return }

        let nowComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinute = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let scheduleEnabled = self == .wallModeSetup
            || self == .wallSchedule
            || self == .wallChecklist
            || self == .blackoutFrame
        try? wallModeStore.saveConfiguration(
            WallModeConfiguration(
                scheduleEnabled: scheduleEnabled,
                dimStartMinute: self == .blackoutFrame
                    ? (currentMinute + 1_438) % 1_440
                    : 20 * 60,
                blackoutStartMinute: self == .blackoutFrame
                    ? (currentMinute + 1_439) % 1_440
                    : 23 * 60,
                blackoutEndMinute: self == .blackoutFrame
                    ? (currentMinute + 2) % 1_440
                    : 7 * 60,
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
                strictOffline: false
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
                        interval: 30
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
        let samples = zip(
            Self.importedPhotoFixtureIDs,
            BundledSampleCatalog.photos.prefix(Self.importedPhotoFixtureIDs.count)
        )
        do {
            try importedStore.prepareDirectories()
            let photos = try samples.enumerated().map { index, sample -> ImportedPhoto in
                let (id, bundledPhoto) = sample
                guard let sourceURL = BundledSampleImageLoader.url(
                    named: bundledPhoto.resourceName
                ) else {
                    throw PhotoLibraryClientError.assetUnavailable
                }
                let filename = id.uuidString + "." + sourceURL.pathExtension
                try FileManager.default.copyItem(
                    at: sourceURL,
                    to: importedStore.imageURL(filename: filename)
                )
                return ImportedPhoto(
                    id: id,
                    filename: filename,
                    pixelWidth: bundledPhoto.pixelSize.width,
                    pixelHeight: bundledPhoto.pixelSize.height,
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
            displayName: "FrameWink Lifetime",
            description: "One-time FrameWink feature unlock",
            displayPrice: "$9.99",
            isFamilyShareable: true
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
        (id: "sample-city-skyline", resource: "sample-city-skyline", width: 2_048, height: 1_365),
        (id: "sample-city-tower", resource: "sample-city-tower", width: 1_365, height: 2_048),
        (id: "sample-autumn-leaves", resource: "sample-autumn-leaves", width: 2_048, height: 1_365),
        (id: "sample-city-skyline-alt", resource: "sample-city-skyline", width: 1_024, height: 1_365),
    ]

    func authorizationState() -> PhotoLibraryAuthorizationState {
        .authorized
    }

    func requestAuthorization() async -> PhotoLibraryAuthorizationState {
        .authorized
    }

    func albums() async throws -> [PhotoLibraryAlbum] {
        [
            PhotoLibraryAlbum(
                id: "screenshot-family-favorites",
                title: "Family Favorites",
                photoCount: sampleAssets.count
            ),
            PhotoLibraryAlbum(
                id: "screenshot-recently-added",
                title: "Recently Added",
                photoCount: 48
            ),
            PhotoLibraryAlbum(
                id: "screenshot-travel",
                title: "Travel",
                photoCount: 126
            ),
            PhotoLibraryAlbum(
                id: "screenshot-weekends",
                title: "Weekends",
                photoCount: 21
            ),
            PhotoLibraryAlbum(
                id: "screenshot-portraits",
                title: "Portraits",
                photoCount: 76
            ),
            PhotoLibraryAlbum(
                id: "screenshot-favorites",
                title: "Favorites",
                photoCount: 19
            ),
        ]
    }

    func albumThumbnail(
        albumIdentifier: String,
        maxPixelDimension: Int
    ) async -> UIImage? {
        let resources = BundledSampleCatalog.photos.prefix(3).map(\.resourceName)
        let index = abs(albumIdentifier.hashValue) % resources.count
        guard let url = BundledSampleImageLoader.url(named: resources[index]) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    func assets(in albumIdentifier: String) async throws -> [PhotoLibraryAsset] {
        guard albumIdentifier == "screenshot-family-favorites" else {
            throw PhotoLibraryClientError.albumUnavailable
        }
        return sampleAssets.enumerated().map { index, sample in
            PhotoLibraryAsset(
                id: sample.id,
                pixelWidth: sample.width,
                pixelHeight: sample.height,
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
              let sourceURL = BundledSampleImageLoader.url(named: sample.resource) else {
            throw PhotoLibraryClientError.assetUnavailable
        }
        if assetIdentifier == "sample-city-skyline-alt",
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
           let data = UIImage(cgImage: detail).jpegData(compressionQuality: 0.9) {
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
