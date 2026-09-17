import Combine
import Foundation
import Observation

@MainActor
final class QuotaManager: ObservableObject {
    static let shared = QuotaManager()
    static let weeklyFreeLimit = 2
    private static let storageKey = "skinstreak.deepscan.dates"

    var deepScanDates: [Date] {
        didSet {
            UserDefaults.standard.set(deepScanDates.map { $0.timeIntervalSince1970 }, forKey: Self.storageKey)
        }
    }

    private init() {
        let raw = UserDefaults.standard.array(forKey: Self.storageKey) as? [Double] ?? []
        deepScanDates = raw.map(Date.init(timeIntervalSince1970:))
    }

    func remainingDeepScans(isPro: Bool) -> Int {
        guard !isPro else { return Int.max }
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let used = deepScanDates.filter { $0 >= weekAgo }.count
        return max(0, Self.weeklyFreeLimit - used)
    }

    func canDeepScan(isPro: Bool) -> Bool {
        remainingDeepScans(isPro: isPro) > 0
    }

    func recordDeepScan() {
        deepScanDates.append(Date())
    }

    func resetAll() {
        deepScanDates = []
    }
}
