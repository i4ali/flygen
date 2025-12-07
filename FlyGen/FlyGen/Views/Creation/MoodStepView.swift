import SwiftUI

struct MoodStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.lg) {
                    // Header
                    FGStepHeader(
                        title: "Set the mood",
                        subtitle: "This affects colors, imagery, and overall feel of your flyer",
                        tooltipText: "Mood influences the emotional tone and visual atmosphere"
                    )

                    // Mood grid with gradient cards
                    LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                        ForEach(Mood.allCases) { mood in
                            MoodCard(
                                mood: mood,
                                isSelected: viewModel.project?.visuals.mood == mood
                            ) {
                                withAnimation(FGAnimations.spring) {
                                    viewModel.project?.visuals.mood = mood
                                }
                            }
                        }
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }
                .padding(.vertical, FGSpacing.lg)
            }
        }
        .background(FGColors.backgroundPrimary)
    }
}

/// Mood selection card with gradient circle
private struct MoodCard: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xs) {
                // Mood-colored gradient circle with icon
                ZStack {
                    Circle()
                        .fill(FGGradients.moodGradient(for: mood.rawValue))
                        .frame(width: 52, height: 52)
                        .shadow(
                            color: isSelected ? moodColor.opacity(0.5) : .clear,
                            radius: 8
                        )

                    Image(systemName: mood.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: isSelected)
                }

                Text(mood.shortName)
                    .font(FGTypography.label)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.sm)
            .padding(.horizontal, FGSpacing.xs)
            .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(FGAnimations.spring, value: isSelected)
    }

    private var moodColor: Color {
        switch mood {
        case .urgent: return .red
        case .exciting: return .orange
        case .calm: return .cyan
        case .elegant: return .purple
        case .friendly: return .green
        case .professional: return .blue
        case .festive: return .pink
        case .serious: return .gray
        case .inspirational: return .orange
        case .romantic: return .pink
        case .somber: return .gray
        }
    }
}

// MARK: - Mood Extension for short name

extension Mood {
    var shortName: String {
        switch self {
        case .urgent: return "Urgent"
        case .exciting: return "Exciting"
        case .calm: return "Calm"
        case .elegant: return "Elegant"
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        case .festive: return "Festive"
        case .serious: return "Serious"
        case .inspirational: return "Inspiring"
        case .romantic: return "Romantic"
        case .somber: return "Somber"
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return MoodStepView(viewModel: vm)
}
