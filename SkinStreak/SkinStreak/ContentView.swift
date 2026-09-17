import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            if profile.onboardingCompleted {
                RootTabView()
            } else {
                OnboardingView(profile: profile)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.sand.ignoresSafeArea())
                .task {
                    modelContext.insert(UserProfile())
                }
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Tonight", systemImage: "flame.fill") }
            CabinetView()
                .tabItem { Label("Cabinet", systemImage: "shippingbox.fill") }
            ProofView()
                .tabItem { Label("Proof", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
