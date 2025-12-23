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

/// Promotional credit pack product identifiers (50% off welcome offer)
enum PromoCreditPack: String, CaseIterable {
    case credits100Promo = "com.flygen.credits.100.welcome"
    case credits250Promo = "com.flygen.credits.250.welcome"
    case credits500Promo = "com.flygen.credits.500.welcome"

    var creditAmount: Int {
        switch self {
        case .credits100Promo: return 100
        case .credits250Promo: return 250
        case .credits500Promo: return 500
        }
    }

    var displayName: String {
        switch self {
        case .credits100Promo: return "100 Credits"
        case .credits250Promo: return "250 Credits"
        case .credits500Promo: return "500 Credits"
        }
    }

    /// Number of generations this pack provides (10 credits per generation)
    var generationCount: Int {
        creditAmount / 10
    }

    var badge: String {
        "50% OFF"
    }

    /// The corresponding regular pack for showing original price
    var regularPack: CreditPack {
        switch self {
        case .credits100Promo: return .credits100
        case .credits250Promo: return .credits250
        case .credits500Promo: return .credits500
        }
    }
}

@MainActor
class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var promoProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress: Bool = false

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await loadPromoProducts()
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

    /// Load promotional products from App Store
    func loadPromoProducts() async {
        do {
            let promoProductIDs = PromoCreditPack.allCases.map { $0.rawValue }
            promoProducts = try await Product.products(for: promoProductIDs)
            promoProducts.sort { $0.price < $1.price }
        } catch {
            print("StoreKit: Failed to load promo products: \(error)")
            // Don't set error message - promo products are optional
        }
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

                // Get credit amount for this product (check both regular and promo packs)
                var creditsToAdd = 0
                if let creditPack = CreditPack(rawValue: product.id) {
                    creditsToAdd = creditPack.creditAmount
                } else if let promoPack = PromoCreditPack(rawValue: product.id) {
                    creditsToAdd = promoPack.creditAmount
                }

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

    /// Get promo product for a promo credit pack
    func promoProduct(for promoPack: PromoCreditPack) -> Product? {
        promoProducts.first { $0.id == promoPack.rawValue }
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
