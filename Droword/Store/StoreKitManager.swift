import Foundation
import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    static let monthlyID = "com.droword.pro.monthly"
    static let yearlyID  = "com.droword.pro.yearly"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    var isPurchased: Bool { !purchasedProductIDs.isEmpty }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product?  { products.first { $0.id == Self.yearlyID } }

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        do {
            let fetched = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            #if DEBUG
            print("⚠️ StoreKit: Failed to load products: \(error.localizedDescription)")
            #endif
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? Self.checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased

        let hasPurchase = !purchased.isEmpty
        UserDefaults.standard.set(hasPurchase, forKey: "hasRealPurchase")

        if hasPurchase {
            UserDefaults.standard.set(true, forKey: "isPremium")
        } else if UserDefaults.standard.bool(forKey: "hasRealPurchase") == false {
            
            let hasUsedTrial = UserDefaults.standard.bool(forKey: "hasUsedTrial")
            let trialStart = UserDefaults.standard.string(forKey: "trialStartDate") ?? ""
            if hasUsedTrial, !trialStart.isEmpty, let start = DateFormatting.dayFormatter.date(from: trialStart) {
                let daysSince = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
                if daysSince > 7 {
                    UserDefaults.standard.set(false, forKey: "isPremium")
                }
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? Self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
