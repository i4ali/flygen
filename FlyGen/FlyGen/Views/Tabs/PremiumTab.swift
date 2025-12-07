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
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Current credits
                    creditsDisplay

                    // Credit Packs
                    creditPacksSection

                    // Features list
                    featuresSection

                    Spacer(minLength: 40)
                }
            }
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
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Credit Packs")
                .font(.title)
                .fontWeight(.bold)

            Text("Purchase credits to create\nmore AI-powered flyers")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    // MARK: - Credits Display

    private var creditsDisplay: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
            Text("Current Credits: \(credits)")
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Credit Packs Section

    private var creditPacksSection: some View {
        VStack(spacing: 16) {
            if storeKitService.isLoading {
                ProgressView("Loading products...")
                    .padding()
            } else if storeKitService.products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Unable to load products")
                        .font(.headline)
                    Text("Please check your connection and try again")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await storeKitService.loadProducts()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
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
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You Get")
                .font(.headline)
                .padding(.horizontal)

            FeatureRow(icon: "wand.and.stars", title: "AI-Powered Design", description: "Professional flyers in seconds")
            FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited Refinements", description: "Perfect your design with feedback")
            FeatureRow(icon: "icloud", title: "Cloud Sync", description: "Access flyers on all your devices")
            FeatureRow(icon: "square.and.arrow.up", title: "Easy Sharing", description: "Share directly to social media")
        }
        .padding(.vertical)
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
        HStack(spacing: 16) {
            // Credits amount
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pack.displayName)
                        .font(.headline)
                        .fontWeight(.bold)

                    if let badge = pack.badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                        .frame(width: 80)
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.horizontal)
    }
}

#Preview {
    PremiumTab()
        .environmentObject(StoreKitService())
}
