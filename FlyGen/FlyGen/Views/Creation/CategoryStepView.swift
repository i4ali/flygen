import SwiftUI

struct CategoryStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header with guidance
                FGStepHeader(
                    title: "What are you creating?",
                    subtitle: "Choose a category that best matches your flyer's purpose",
                    tooltipText: "Categories help optimize the AI prompt for your specific use case"
                )

                // Categories grid
                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(FlyerCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            isSelected: viewModel.project?.category == category
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
