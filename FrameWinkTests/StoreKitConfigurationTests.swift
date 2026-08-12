import StoreKit
import StoreKitTest
import XCTest
@testable import FrameWink

@MainActor
final class StoreKitConfigurationTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "FrameWink")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        session = nil
    }

    func testLocalConfigurationLoadsNonConsumableProduct() async throws {
        let products = try await Product.products(
            for: [ProductConfiguration.localWallModeProductID]
        )
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertEqual(product.displayName, "Wall Mode Lifetime")
        XCTAssertTrue(product.isFamilyShareable)
    }

    func testStoreKitTestPurchaseAndRefundUpdateCurrentEntitlement() async throws {
        let client = StoreKitPurchaseClient(
            productID: ProductConfiguration.localWallModeProductID
        )
        _ = try await client.loadProduct()
        let purchaseResult = try await client.purchase()
        XCTAssertEqual(purchaseResult, .success)
        let purchased = await waitForEntitlement(
            from: client,
            matching: { $0 == .purchased }
        )
        XCTAssertEqual(purchased, .purchased)

        try await client.restore()
        let restoredEntitlement = try await client.currentEntitlement()
        XCTAssertEqual(restoredEntitlement, .purchased)

        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        let refunded = await waitForEntitlement(
            from: client,
            matching: { $0 == .revoked || $0 == .notPurchased }
        )
        XCTAssertNotEqual(refunded, .purchased)
        XCTAssertTrue(refunded == .revoked || refunded == .notPurchased)
    }

    func testStoreKitTestAskToBuyReturnsPendingWithoutUnlocking() async throws {
        session.askToBuyEnabled = true
        let client = StoreKitPurchaseClient(
            productID: ProductConfiguration.localWallModeProductID
        )
        _ = try await client.loadProduct()

        let purchaseResult = try await client.purchase()

        XCTAssertEqual(purchaseResult, .pending)
        let entitlement = try await client.currentEntitlement()
        XCTAssertEqual(entitlement, .notPurchased)
    }

    func testStoreKitTestPurchaseFailureDoesNotCreateEntitlement() async throws {
        let client = StoreKitPurchaseClient(
            productID: ProductConfiguration.localWallModeProductID
        )
        _ = try await client.loadProduct()
        try await session.setSimulatedError(
            .generic(.notAvailableInStorefront),
            forAPI: .purchase
        )

        do {
            _ = try await client.purchase()
            XCTFail("Expected the simulated StoreKit failure")
        } catch {
            let entitlement = try await client.currentEntitlement()
            XCTAssertEqual(entitlement, .notPurchased)
        }
    }

    private func waitForEntitlement(
        from client: StoreKitPurchaseClient,
        matching predicate: (PurchaseEntitlementEvent) -> Bool,
        attempts: Int = 50
    ) async -> PurchaseEntitlementEvent? {
        for _ in 0..<attempts {
            if let entitlement = try? await client.currentEntitlement(),
               predicate(entitlement) {
                return entitlement
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return nil
    }
}
