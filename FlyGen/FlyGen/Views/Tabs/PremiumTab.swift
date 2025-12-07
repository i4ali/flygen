import SwiftUI
import SwiftData
import StoreKit

struct PremiumTab: View {
    @EnvironmentObject var storeKitService: StoreKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

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

                    // Current credits
                    creditsDisplay

                    // Credit Packs
                    creditPacksSection

                    // Features list
                    featuresSection

                    Spacer(minLength: FGSpacing.xl)
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Get Credits")
            .alert("Purchase Successful!", isPresented: $showingPurchaseSuccess) {
                Button("OK", role: .cancel) { }
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

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentSecondary, FGColors.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Credit Packs")
                .font(FGTypography.displaySmall)
                .foregroundColor(FGColors.textPrimary)

            Text("Purchase credits to create\nmore AI-powered flyers")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FGSpacing.xl)
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
                ForEach(CreditPack.allCases, id: \.rawValue) { pack in
                    if let product = storeKitService.product(for: pack) {
                        CreditPackCard(
                            pack: pack,
                            product: product,
                            isLoading: storeKitService.purchaseInProgress
                        ) {
                            await purchaseCredits(product: product, pack: pack)
                        }
                    }
                }
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

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            Text("What You Get")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.sm) {
                FeatureRow(icon: "wand.and.stars", title: "AI-Powered Design", description: "Professional flyers in seconds")
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited Refinements", description: "Perfect your design with feedback")
                FeatureRow(icon: "icloud", title: "Cloud Sync", description: "Access flyers on all your devices")
                FeatureRow(icon: "square.and.arrow.up", title: "Easy Sharing", description: "Share directly to social media")
            }
        }
        .padding(.vertical, FGSpacing.md)
    }

    // MARK: - Purchase Action

    private func purchaseCredits(product: Product, pack: CreditPack) async {
        if let creditsAdded = await storeKitService.purchase(product) {
            // Add credits to user profile
            if let profile = userProfiles.first {
                profile.credits += creditsAdded
                profile.lastSyncedAt = Date()
                try? modelContext.save()

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

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(FGColors.accentPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                Text(title)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)

                Text(description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(FGColors.success)
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }
}

#Preview {
    PremiumTab()
        .environmentObject(StoreKitService())
}
