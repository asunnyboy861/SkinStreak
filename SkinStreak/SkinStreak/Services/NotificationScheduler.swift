import Foundation
import UserNotifications

enum NotificationScheduler {
    static let sundayID = "skinstreak.sunday.photo"
    static let trialID = "skinstreak.trial.end"
    static let renewalID = "skinstreak.renewal.notice"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleSundayReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [sundayID])
        var components = DateComponents()
        components.weekday = 1
        components.hour = 19
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Proof time"
        content.body = "Take this week's aligned photo so your progress stays real."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: sundayID, content: content, trigger: trigger))
    }

    static func cancelSundayReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [sundayID])
    }

    static func scheduleTrialEndNotice(end: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [trialID])
        let fireDate = end.addingTimeInterval(-24 * 3600)
        guard fireDate > Date() else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Your free trial ends tomorrow"
        content.body = "After tomorrow SkinStreak falls back to the Free tier — conflict checks, streaks and photos stay free forever."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: trialID, content: content, trigger: trigger))
    }

    static func clearTrialEndNotice() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trialID])
    }

    static func scheduleRenewalNotice(purchaseDate: Date, isYearly: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [renewalID])
        let period: TimeInterval = isYearly ? 365 * 24 * 3600 : 30 * 24 * 3600
        let fireDate = purchaseDate.addingTimeInterval(period - 24 * 3600)
        guard fireDate > Date() else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "SkinStreak Pro renews tomorrow"
        content.body = "Your subscription renews soon. Manage or cancel anytime in Settings."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: renewalID, content: content, trigger: trigger))
    }
}
