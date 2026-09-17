import Combine
import Foundation
import StoreKit

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    static let yearlyID = "com.zzoutuo.SkinStreak.pro.yearly"
    static let monthlyID = "com.zzoutuo.SkinStreak.pro.monthly"
    static let foreverID = "com.zzoutuo.SkinStreak.forever.byo"
    static let allIDs = [yearlyID, monthlyID, foreverID]

    @Published var isPro = false
    @Published var isForever = false
    @Published var products: [StoreKit.Product] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var trialEndDate: Date?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refresh()
                }
            }
        }
        Task {
            await loadProducts()
            await refresh()
        }
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await StoreKit.Product.products(for: Self.allIDs)
            loadError = products.isEmpty ? "Purchase options are unavailable right now. Try again soon." : nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    var yearlyProduct: StoreKit.Product? { products.first { $0.id == Self.yearlyID } }
    var monthlyProduct: StoreKit.Product? { products.first { $0.id == Self.monthlyID } }
    var foreverProduct: StoreKit.Product? { products.first { $0.id == Self.foreverID } }

    func purchase(_ product: StoreKit.Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                    return true
                } else {
                    loadError = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                loadError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        var pro = false
        var forever = false
        for id in Self.allIDs {
            guard let result = await StoreKit.Transaction.currentEntitlement(for: id) else { continue }
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                pro = true
                if id == Self.foreverID { forever = true }
                if id == Self.yearlyID {
                    if transaction.offerType == .introductory {
                        let end = transaction.purchaseDate.addingTimeInterval(7 * 24 * 3600)
                        trialEndDate = end
                        NotificationScheduler.scheduleTrialEndNotice(end: end)
                    } else {
                        trialEndDate = nil
                        NotificationScheduler.clearTrialEndNotice()
                    }
                    NotificationScheduler.scheduleRenewalNotice(purchaseDate: transaction.purchaseDate, isYearly: true)
                } else if id == Self.monthlyID {
                    NotificationScheduler.scheduleRenewalNotice(purchaseDate: transaction.purchaseDate, isYearly: false)
                }
            }
        }
        isPro = pro
        isForever = forever
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isPro = false
    @Published var isForever = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        EntitlementManager.shared.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
        EntitlementManager.shared.$isForever
            .receive(on: RunLoop.main)
            .assign(to: &$isForever)
    }
}
