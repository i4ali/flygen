import SwiftUI
import SwiftData

struct CategoryStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Query private var userProfiles: [UserProfile]

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    /// Categories sorted with user's preferred categories first
    private var sortedCategories: [FlyerCategory] {
        let preferredCategories = userProfiles.first?.preferredFlyerCategories ?? []

        if preferredCategories.isEmpty {
            return FlyerCategory.allCases
        }

        // Preferred categories first, then remaining in original order
        let preferred = preferredCategories.filter { FlyerCategory.allCases.contains($0) }
        let others = FlyerCategory.allCases.filter { !preferred.contains($0) }
        return preferred + others
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header with guidance
                FGStepHeader(
                    title: "What are you creating?",
                    subtitle: "Choose a category that best matches your flyer's purpose",
                    tooltipText: "Categories help optimize the AI prompt for your specific use case"
                )

                // Categories grid (sorted with preferred first)
                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(sortedCategories) { category in
                        CategoryCard(
                            category: category,
                            isSelected: viewModel.project?.category == category,
                            isPreferred: userProfiles.first?.preferredFlyerCategories.contains(category) ?? false
                        ) {
                            viewModel.startNewFlyer(category: category)
                        }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
    }
}

/// Category selection card with emoji and icon
private struct CategoryCard: View {
    let category: FlyerCategory
    let isSelected: Bool
    let isPreferred: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.sm) {
                // Emoji with subtle background
                ZStack {
                    Circle()
                        .fill(isSelected ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
                        .frame(width: 56, height: 56)

                    Text(category.emoji)
                        .font(.system(size: 28))

                    // Star indicator for preferred categories
                    if isPreferred && !isSelected {
                        Circle()
                            .fill(FGColors.accentSecondary)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 20, y: -20)
                    }
                }

                VStack(spacing: FGSpacing.xxxs) {
                    Text(category.displayName)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(height: 110)
        }
    }
}

#Preview {
    CategoryStepView(viewModel: FlyerCreationViewModel())
}
