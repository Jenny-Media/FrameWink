import XCTest
@testable import FrameWink

@MainActor
final class PurchaseControllerTests: XCTestCase {
    func testFreeStateLoadsProductWithoutUnlocking() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)

        controller.start()
        await waitUntil { controller.entitlement == .free && controller.product != nil }

        XCTAssertFalse(controller.isWallModeUnlocked)
        XCTAssertEqual(client.updatesStreamCount, 1)
    }

    func testVerifiedPurchaseUnlocksWallMode() async {
        let client = FakePurchaseClient()
        client.purchaseResult = .success
        let controller = PurchaseController(client: client)

        controller.start()
        await waitUntil { controller.entitlement == .free }
        await controller.purchase()

        XCTAssertTrue(controller.isWallModeUnlocked)
        XCTAssertEqual(controller.actionState, .purchased)
    }

    func testCancellationAndPendingRemainFreeAndRecoverable() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .free }

        client.purchaseResult = .userCancelled
        await controller.purchase()
        XCTAssertEqual(controller.actionState, .cancelled)
        XCTAssertFalse(controller.isWallModeUnlocked)

        client.purchaseResult = .pending
        await controller.purchase()
        XCTAssertEqual(controller.actionState, .pending)
        XCTAssertFalse(controller.isWallModeUnlocked)
    }

    func testPurchaseFailureDoesNotDisableFreeState() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .free }

        client.purchaseError = TestPurchaseError.expected
        await controller.purchase()

        if case .failed = controller.actionState {
            XCTAssertEqual(controller.entitlement, .free)
        } else {
            XCTFail("Expected recoverable purchase failure")
        }
    }

    func testRestoreIsIdempotentAndUsesRefreshedVerifiedEntitlement() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .free }
        client.entitlement = .purchased

        await controller.restore()
        await controller.restore()

        XCTAssertEqual(client.restoreCount, 2)
        XCTAssertEqual(controller.entitlement, .purchased)
        XCTAssertEqual(controller.actionState, .restored)
    }

    func testRestoreWithoutPurchaseReportsRecoverableFreeState() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .free }

        await controller.restore()

        XCTAssertEqual(controller.entitlement, .free)
        XCTAssertEqual(controller.actionState, .nothingToRestore)
    }

    func testRevocationUpdateRemovesOnlyPaidEntitlement() async {
        let client = FakePurchaseClient()
        client.entitlement = .purchased
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .purchased }

        client.send(.revoked)
        await waitUntil { controller.entitlement == .revoked }

        XCTAssertFalse(controller.isWallModeUnlocked)
    }

    func testUnverifiedUpdateNeverUnlocks() async {
        let client = FakePurchaseClient()
        let controller = PurchaseController(client: client)
        controller.start()
        await waitUntil { controller.entitlement == .free }

        client.send(.unverified)
        await waitUntil {
            if case .failed = controller.actionState { return true }
            return false
        }

        XCTAssertEqual(controller.entitlement, .free)
    }

    func testOfflineProductFailurePreservesLastStoreKitVerifiedEntitlement() async {
        let client = FakePurchaseClient()
        client.entitlement = .purchased
        client.productError = TestPurchaseError.expected
        let controller = PurchaseController(client: client)

        controller.start()
        await waitUntil { controller.entitlement == .purchased }

        XCTAssertTrue(controller.isWallModeUnlocked)
        XCTAssertNil(controller.product)
    }

    func testStoreKitUnavailableKeepsFreeExperienceRecoverable() async {
        let client = FakePurchaseClient()
        client.entitlementError = TestPurchaseError.expected
        client.productError = TestPurchaseError.expected
        let controller = PurchaseController(client: client)

        controller.start()
        await waitUntil {
            if case .unavailable = controller.entitlement { return true }
            return false
        }

        XCTAssertFalse(controller.isWallModeUnlocked)
    }

    func testUnavailableProductCanBeRetriedWithoutRestarting() async {
        let client = FakePurchaseClient()
        client.productError = TestPurchaseError.expected
        let controller = PurchaseController(client: client)

        controller.start()
        await waitUntil {
            if case .unavailable = controller.entitlement { return true }
            return false
        }

        client.productError = nil
        controller.refreshProduct()
        await waitUntil { controller.product != nil && controller.entitlement == .free }

        XCTAssertEqual(client.loadProductCount, 2)
        XCTAssertFalse(controller.isWallModeUnlocked)
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            await Task.yield()
        }
        XCTAssertTrue(condition())
    }
}

@MainActor
private final class FakePurchaseClient: PurchaseClient {
    var product = PurchaseProductInfo(
        id: ProductConfiguration.productionWallModeProductID,
        displayName: "FrameWink Lifetime",
        description: "Local test product",
        displayPrice: "$9.99",
        isFamilyShareable: false
    )
    var productError: Error?
    var entitlement: PurchaseEntitlementEvent = .notPurchased
    var entitlementError: Error?
    var purchaseResult: PurchaseClientResult = .success
    var purchaseError: Error?
    private(set) var restoreCount = 0
    private(set) var updatesStreamCount = 0
    private(set) var loadProductCount = 0
    private var continuation: AsyncStream<PurchaseEntitlementEvent>.Continuation?

    func loadProduct() async throws -> PurchaseProductInfo? {
        loadProductCount += 1
        if let productError = productError { throw productError }
        return product
    }

    func currentEntitlement() async throws -> PurchaseEntitlementEvent {
        if let entitlementError = entitlementError { throw entitlementError }
        return entitlement
    }

    func purchase() async throws -> PurchaseClientResult {
        if let purchaseError = purchaseError { throw purchaseError }
        return purchaseResult
    }

    func restore() async throws {
        restoreCount += 1
    }

    func transactionUpdates() -> AsyncStream<PurchaseEntitlementEvent> {
        updatesStreamCount += 1
        return AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func send(_ event: PurchaseEntitlementEvent) {
        continuation?.yield(event)
    }
}

private enum TestPurchaseError: LocalizedError {
    case expected

    var errorDescription: String? { "Expected StoreKit failure" }
}
