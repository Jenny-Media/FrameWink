import Foundation

enum RootInitialPresentation: Equatable {
    case frameMode
    case wallModePaywallFeatures
    case wallModePaywallPurchase
    case wallModeSetup
}

#if DEBUG
enum DebugScreenshotScenario: String {
    case sample
    case smartFrame = "smart-frame"
    case paywall
    case paywallFeatures = "paywall-features"
    case wallModeSetup = "wall-mode-setup"

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
        case .sample:
            return nil
        case .smartFrame:
            return .frameMode
        case .paywall:
            return .wallModePaywallPurchase
        case .paywallFeatures:
            return .wallModePaywallFeatures
        case .wallModeSetup:
            return .wallModeSetup
        }
    }

    var requiresWallModeEntitlement: Bool {
        self == .wallModeSetup
    }
}

extension DebugScreenshotScenario {
    func seed(
        wallModeStore: WallModeConfigurationStoring,
        albumStore: AlbumSourceStoring,
        frameConfigurationStore: FrameConfigurationStoring
    ) {
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
                ],
                activeConfigurationID: livingRoomID
            )
        )
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
    private let sampleNames = [
        "sample-lakeside",
        "sample-beach-dog",
        "sample-kitchen",
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
                photoCount: sampleNames.count
            ),
        ]
    }

    func assets(in albumIdentifier: String) throws -> [PhotoLibraryAsset] {
        guard albumIdentifier == "screenshot-family-favorites" else {
            throw PhotoLibraryClientError.albumUnavailable
        }
        return sampleNames.enumerated().map { index, name in
            PhotoLibraryAsset(
                id: name,
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
        guard sampleNames.contains(assetIdentifier),
              let sourceURL = Bundle.main.url(
                forResource: assetIdentifier,
                withExtension: "png"
              ) else {
            throw PhotoLibraryClientError.assetUnavailable
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }

    func changeEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
#endif
