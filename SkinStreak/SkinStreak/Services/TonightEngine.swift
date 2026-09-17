import Foundation

nonisolated enum SkinCycleNight: String, CaseIterable {
    case exfoliation
    case retinoid
    case recovery

    var displayName: String {
        switch self {
        case .exfoliation: "Exfoliation night"
        case .retinoid: "Retinoid night"
        case .recovery: "Recovery night"
        }
    }
}

struct SlotPlan: Identifiable, Equatable {
    let id = UUID()
    var productName: String
    var actives: [String]
    var isSeparated: Bool
    var note: String
    var order: Int
}

enum TonightEngine {
    static func cycleNight(for date: Date, startedAt: Date) -> SkinCycleNight {
        let days = Calendar.current.dateComponents(
            [.day],
            from: startOfDay(startedAt),
            to: startOfDay(date)
        ).day ?? 0
        let index = ((days % 4) + 4) % 4
        switch index {
        case 0: return .exfoliation
        case 1: return .retinoid
        default: return .recovery
        }
    }

    static func buildSlots(for date: Date, session: String, cycleNight: SkinCycleNight, products: [Product]) -> [SlotPlan] {
        var plans: [SlotPlan] = []
        var order = 0
        for product in products.sorted(by: { $0.addedAt < $1.addedAt }) {
            let families = ConflictEngine.families(in: product.actives)
            guard slotAllowed(session: session, night: cycleNight, families: families, avoidSession: product.avoidSession) else { continue }
            let separated = !product.avoidSession.isEmpty && product.avoidSession == session
            plans.append(SlotPlan(
                productName: product.name,
                actives: product.actives,
                isSeparated: separated,
                note: separated ? product.avoidNote : "",
                order: order
            ))
            order += 1
        }
        return plans
    }

    private static func slotAllowed(session: String, night: SkinCycleNight, families: Set<String>, avoidSession: String) -> Bool {
        if !avoidSession.isEmpty {
            return avoidSession == session
        }
        let exfoliants = families.contains("aha") || families.contains("bha") || families.contains("pha") || families.contains("enzyme") || families.contains("tca")
        let retinoids = families.contains("retinol_family") || families.contains("tretinoin") || families.contains("adapalene")
        let treatments = families.contains("bpo") || families.contains("sulfur")

        if session == "AM" {
            return !(exfoliants || retinoids)
        }

        let gentle = !(exfoliants || retinoids)
        switch night {
        case .exfoliation: return exfoliants || gentle
        case .retinoid: return retinoids || treatments || gentle
        case .recovery: return treatments || gentle
        }
    }

    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
