import SwiftData
import SwiftUI

@main
struct SkinStreakApp: App {
    let container: ModelContainer
    @State private var entitlements = EntitlementManager.shared

    init() {
        do {
            container = try ModelContainer(
                for: UserProfile.self, Product.self, RoutineSlot.self, CheckIn.self,
                SkinReport.self, ProgressPhoto.self, ConflictLog.self, StreakState.self
            )
        } catch {
            fatalError("Failed to create SkinStreak data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(entitlements)
                .tint(Theme.sage)
        }
    }
}
