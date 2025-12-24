import SwiftUI
import SwiftData
import StoreKit

struct CreditPurchaseSheet: View {
    @EnvironmentObject var storeKitService: StoreKitService
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    /// When true, shows promotional 50% off products instead of regular products
    var isPromoMode: Bool = false

    @State private var showingPurchaseSuccess = false
    @State private var purchasedCredits: Int = 0

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
                    // Header
                    headerSection

                    // Value comparison
                    valueComparisonSection

                    // Current credits
                    creditsDisplay

                    // Credit Packs
                    creditPacksSection

                    Spacer(minLength: FGSpacing.xl)
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Get Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(FGColors.textTertiary)
                    }
                }
            }
            .alert("Purchase Successful!", isPresented: $showingPurchaseSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("You've received \(purchasedCredits) credits. Happy creating!")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: FGSpacing.md) {
            ZStack {
                Circle()
                    .fill(FGColors.accentSecondary.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Image(systemName: isPromoMode ? "gift.fill" : "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentSecondary, FGColors.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            if isPromoMode {
                Text("50% OFF")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Welcome Offer")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)

                Text("One-time discount for new users\nClaim before this offer expires!")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Credit Packs")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)

                Text("Purchase credits to create\nmore AI-powered flyers")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, FGSpacing.lg)
    }

    // MARK: - Value Comparison Section

    private var valueComparisonSection: some View {
        VStack(spacing: FGSpacing.sm) {
            Text("Why FlyGen?")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: FGSpacing.xs) {
                ComparisonRow(
                    icon: "person.fill",
                    title: "Hire a Designer",
                    subtitle: "$150-500+ per flyer",
                    highlight: nil,
                    isExpensive: true
                )

                ComparisonRow(
                    icon: "paintbrush.fill",
                    title: "Canva Pro",
                    subtitle: "$12.99/mo + hours of work",
                    highlight: nil,
                    isExpensive: true
                )

                ComparisonRow(
                    icon: "clock.fill",
                    title: "DIY Design",
                    subtitle: "3-5 hours of your time",
                    highlight: nil,
                    isExpensive: true
                )

                ComparisonRow(
                    icon: "sparkles",
                    title: "FlyGen",
                    subtitle: "Done in 30 seconds",
                    highlight: isPromoMode ? "From $0.05/flyer" : "From $0.10/flyer",
                    isExpensive: false
                )
            }
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Credits Display

    private var creditsDisplay: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: "sparkles")
                .foregroundColor(FGColors.accentSecondary)
            Text("Current Credits:")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
            Text("\(credits)")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)
        }
        .padding(FGSpacing.md)
        .frame(maxWidth: .infinity)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.accentSecondary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Credit Packs Section

    private var creditPacksSection: some View {
        VStack(spacing: FGSpacing.md) {
            if storeKitService.isLoading {
                VStack(spacing: FGSpacing.sm) {
                    ProgressView()
                        .tint(FGColors.accentPrimary)
                    Text("Loading products...")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.xl)
            } else if isPromoMode {
                // Promo mode - show discounted products
                if storeKitService.promoProducts.isEmpty {
                    // Fallback to regular products if promo products not available
                    regularProductsList
                } else {
                    promoProductsList
                }
            } else if storeKitService.products.isEmpty {
                VStack(spacing: FGSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(FGColors.warning)

                    Text("Unable to load products")
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    Text("Please check your connection and try again")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)

                    Button {
                        Task {
                            await storeKitService.loadProducts()
                        }
                    } label: {
                        Text("Retry")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.accentPrimary)
                            .padding(.horizontal, FGSpacing.lg)
                            .padding(.vertical, FGSpacing.sm)
                            .background(FGColors.surfaceDefault)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(FGColors.accentPrimary, lineWidth: 1)
                            )
                    }
                }
                .padding(FGSpacing.lg)
            } else {
                regularProductsList
            }

            if let error = storeKitService.errorMessage {
                Text(error)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.error)
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    private var regularProductsList: some View {
        ForEach(CreditPack.allCases, id: \.rawValue) { pack in
            if let product = storeKitService.product(for: pack) {
                CreditPackCard(
                    pack: pack,
                    product: product,
                    isLoading: storeKitService.purchaseInProgress
                ) {
                    await purchaseCredits(product: product, creditAmount: pack.creditAmount)
                }
            }
        }
    }

    private var promoProductsList: some View {
        ForEach(PromoCreditPack.allCases, id: \.rawValue) { promoPack in
            if let promoProduct = storeKitService.promoProduct(for: promoPack) {
                let regularProduct = storeKitService.product(for: promoPack.regularPack)
                PromoCreditPackCard(
                    promoPack: promoPack,
                    promoProduct: promoProduct,
                    originalPrice: regularProduct?.displayPrice,
                    isLoading: storeKitService.purchaseInProgress
                ) {
                    await purchaseCredits(product: promoProduct, creditAmount: promoPack.creditAmount)
                }
            }
        }
    }

    // MARK: - Purchase Action

    private func purchaseCredits(product: Product, creditAmount: Int) async {
        if let creditsAdded = await storeKitService.purchase(product) {
            // Add credits to user profile
            if let profile = userProfiles.first {
                profile.credits += creditsAdded
                profile.lastSyncedAt = Date()
                try? modelContext.save()

                // Sync credits to CloudKit
                await cloudKitService.saveCredits(profile.credits)

                // Cancel scheduled notification since credits restored
                notificationService.onCreditsChanged(newCredits: profile.credits)

                purchasedCredits = creditsAdded
                showingPurchaseSuccess = true
            }
        }
    }
}

// MARK: - Credit Pack Card

struct CreditPackCard: View {
    let pack: CreditPack
    let product: Product
    let isLoading: Bool
    let onPurchase: () async -> Void

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            // Credits amount
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                HStack(spacing: FGSpacing.sm) {
                    Text(pack.displayName)
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    if let badge = pack.badge {
                        Text(badge)
                            .font(FGTypography.captionBold)
                            .foregroundColor(FGColors.textOnAccent)
                            .padding(.horizontal, FGSpacing.sm)
                            .padding(.vertical, FGSpacing.xxxs)
                            .background(FGColors.warning)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                    }
                }

                Text(product.description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            // Price button
            Button {
                Task {
                    await onPurchase()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(FGColors.textOnAccent)
                        .frame(width: 80)
                } else {
                    Text(product.displayPrice)
                        .font(FGTypography.buttonLarge)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(width: 80)
                        .padding(.vertical, FGSpacing.sm)
                        .background(FGColors.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                }
            }
            .disabled(isLoading)
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Promo Credit Pack Card

struct PromoCreditPackCard: View {
    let promoPack: PromoCreditPack
    let promoProduct: Product
    let originalPrice: String?
    let isLoading: Bool
    let onPurchase: () async -> Void

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            // Credits amount
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                HStack(spacing: FGSpacing.sm) {
                    Text(promoPack.displayName)
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    Text(promoPack.badge)
                        .font(FGTypography.captionBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, FGSpacing.sm)
                        .padding(.vertical, FGSpacing.xxxs)
                        .background(
                            LinearGradient(
                                colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                }

                Text(promoProduct.description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            // Price section with strikethrough original price
            VStack(alignment: .trailing, spacing: 2) {
                if let originalPrice = originalPrice {
                    Text(originalPrice)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .strikethrough()
                }

                Button {
                    Task {
                        await onPurchase()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(FGColors.textOnAccent)
                            .frame(width: 80)
                    } else {
                        Text(promoProduct.displayPrice)
                            .font(FGTypography.buttonLarge)
                            .foregroundColor(.white)
                            .frame(width: 80)
                            .padding(.vertical, FGSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                }
                .disabled(isLoading)
            }
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [FGColors.accentPrimary.opacity(0.5), FGColors.accentSecondary.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let highlight: String?
    let isExpensive: Bool

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isExpensive ? FGColors.textTertiary : FGColors.accentSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: FGSpacing.xs) {
                    Text(title)
                        .font(FGTypography.bodyBold)
                        .foregroundColor(isExpensive ? FGColors.textSecondary : FGColors.textPrimary)

                    if isExpensive {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(FGColors.error.opacity(0.7))
                    }
                }

                Text(subtitle)
                    .font(FGTypography.caption)
                    .foregroundColor(isExpensive ? FGColors.textTertiary : FGColors.textSecondary)
            }

            Spacer()

            if let highlight = highlight {
                Text(highlight)
                    .font(FGTypography.captionBold)
                    .foregroundColor(FGColors.success)
                    .padding(.horizontal, FGSpacing.sm)
                    .padding(.vertical, FGSpacing.xxxs)
                    .background(FGColors.success.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
            }
        }
        .padding(.vertical, FGSpacing.xs)
        .padding(.horizontal, FGSpacing.sm)
        .background(isExpensive ? Color.clear : FGColors.accentSecondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
    }
}

#Preview {
    CreditPurchaseSheet()
        .environmentObject(StoreKitService())
        .environmentObject(CloudKitService())
        .environmentObject(NotificationService())
}
