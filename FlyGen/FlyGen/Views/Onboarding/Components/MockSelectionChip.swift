import SwiftUI

/// Compact selection chip for onboarding interactive demo
struct MockSelectionChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                Text(emoji)
                    .font(.system(size: 18))

                Text(title)
                    .font(FGTypography.label)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
            }
            .padding(.horizontal, FGSpacing.md)
            .padding(.vertical, FGSpacing.sm)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0
            )
        }
        .buttonStyle(FGCardButtonStyle())
        .animation(FGAnimations.spring, value: isSelected)
    }

    private var chipBackground: some View {
        Group {
            if isSelected {
                FGColors.surfaceSelected
            } else {
                FGColors.surfaceDefault
            }
        }
    }
}

/// Category chip for the demo
struct CategoryChip: View {
    let category: OnboardingViewModel.MockCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        MockSelectionChip(
            title: category.rawValue,
            emoji: category.emoji,
            isSelected: isSelected,
            action: action
        )
    }
}

/// Style chip for the demo
struct StyleChip: View {
    let style: OnboardingViewModel.MockStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        MockSelectionChip(
            title: style.rawValue,
            emoji: style.emoji,
            isSelected: isSelected,
            action: action
        )
    }
}

#Preview("Mock Selection Chips") {
    VStack(spacing: FGSpacing.lg) {
        Text("Category Chips")
            .font(FGTypography.label)
            .foregroundColor(FGColors.textSecondary)

        HStack(spacing: FGSpacing.sm) {
            MockSelectionChip(title: "Event", emoji: "📅", isSelected: true) {}
            MockSelectionChip(title: "Sale", emoji: "🏷️", isSelected: false) {}
            MockSelectionChip(title: "News", emoji: "📢", isSelected: false) {}
        }

        Text("Style Chips")
            .font(FGTypography.label)
            .foregroundColor(FGColors.textSecondary)

        HStack(spacing: FGSpacing.sm) {
            MockSelectionChip(title: "Modern", emoji: "◼️", isSelected: false) {}
            MockSelectionChip(title: "Bold", emoji: "🔥", isSelected: true) {}
            MockSelectionChip(title: "Elegant", emoji: "✨", isSelected: false) {}
        }
    }
    .padding()
    .background(FGColors.backgroundPrimary)
}
