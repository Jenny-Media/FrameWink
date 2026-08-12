import SwiftUI

struct WallModePaywallView: View {
    @ObservedObject var purchases: PurchaseController
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "rectangle.inset.filled.and.person.filled")
                            .font(.system(size: 52))
                            .foregroundColor(.accentColor)
                            .accessibilityHidden(true)

                        Text("Make this iPad a dependable frame")
                            .font(.largeTitle.bold())

                        Text("Wall Mode Lifetime is one non-consumable purchase—no subscription, account, ads, or photo upload.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        paidPoint(
                            icon: "moon.stars.fill",
                            title: "Foreground dimming and blackout",
                            detail: "Use a saved visual schedule while FrameWink remains active."
                        )
                        paidPoint(
                            icon: "display",
                            title: "Continuous foreground display",
                            detail: "Prevent Auto-Lock only during active, foreground Frame Mode."
                        )
                        paidPoint(
                            icon: "checklist",
                            title: "Wall setup assistance",
                            detail: "Commission power, ventilation, cable routing, orientation, Guided Access, and restart recovery."
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Free Smart Reel stays fully useful")
                            .font(.headline)
                        Text("The free experience keeps full-quality local curation, up to 100 imported candidates, one 30-photo reel, review and Never Show Again, face-safe layouts, portrait pairing, Fit/Fill, timing, pause, navigation, and unlimited replay. StoreKit problems never disable it.")
                            .foregroundColor(.secondary)
                    }

                    if purchases.isWallModeUnlocked {
                        Label("Wall Mode is unlocked", systemImage: "checkmark.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.green)

                        Button("Continue") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        purchaseControls
                    }

                    Text("Automatic album refresh, unlimited library sources, and additional saved frame configurations are planned paid capabilities but are not included in this build. This purchase screen only promises the Wall Mode behavior available now.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(32)
            }
            .navigationTitle("Wall Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private var purchaseControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await purchases.purchase() }
            } label: {
                if purchases.actionState == .purchasing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(purchaseTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(purchases.product == nil || purchases.actionState == .purchasing)

            Button("Restore Purchases") {
                Task { await purchases.restore() }
            }
            .buttonStyle(.bordered)
            .disabled(purchases.actionState == .purchasing)

            statusMessage
        }
    }

    private var purchaseTitle: String {
        if let product = purchases.product {
            return "Unlock for \(product.displayPrice)"
        }
        return "Wall Mode unavailable"
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch purchases.actionState {
        case .idle:
            entitlementStatus
        case .purchasing:
            Text("Contacting the App Store…")
                .foregroundColor(.secondary)
        case .purchased, .restored:
            Label("Wall Mode unlocked", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .nothingToRestore:
            Text("No previous Wall Mode purchase was found. Your free Smart Reel is unchanged.")
                .foregroundColor(.secondary)
        case .cancelled:
            Text("Purchase cancelled. Your free Smart Reel is unchanged.")
                .foregroundColor(.secondary)
        case .pending:
            Text("Purchase pending approval. Free Smart Reel remains available while the App Store finishes it.")
                .foregroundColor(.secondary)
        case .failed(let message):
            Label(
                "\(message) Your free Smart Reel is unchanged.",
                systemImage: "exclamationmark.triangle.fill"
            )
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var entitlementStatus: some View {
        switch purchases.entitlement {
        case .loading:
            Text("Checking purchases…")
                .foregroundColor(.secondary)
        case .free:
            if purchases.product?.isFamilyShareable == true {
                Text("Family Sharing is available for this product.")
                    .foregroundColor(.secondary)
            }
        case .purchased:
            EmptyView()
        case .revoked:
            Text("This purchase is no longer entitled. Your free Smart Reel remains available.")
                .foregroundColor(.secondary)
        case .unavailable(let message):
            Text("\(message) Free Smart Reel remains available.")
                .foregroundColor(.secondary)
        }
    }

    private func paidPoint(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundColor(.secondary)
            }
        }
    }
}
