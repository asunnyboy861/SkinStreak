import Foundation
import SwiftData

@Model
final class UserProfile {
    var skinType: String = "combination"
    var goal: String = "General glow"
    var fitzpatrick: Int = 3
    var onboardingCompleted: Bool = false
    var sundayReminderEnabled: Bool = true
    var cyclingStartedAt: Date = Date()
    var createdAt: Date = Date()

    init(skinType: String = "combination", goal: String = "General glow", fitzpatrick: Int = 3) {
        self.skinType = skinType
        self.goal = goal
        self.fitzpatrick = fitzpatrick
    }
}
