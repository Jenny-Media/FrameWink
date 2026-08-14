import Foundation

struct PurchaseProductInfo: Equatable {
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
    let isFamilyShareable: Bool
}

enum PurchaseClientResult: Equatable {
    case success
    case userCancelled
    case pending
}

enum PurchaseEntitlementEvent: Equatable {
    case notPurchased
    case purchased
    case revoked
    case unverified
}

enum WallModeEntitlementState: Equatable {
    case loading
    case free
    case purchased
    case revoked
    case unavailable(String)

    var isUnlocked: Bool {
        self == .purchased
    }
}

enum PurchaseActionState: Equatable {
    case idle
    case purchasing
    case purchased
    case cancelled
    case pending
    case restored
    case nothingToRestore
    case failed(String)
}

enum ProductConfiguration {
    static let productionWallModeProductID = "media.jenny.FrameWink.wallmode"
    static let localWallModeProductID = "media.jenny.FrameWink.wallmode.local"
    static let infoKey = "FrameWinkWallModeProductIdentifier"

    static func wallModeProductID(bundle: Bundle = .main) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: infoKey) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
