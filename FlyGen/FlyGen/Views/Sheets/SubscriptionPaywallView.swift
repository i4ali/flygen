import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @EnvironmentObject var entitlementService: EntitlementService
    @Environment(\.dismiss) var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://i4ali.github.io/flygen/privacy-policy.html")!

    // MARK: - Computed

    private var resolvedSelected: Product? {
        selectedProduct
            ?? entitlementService.products.first { $0.id == SubscriptionConfig.Product.monthly }
            ?? entitlementService.products.first
    }

    private var isLoading: Bool {
        entitlementService.products.isEmpty && !entitlementService.didAttemptProductLoad
    }

    private var loadFailed: Bool {
        entitlementService.products.isEmpty && entitlementService.didAttemptProductLoad
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
                    heroSection
                    featureList
                    planSelector
                    subscribeButton
                    restoreButton
                    disclosureText
                    legalLinks
                    Spacer(minLength: FGSpacing.xl)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("")
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
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: FGSpacing.md) {
            ZStack {
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Image(systemName: "crown.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("FlyGen Premium")
                .font(FGTypography.displaySmall)
                .foregroundColor(FGColors.textPrimary)

            Text("Create flyers all month long")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FGSpacing.lg)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: FGSpacing.sm) {
            FeatureRow(icon: "sparkles", text: "AI flyer generations, reset each period")
            FeatureRow(icon: "wand.and.stars", text: "Refine & resize your flyers")
            FeatureRow(icon: "globe", text: "All styles, formats & languages")
            FeatureRow(icon: "arrow.clockwise", text: "Quota resets every billing period")
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Plan Selector

    @ViewBuilder
    private var planSelector: some View {
        if isLoading {
            VStack(spacing: FGSpacing.sm) {
                ProgressView()
                    .tint(FGColors.accentPrimary)
                Text("Loading plans...")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.xl)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        } else if loadFailed {
            VStack(spacing: FGSpacing.sm) {
                Text("Couldn't load plans")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                Text("Check your connection and try again.")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await entitlementService.loadProducts() }
                } label: {
                    Text("Retry")
                        .font(FGTypography.button)
                        .foregroundColor(FGColors.accentPrimary)
                }
                .padding(.top, FGSpacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.xl)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        } else {
            VStack(spacing: FGSpacing.sm) {
                ForEach(entitlementService.products, id: \.id) { product in
                    PlanCard(
                        product: product,
                        isSelected: resolvedSelected?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            guard let product = resolvedSelected else { return }
            isPurchasing = true
            Task {
                defer { isPurchasing = false }
                if (try? await entitlementService.purchase(product)) == true
                    || entitlementService.isSubscribed
                {
                    dismiss()
                }
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(FGColors.textOnAccent)
                } else {
                    Text("Subscribe")
                        .font(FGTypography.buttonLarge)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.md)
            .foregroundColor(FGColors.textOnAccent)
            .background(
                entitlementService.products.isEmpty
                    ? AnyShapeStyle(FGColors.textTertiary)
                    : AnyShapeStyle(LinearGradient(
                        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
        }
        .disabled(entitlementService.products.isEmpty || isPurchasing || isRestoring)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            isRestoring = true
            Task {
                defer { isRestoring = false }
                await entitlementService.restore()
                if entitlementService.isSubscribed {
                    dismiss()
                }
            }
        } label: {
            if isRestoring {
                ProgressView()
                    .tint(FGColors.accentPrimary)
            } else {
                Text("Restore Purchases")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.accentPrimary)
            }
        }
        .disabled(isPurchasing || isRestoring)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: FGSpacing.sm) {
            Link("Terms of Use", destination: termsURL)
            Text("-")
                .foregroundColor(FGColors.textTertiary)
            Link("Privacy Policy", destination: privacyURL)
        }
        .font(FGTypography.caption)
        .foregroundColor(FGColors.textTertiary)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Disclosure

    private var subscriptionDescription: String {
        guard let product = resolvedSelected else { return "" }
        let unitText: String
        switch product.subscription?.subscriptionPeriod.unit {
        case .day?: unitText = "day"
        case .week?: unitText = "week"
        case .month?: unitText = "month"
        case .year?: unitText = "year"
        default: unitText = "period"
        }
        return "\(product.displayName) is \(product.displayPrice) per \(unitText)."
    }

    private var disclosureText: some View {
        VStack(spacing: FGSpacing.xs) {
            if !subscriptionDescription.isEmpty {
                Text(subscriptionDescription)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }
            Text("Payment will be charged to your Apple Account at confirmation of purchase. The subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage or cancel your subscription anytime in your App Store account settings.")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)

            Text(text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    private var isMonthly: Bool {
        product.id == SubscriptionConfig.Product.monthly
    }

    private var allotmentText: String {
        switch product.id {
        case SubscriptionConfig.Product.weekly:  return "\(SubscriptionConfig.weeklyQuota) flyers / week"
        case SubscriptionConfig.Product.monthly: return "\(SubscriptionConfig.monthlyQuota) flyers / month"
        default: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FGSpacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? FGColors.accentPrimary : FGColors.textTertiary)

                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack(spacing: FGSpacing.xs) {
                        Text(product.displayName)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        if isMonthly {
                            Text("Best Value")
                                .font(FGTypography.captionBold)
                                .foregroundColor(FGColors.textOnAccent)
                                .padding(.horizontal, FGSpacing.sm)
                                .padding(.vertical, FGSpacing.xxxs)
                                .background(FGColors.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                        }
                    }

                    if !allotmentText.isEmpty {
                        Text(allotmentText)
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textSecondary)
                    }

                    Text(product.description.isEmpty ? product.displayPrice : product.description)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(FGTypography.h4)
                    .foregroundColor(FGColors.textPrimary)
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(
                        isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionPaywallView()
        .environmentObject(EntitlementService())
}
