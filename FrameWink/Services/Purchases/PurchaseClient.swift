import Foundation
import StoreKit

@MainActor
protocol PurchaseClient: AnyObject {
    func loadProduct() async throws -> PurchaseProductInfo?
    func currentEntitlement() async throws -> PurchaseEntitlementEvent
    func purchase() async throws -> PurchaseClientResult
    func restore() async throws
    func transactionUpdates() -> AsyncStream<PurchaseEntitlementEvent>
}

enum PurchaseClientError: LocalizedError {
    case productIdentifierMissing
    case productUnavailable
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productIdentifierMissing:
            return "Purchasing is not configured for this build."
        case .productUnavailable:
            return "FrameWink Lifetime is temporarily unavailable from the App Store."
        case .unverifiedTransaction:
            return "The App Store transaction could not be verified. No paid access was granted."
        }
    }
}

@MainActor
final class StoreKitPurchaseClient: PurchaseClient {
    private let productID: String?
    private var product: Product?

    init(productID: String?) {
        self.productID = productID
    }

    func loadProduct() async throws -> PurchaseProductInfo? {
        guard let productID = productID else {
            throw PurchaseClientError.productIdentifierMissing
        }
        let products = try await Product.products(for: [productID])
        guard let product = products.first(where: { $0.id == productID }) else {
            throw PurchaseClientError.productUnavailable
        }
        self.product = product
        return PurchaseProductInfo(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            isFamilyShareable: product.isFamilyShareable
        )
    }

    func currentEntitlement() async throws -> PurchaseEntitlementEvent {
        guard let productID = productID else {
            throw PurchaseClientError.productIdentifierMissing
        }

        for await result in Transaction.currentEntitlements {
            let transaction = result.unsafePayloadValue
            guard transaction.productID == productID else { continue }
            switch result {
            case .verified(let verified):
                return verified.revocationDate == nil ? .purchased : .revoked
            case .unverified:
                return .unverified
            }
        }
        return .notPurchased
    }

    func purchase() async throws -> PurchaseClientResult {
        let product: Product
        if let loaded = self.product {
            product = loaded
        } else {
            _ = try await loadProduct()
            guard let loaded = self.product else {
                throw PurchaseClientError.productUnavailable
            }
            product = loaded
        }

        switch try await product.purchase() {
        case .success(let result):
            switch result {
            case .verified(let transaction):
                guard transaction.productID == productID else {
                    throw PurchaseClientError.unverifiedTransaction
                }
                await transaction.finish()
                return .success
            case .unverified:
                throw PurchaseClientError.unverifiedTransaction
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            throw PurchaseClientError.productUnavailable
        }
    }

    func restore() async throws {
        try await AppStore.sync()
    }

    func transactionUpdates() -> AsyncStream<PurchaseEntitlementEvent> {
        let productID = productID
        return AsyncStream { continuation in
            let task = Task { @MainActor in
                for await result in Transaction.updates {
                    let transaction = result.unsafePayloadValue
                    guard transaction.productID == productID else { continue }
                    switch result {
                    case .verified(let verified):
                        let event: PurchaseEntitlementEvent = verified.revocationDate == nil
                            ? .purchased
                            : .revoked
                        continuation.yield(event)
                        await verified.finish()
                    case .unverified:
                        continuation.yield(.unverified)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
