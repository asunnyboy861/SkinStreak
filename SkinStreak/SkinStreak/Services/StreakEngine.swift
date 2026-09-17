import Foundation

enum SettleOutcome: Equatable {
    case continued(streak: Int)
    case freezeUsed(streak: Int)
    case restarted

    var isBreakDay: Bool {
        if case .restarted = self { return true }
        return false
    }
}

enum StreakEngine {
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func monthlyResetIfNeeded(_ state: StreakState, now: Date = Date()) {
        let key = monthKey(now)
        if state.freezeMonthKey != key {
            state.freezeMonthKey = key
            state.freezesLeft = 2
        }
    }

    static func settle(state: StreakState, now: Date = Date()) -> SettleOutcome {
        monthlyResetIfNeeded(state, now: now)
        let today = startOfDay(now)
        guard state.lastCheckInDay != today else {
            return .continued(streak: state.current)
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let outcome: SettleOutcome

        if let last = state.lastCheckInDay, startOfDay(last) == yesterday {
            state.current += 1
            outcome = .continued(streak: state.current)
        } else if state.lastCheckInDay != nil, state.freezesLeft > 0 {
            state.freezesLeft -= 1
            state.current += 1
            outcome = .freezeUsed(streak: state.current)
        } else {
            state.current = 1
            outcome = .restarted
        }

        state.lastCheckInDay = today
        state.longest = max(state.longest, state.current)
        return outcome
    }

    static func monthKey(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }
}
