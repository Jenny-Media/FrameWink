import Foundation

@MainActor
final class PurchaseController: ObservableObject {
    @Published private(set) var entitlement: WallModeEntitlementState = .loading
    @Published private(set) var product: PurchaseProductInfo?
    @Published private(set) var actionState: PurchaseActionState = .idle
    @Published private(set) var isLoadingProduct = false

    private let client: PurchaseClient
    private var startupTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    private var productTask: Task<Void, Never>?

    init(client: PurchaseClient) {
        self.client = client
    }

    deinit {
        startupTask?.cancel()
        updatesTask?.cancel()
        productTask?.cancel()
    }

    var isWallModeUnlocked: Bool {
        entitlement.isUnlocked
    }

    func start() {
        guard startupTask == nil, updatesTask == nil else { return }

        updatesTask = Task { [weak self, client] in
            for await event in client.transactionUpdates() {
                guard !Task.isCancelled else { return }
                self?.apply(event)
            }
        }

        startupTask = Task { [weak self, client] in
            guard let self = self else { return }
            do {
                self.apply(try await client.currentEntitlement())
            } catch {
                self.entitlement = .unavailable(error.localizedDescription)
            }

            self.beginProductLoad()
        }
    }

    func refreshProduct() {
        guard product == nil else { return }
        beginProductLoad()
    }

    func purchase() async {
        actionState = .purchasing
        do {
            switch try await client.purchase() {
            case .success:
                apply(.purchased)
                actionState = .purchased
            case .userCancelled:
                actionState = .cancelled
            case .pending:
                actionState = .pending
            }
        } catch {
            actionState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        actionState = .purchasing
        do {
            try await client.restore()
            let refreshed = try await client.currentEntitlement()
            apply(refreshed)
            actionState = refreshed == .purchased ? .restored : .nothingToRestore
        } catch {
            actionState = .failed(error.localizedDescription)
        }
    }

    func clearActionStatus() {
        actionState = .idle
    }

    private func beginProductLoad() {
        guard productTask == nil else { return }
        isLoadingProduct = true
        productTask = Task { [weak self, client] in
            defer {
                self?.isLoadingProduct = false
                self?.productTask = nil
            }
            do {
                let loadedProduct = try await client.loadProduct()
                guard let self else { return }
                product = loadedProduct
                if case .unavailable = entitlement {
                    entitlement = .free
                }
            } catch {
                guard let self, !entitlement.isUnlocked else { return }
                entitlement = .unavailable(error.localizedDescription)
            }
        }
    }

    private func apply(_ event: PurchaseEntitlementEvent) {
        switch event {
        case .notPurchased:
            entitlement = .free
        case .purchased:
            entitlement = .purchased
        case .revoked:
            entitlement = .revoked
        case .unverified:
            if !entitlement.isUnlocked {
                entitlement = .free
            }
            actionState = .failed(
                PurchaseClientError.unverifiedTransaction.localizedDescription
            )
        }
    }
}
