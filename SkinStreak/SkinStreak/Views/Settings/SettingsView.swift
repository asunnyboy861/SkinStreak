import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var quota = QuotaManager.shared
    @Query private var profiles: [UserProfile]
    @State private var showPaywall = false
    @State private var showContact = false
    @State private var glmKeyInput = ""
    @State private var keyStatus: String?
    @State private var isTestingKey = false
    @State private var confirmDelete = false

    private var profile: UserProfile? { profiles.first }
    private var hasKey: Bool { GLMClient.hasKey }

    // Must match OnboardingView's option values exactly — otherwise the pickers render blank.
    private static let skinTypeOptions = ["Oily", "Dry", "Combination", "Sensitive"]
    private static let goalOptions = ["Clear acne", "Even tone", "Calm redness", "Smooth texture", "General glow"]

    private func normalize(_ value: String, options: [String], fallback: String) -> String {
        options.first { $0.caseInsensitiveCompare(value) == .orderedSame } ?? fallback
    }

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                aiSection
                keySection
                profileSection
                remindersSection
                dataSection
                legalSection
                dangerSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showContact) {
                NavigationStack {
                    ContactSupportView()
                }
            }
            .confirmationDialog("Delete all my data?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes products, photos, reports, streaks and your saved API key. This cannot be undone.")
            }
        }
    }

    private var subscriptionSection: some View {
        Section {
            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                HStack {
                    Label("Manage Subscription", systemImage: "creditcard.fill")
                        .foregroundStyle(Theme.sageDeep)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if entitlements.isPro {
                HStack {
                    Label("SkinStreak Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.flame)
                    Spacer()
                    Text(entitlements.isForever ? "Forever BYO" : "Active")
                        .foregroundStyle(.secondary)
                }
                if let trialEnd = entitlements.trialEndDate {
                    Label("Free trial ends \(trialEnd.formatted(date: .abbreviated, time: .omitted))", systemImage: "hourglass")
                        .font(.subheadline)
                        .foregroundStyle(Theme.flame)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "crown")
                            .foregroundStyle(Theme.sageDeep)
                        Spacer()
                        Text("from $3.99/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var aiSection: some View {
        Section {
            HStack {
                Image(systemName: "apple.logo")
                    .foregroundStyle(Theme.sageDeep)
                Text("Apple Intelligence")
                Spacer()
                Text(appleIntelligenceStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Label("Deep scans left this week", systemImage: "sparkles")
                Spacer()
                Text(quotaText)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if let guidance = appleIntelligenceGuidance {
                Text(guidance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("AI")
        } footer: {
            Text("Daily notes run on-device when possible. Deep scans try your key first, then Apple Intelligence, then the template coach — you always get a note.")
        }
    }

    private var appleIntelligenceStatus: String {
        if #available(iOS 26.0, *) {
            return AppleIntelligenceStatus.isAvailable ? "On — on-device" : "Unavailable"
        }
        return "Needs iOS 26"
    }

    private var appleIntelligenceGuidance: String? {
        if #available(iOS 26.0, *) {
            return AppleIntelligenceStatus.isAvailable ? nil : AppleIntelligenceStatus.guidanceText
        }
        return "Apple Intelligence requires iOS 26 or newer. Add your own key below for AI insights."
    }

    private var quotaText: String {
        let remaining = quota.remainingDeepScans(isPro: entitlements.isPro)
        return remaining == .max ? "Unlimited" : "\(remaining) of \(QuotaManager.weeklyFreeLimit)"
    }

    private var keySection: some View {
        Section {
            SecureField("GLM API key (z.ai)", text: $glmKeyInput)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            HStack {
                Button("Save") {
                    GLMKeyStore.save(glmKeyInput.trimmingCharacters(in: .whitespacesAndNewlines))
                    glmKeyInput = ""
                    keyStatus = "Key saved."
                }
                .disabled(glmKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Test") {
                    isTestingKey = true
                    keyStatus = nil
                    Task {
                        do {
                            _ = try await GLMClient.testKey()
                            keyStatus = "Key works — deep scans will use GLM first."
                        } catch {
                            keyStatus = error.localizedDescription
                        }
                        isTestingKey = false
                    }
                }
                .disabled(!hasKey || isTestingKey)
                Button("Clear", role: .destructive) {
                    GLMKeyStore.clear()
                    glmKeyInput = ""
                    keyStatus = "Key removed."
                }
                .disabled(!hasKey)
                Spacer()
                if isTestingKey {
                    ProgressView()
                }
            }
            if let keyStatus {
                Text(keyStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(hasKey ? "A key is saved on this phone." : "No key saved yet — deep scans still work via Apple Intelligence or the template coach.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Your own AI key")
        } footer: {
            Text("Key stays on your phone. It's stored in the iOS Keychain and sent only to the AI endpoint when you run a deep scan.")
        }
    }

    private var profileSection: some View {
        Section("Your skin") {
            if let profile {
                Picker("Skin type", selection: Binding(
                    get: { normalize(profile.skinType, options: Self.skinTypeOptions, fallback: "Combination") },
                    set: { profile.skinType = $0 }
                )) {
                    ForEach(Self.skinTypeOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                Picker("Main goal", selection: Binding(
                    get: { normalize(profile.goal, options: Self.goalOptions, fallback: "General glow") },
                    set: { profile.goal = $0 }
                )) {
                    ForEach(Self.goalOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                Picker("Fitzpatrick type", selection: Binding(get: { profile.fitzpatrick }, set: { profile.fitzpatrick = $0 })) {
                    Text("I — Very fair, always burns").tag(1)
                    Text("II — Fair, burns easily").tag(2)
                    Text("III — Medium, sometimes burns").tag(3)
                    Text("IV — Olive, rarely burns").tag(4)
                    Text("V — Brown, almost never burns").tag(5)
                    Text("VI — Deep brown, never burns").tag(6)
                }
            }
        }
    }

    private var remindersSection: some View {
        Section {
            if let profile {
                Toggle(isOn: Binding(
                    get: { profile.sundayReminderEnabled },
                    set: { enabled in
                        profile.sundayReminderEnabled = enabled
                        if enabled {
                            Task {
                                if await NotificationScheduler.requestAuthorization() {
                                    NotificationScheduler.scheduleSundayReminder()
                                }
                            }
                        } else {
                            NotificationScheduler.cancelSundayReminder()
                        }
                    }
                )) {
                    Label("Sunday photo reminder", systemImage: "bell.fill")
                }
            }
        } footer: {
            Text("A gentle nudge every Sunday at 7:00 PM to keep your weekly proof aligned.")
        }
    }

    private var dataSection: some View {
        Section("Data sources") {
            row("shippingbox.fill", "Open Beauty Facts", "Product database — used under the ODbL license.")
            row("book.fill", "American Academy of Dermatology", "Skincare guidance that informs conflict rules.")
            row("text.quote", "INCI Decoder", "Ingredient naming and function references.")
            Button {
                showContact = true
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }
        }
    }

    private func row(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.sageDeep)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://asunnyboy861.github.io/SkinStreak/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/SkinStreak/terms.html")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete all my data", systemImage: "trash.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(Theme.disclaimer)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func deleteAllData() {
        let modelTypes: [any PersistentModel.Type] = [
            UserProfile.self, Product.self, RoutineSlot.self, CheckIn.self,
            SkinReport.self, ProgressPhoto.self, ConflictLog.self, StreakState.self
        ]
        for type in modelTypes {
            try? modelContext.delete(model: type)
        }
        GLMKeyStore.clear()
        QuotaManager.shared.resetAll()
        glmKeyInput = ""
        keyStatus = nil
    }
}
