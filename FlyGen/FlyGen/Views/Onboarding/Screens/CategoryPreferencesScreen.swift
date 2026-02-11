import SwiftUI

/// Screen 4: Category preferences selection - shows all 15 FlyerCategory values
struct CategoryPreferencesScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed)
            VStack(spacing: FGSpacing.sm) {
                Text("What do you create?")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Select the types you create most often")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }
            .padding(.top, FGSpacing.lg)
            .padding(.bottom, FGSpacing.md)

            // Scrollable category grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                    ForEach(FlyerCategory.allCases) { category in
                        FlyerCategoryChip(
                            category: category,
                            isSelected: viewModel.selectedFlyerCategories.contains(category),
                            isRecommended: isRecommended(category)
                        ) {
                            withAnimation(FGAnimations.spring) {
                                viewModel.toggleFlyerCategory(category)
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        .opacity(animateContent ? 1 : 0)
                        .scaleEffect(animateContent ? 1 : 0.9)
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
                .padding(.bottom, FGSpacing.lg)
            }

            // Selection count hint
            if !viewModel.selectedFlyerCategories.isEmpty {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(FGColors.accentPrimary)

                    Text("\(viewModel.selectedFlyerCategories.count) selected")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.accentSecondary)
                }
                .padding(.bottom, FGSpacing.md)
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
        }
    }

    /// Check if a category is recommended based on user role
    private func isRecommended(_ category: FlyerCategory) -> Bool {
        guard let role = viewModel.selectedUserRole else { return false }
        return role.recommendedCategories.contains(category)
    }
}

// MARK: - Category Chip

private struct FlyerCategoryChip: View {
    let category: FlyerCategory
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xs) {
                // Icon with recommended badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.accentPrimary)

                    // Recommended indicator
                    if isRecommended && !isSelected {
                        Circle()
                            .fill(FGColors.accentSecondary)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }

                Text(category.displayName)
                    .font(FGTypography.caption)
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 85)
            .background(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .fill(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(
                        isSelected ? FGColors.accentPrimary :
                            (isRecommended ? FGColors.accentSecondary.opacity(0.5) : FGColors.borderSubtle),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? FGColors.accentPrimary.opacity(0.4) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Category Preferences Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        CategoryPreferencesScreen(viewModel: OnboardingViewModel())
    }
}
