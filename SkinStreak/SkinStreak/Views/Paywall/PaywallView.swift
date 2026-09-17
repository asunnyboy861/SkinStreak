import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementManager
    @State private var selectedTier: Tier = .yearly
    @State private var isPurchasing = false
    @State private var successMessage: String?
    @State private var showBYOSetup = false

    enum Tier: String, CaseIterable, Identifiable {
        case yearly, monthly, forever
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    featureList
                    tierCards
                    purchaseButton
                    if let successMessage {
                        Label(successMessage, systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.sageDeep)
                            .multilineTextAlignment(.center)
                    }
                    if let loadError = entitlements.loadError {
                        Text(loadError)
                            .font(.caption)
                            .foregroundStyle(Theme.coral)
                    }
                    disclosure
                    legalLinks
                    Button("Restore purchases") {
                        Task { await entitlements.restore() }
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .background(Theme.sand.ignoresSafeArea())
            .navigationTitle("SkinStreak Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showBYOSetup) {
                BYOKeySetupView()
            }
            .task {
                if entitlements.products.isEmpty {
                    await entitlements.loadProducts()
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.flame)
            Text("Proof beats promises.")
                .font(.title2.weight(.bold))
            Text("Conflict checks, streaks and photos are free forever. Pro adds the deep stuff.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("sparkles", "Unlimited deep scans with Apple Intelligence or your own key")
            featureRow("chart.line.uptrend.xyaxis", "Weekly Proof report with measured trends")
            featureRow("quote.opening", "Attribution — what changed when your routine changed")
            featureRow("square.and.arrow.up", "9:16 share cards, watermarked, no filters")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.sage)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }

    private var tierCards: some View {
        VStack(spacing: 10) {
            tierCard(.yearly, title: "Yearly", subtitle: "7-day free trial, then per year", price: entitlements.yearlyProduct?.displayPrice, badge: "Best value", trialNote: "7-day free trial")
            tierCard(.monthly, title: "Monthly", subtitle: "Cancel anytime", price: entitlements.monthlyProduct?.displayPrice, badge: nil, trialNote: nil)
            tierCard(.forever, title: "Forever BYO", subtitle: "One-time purchase — bring your own AI key", price: entitlements.foreverProduct?.displayPrice, badge: nil, trialNote: nil)
        }
    }

    private func tierCard(_ tier: Tier, title: String, subtitle: String, price: String?, badge: String?, trialNote: String?) -> some View {
        let isSelected = selectedTier == tier
        return Button {
            selectedTier = tier
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.flame.opacity(0.18), in: Capsule())
                                .foregroundStyle(Theme.flame)
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let trialNote {
                        Text(trialNote)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.sageDeep)
                    }
                }
                Spacer()
                Text(price ?? "—")
                    .font(.headline)
                    .monospacedDigit()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.sage : Color.secondary)
            }
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Theme.sage : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            HStack {
                if isPurchasing || entitlements.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(buttonTitle)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isPurchasing || entitlements.isLoading || currentProduct == nil)
    }

    private var buttonTitle: String {
        switch selectedTier {
        case .yearly: "Start 7-day free trial"
        case .monthly: "Subscribe monthly"
        case .forever: "Buy once, keep forever"
        }
    }

    private var currentProduct: StoreKit.Product? {
        switch selectedTier {
        case .yearly: entitlements.yearlyProduct
        case .monthly: entitlements.monthlyProduct
        case .forever: entitlements.foreverProduct
        }
    }

    private var disclosure: some View {
        Text("Payment is charged to your Apple Account at confirmation. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period; the free trial converts to a paid subscription unless cancelled 24 hours before it ends. Manage or cancel anytime in Settings > Apple Account > Subscriptions.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var legalLinks: some View {
        HStack(spacing: 24) {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/SkinStreak/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/SkinStreak/terms.html")!)
        }
        .font(.caption)
    }

    private func purchase() {
        guard let product = currentProduct else { return }
        isPurchasing = true
        Task {
            let success = await entitlements.purchase(product)
            isPurchasing = false
            if success {
                Haptics.success()
                if selectedTier == .forever {
                    showBYOSetup = true
                } else {
                    successMessage = "You're Pro. Deep scans and the Weekly Proof report are unlocked."
                }
            }
        }
    }
}

struct BYOKeySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.sage)
                Text("Bring your own AI key")
                    .font(.title3.weight(.bold))
                Text("Paste a GLM API key to power unlimited deep scans. It's stored in your phone's Keychain and sent only to the AI endpoint — never to us.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                SecureField("GLM API key", text: $key)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button {
                    GLMKeyStore.save(key.trimmingCharacters(in: .whitespacesAndNewlines))
                    saved = true
                    Haptics.success()
                } label: {
                    Text("Save key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if saved {
                    Label("Key saved — it stays on your phone.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.sageDeep)
                }
                Text(Theme.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(Theme.sand.ignoresSafeArea())
            .navigationTitle("Deep scan setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
