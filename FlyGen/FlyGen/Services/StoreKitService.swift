import StoreKit
import SwiftUI

/// Credit pack product identifiers
enum CreditPack: String, CaseIterable {
    case credits100 = "com.flygen.credits.100"
    case credits250 = "com.flygen.credits.250"
    case credits500 = "com.flygen.credits.500"

    var creditAmount: Int {
        switch self {
        case .credits100: return 100
        case .credits250: return 250
        case .credits500: return 500
        }
    }

    var displayName: String {
        switch self {
        case .credits100: return "100 Credits"
        case .credits250: return "250 Credits"
        case .credits500: return "500 Credits"
        }
    }

    /// Number of generations this pack provides (10 credits per generation)
    var generationCount: Int {
        creditAmount / 10
    }

    var badge: String? {
        switch self {
        case .credits100: return nil
        case .credits250: return "Save 20%"
        case .credits500: return "Best Value"
        }
    }
}

@MainActor
class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress: Bool = false

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = CreditPack.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreKit: Failed to load products: \(error)")
        }

        isLoading = false
    }

    /// Purchase a product
    func purchase(_ product: Product) async -> Int? {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Get credit amount for this product
                let creditPack = CreditPack(rawValue: product.id)
                let creditsToAdd = creditPack?.creditAmount ?? 0

                // Finish the transaction
                await transaction.finish()

                purchaseInProgress = false
                return creditsToAdd

            case .userCancelled:
                purchaseInProgress = false
                return nil

            case .pending:
                errorMessage = "Purchase is pending approval"
                purchaseInProgress = false
                return nil

            @unknown default:
                purchaseInProgress = false
                return nil
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("StoreKit: Purchase failed: \(error)")
            purchaseInProgress = false
            return nil
        }
    }

    /// Listen for transactions (handles interrupted purchases)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Handle the transaction on main actor
                    await MainActor.run {
                        // For consumables, we just finish the transaction
                        // Credits were already added during the purchase flow
                    }

                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Get product for a credit pack
    func product(for creditPack: CreditPack) -> Product? {
        products.first { $0.id == creditPack.rawValue }
    }

    /// Format price for display
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
}

enum StoreKitError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
