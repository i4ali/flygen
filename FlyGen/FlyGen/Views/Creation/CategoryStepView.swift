import SwiftUI
import SwiftData

struct CategoryStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        if viewModel.selectedIntent == nil {
            IntentSelectionContent(viewModel: viewModel, userProfiles: userProfiles)
        } else {
            OutputTypeSelectionContent(viewModel: viewModel, userProfiles: userProfiles)
        }
    }
}

// MARK: - Step 1: Intent Selection

private struct IntentSelectionContent: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    let userProfiles: [UserProfile]

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    /// Intents sorted by how many of their OutputTypes match user preferences
    private var sortedIntents: [Intent] {
        let preferredCategories = userProfiles.first?.preferredFlyerCategories ?? []

        if preferredCategories.isEmpty {
            return Intent.allCases
        }

        return Intent.allCases.sorted { intent1, intent2 in
            let count1 = intent1.outputTypes.filter { preferredCategories.contains($0.category) }.count
            let count2 = intent2.outputTypes.filter { preferredCategories.contains($0.category) }.count
            return count1 > count2
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                FGStepHeader(
                    title: "What's your goal?",
                    subtitle: "Choose what you want to achieve",
                    tooltipText: "Your goal helps us show you the most relevant flyer types"
                )

                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(sortedIntents) { intent in
                        IntentCard(intent: intent) {
                            viewModel.selectIntent(intent)
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

/// Intent selection card with emoji, title, and subtitle
private struct IntentCard: View {
    let intent: Intent
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: false, action: action) {
            VStack(spacing: FGSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(FGColors.backgroundTertiary)
                        .frame(width: 56, height: 56)

                    Text(intent.emoji)
                        .font(.system(size: 28))
                }

                VStack(spacing: FGSpacing.xxxs) {
                    Text(intent.displayName)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)

                    Text(intent.subtitle)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(height: 130)
        }
    }
}

// MARK: - Step 2: Output Type Selection (Filtered by Intent)

private struct OutputTypeSelectionContent: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    let userProfiles: [UserProfile]

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    /// Output types filtered by selected intent (or all if showAllOutputTypes is true)
    private var filteredOutputTypes: [OutputType] {
        guard let intent = viewModel.selectedIntent else { return [] }

        let outputTypes = viewModel.showAllOutputTypes ? OutputType.allCases : intent.outputTypes
        let preferredCategories = userProfiles.first?.preferredFlyerCategories ?? []

        if preferredCategories.isEmpty {
            return outputTypes
        }

        // Sort with preferred categories first
        let preferred = outputTypes.filter { preferredCategories.contains($0.category) }
        let others = outputTypes.filter { !preferredCategories.contains($0.category) }
        return preferred + others
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.lg) {
                // Header showing selected intent
                if let intent = viewModel.selectedIntent {
                    FGStepHeader(
                        title: "\(intent.emoji) \(intent.displayName)",
                        subtitle: "Choose your flyer type",
                        tooltipText: "Each type is optimized for your specific use case"
                    )
                }

                // Output types grid
                LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                    ForEach(filteredOutputTypes) { outputType in
                        OutputTypeCard(
                            outputType: outputType,
                            isSelected: viewModel.project?.category == outputType.category,
                            isPreferred: userProfiles.first?.preferredFlyerCategories.contains(outputType.category) ?? false
                        ) {
                            viewModel.startNewFlyer(category: outputType.category)
                        }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)

                // Show All Types toggle (only when filtered)
                if !viewModel.showAllOutputTypes {
                    Button {
                        viewModel.toggleShowAllTypes()
                    } label: {
                        HStack {
                            Text("Show All Types")
                                .font(FGTypography.body)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(FGColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
    }
}

/// Output type selection card with emoji and display name
private struct OutputTypeCard: View {
    let outputType: OutputType
    let isSelected: Bool
    let isPreferred: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
                        .frame(width: 56, height: 56)

                    Text(outputType.emoji)
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
                    Text(outputType.displayName)
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
