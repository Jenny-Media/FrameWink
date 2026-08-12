import Foundation

@MainActor
final class PurchaseController: ObservableObject {
    @Published private(set) var entitlement: WallModeEntitlementState = .loading
    @Published private(set) var product: PurchaseProductInfo?
    @Published private(set) var actionState: PurchaseActionState = .idle

    private let client: PurchaseClient
    private var startupTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?

    init(client: PurchaseClient) {
        self.client = client
    }

    deinit {
        startupTask?.cancel()
        updatesTask?.cancel()
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

            do {
                self.product = try await client.loadProduct()
            } catch {
                if !self.entitlement.isUnlocked {
                    self.entitlement = .unavailable(error.localizedDescription)
                }
            }
        }
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
