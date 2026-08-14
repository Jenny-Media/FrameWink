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

    func testBundledStoreKitCatalogMatchesProductContract() throws {
        let catalogURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "FrameWink",
                withExtension: "storekit"
            )
        )
        let data = try Data(contentsOf: catalogURL)
        let root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let products = try XCTUnwrap(root["products"] as? [[String: Any]])
        let product = try XCTUnwrap(
            products.first {
                $0["productID"] as? String == ProductConfiguration.localWallModeProductID
            }
        )

        XCTAssertEqual(product["type"] as? String, "NonConsumable")
        XCTAssertEqual(product["familyShareable"] as? Bool, true)
        XCTAssertEqual(product["referenceName"] as? String, "FrameWink Lifetime (Local Test)")
    }

    func testLocalConfigurationLoadsNonConsumableProduct() async throws {
        let product = try await requireRuntimeProduct()

        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertEqual(product.displayName, "FrameWink Lifetime")
        XCTAssertTrue(product.isFamilyShareable)
    }

    func testStoreKitTestPurchaseAndRefundUpdateCurrentEntitlement() async throws {
        _ = try await requireRuntimeProduct()
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
        _ = try await requireRuntimeProduct()
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
        _ = try await requireRuntimeProduct()
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

    private func requireRuntimeProduct() async throws -> Product {
        let products = try await Product.products(
            for: [ProductConfiguration.localWallModeProductID]
        )
        if let product = products.first {
            return product
        }

        if isXcodeCloud {
            throw XCTSkip(
                "Xcode Cloud's artifact-only iOS 26.5 runner did not expose "
                    + "the installed SKTestSession catalog. The bundled catalog "
                    + "is validated separately and runtime transactions remain "
                    + "required in local Simulator tests."
            )
        }

        return try XCTUnwrap(products.first)
    }

    private var isXcodeCloud: Bool {
        let environment = ProcessInfo.processInfo.environment
        let cloudValue = environment["CI_XCODE_CLOUD"]?.lowercased()
        return cloudValue == "true"
            || cloudValue == "1"
            || environment["CI_WORKSPACE"]?.hasPrefix("/Volumes/workspace") == true
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
