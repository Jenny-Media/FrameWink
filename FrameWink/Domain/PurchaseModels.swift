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
    case restoring
    case purchased
    case cancelled
    case pending
    case restored
    case nothingToRestore
    case restoreRevoked
    case failed(String)
}

enum PurchaseRestoreResult: Equatable, Identifiable {
    case restored
    case nothingToRestore
    case revoked
    case failed(String)

    var id: String { title }

    var title: String {
        switch self {
        case .restored: return NSLocalizedString("Purchases Restored", comment: "Restore result title")
        case .nothingToRestore: return NSLocalizedString("No Purchase Found", comment: "Restore result title")
        case .revoked: return NSLocalizedString("Purchase No Longer Available", comment: "Restore result title")
        case .failed: return NSLocalizedString("Unable to Restore Purchases", comment: "Restore result title")
        }
    }

    var message: String {
        switch self {
        case .restored:
            return NSLocalizedString("FrameWink Lifetime is unlocked on this device.", comment: "Restore success")
        case .nothingToRestore:
            return NSLocalizedString("No previous FrameWink Lifetime purchase was found for this App Store account. Your free Smart Reel is unchanged.", comment: "Restore found no purchase")
        case .revoked:
            return NSLocalizedString("This purchase was refunded or is no longer available to this account. Your free Smart Reel is unchanged.", comment: "Restore found revoked purchase")
        case .failed(let reason):
            return String(format: NSLocalizedString("%@ Please try restoring again. Your free Smart Reel is unchanged.", comment: "Restore error and retry guidance"), reason)
        }
    }
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
