import SwiftUI

struct VisualStyleStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable style cards
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.lg) {
                    // Header
                    FGStepHeader(
                        title: "Choose a style",
                        subtitle: "This affects typography, layout, and visual effects",
                        tooltipText: "The style sets the overall visual direction of your flyer"
                    )

                    // Style cards with descriptions
                    VStack(spacing: FGSpacing.md) {
                        ForEach(VisualStyle.allCases) { style in
                            StylePreviewCard(
                                style: style,
                                isSelected: viewModel.project?.visuals.style == style
                            ) {
                                withAnimation(FGAnimations.spring) {
                                    viewModel.project?.visuals.style = style
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

/// Large style preview card with icon, title and description
private struct StylePreviewCard: View {
    let style: VisualStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.md) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .fill(isSelected ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
                        .frame(width: 64, height: 64)

                    Image(systemName: style.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? FGColors.accentPrimary : FGColors.textSecondary)
                        .symbolEffect(.bounce, value: isSelected)
                }

                // Text content
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(style.displayName)
                        .font(FGTypography.h4)
                        .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)

                    Text(style.description)
                        .font(FGTypography.bodySmall)
                        .foregroundColor(FGColors.textTertiary)
                        .lineLimit(2)

                    // Style characteristics
                    HStack(spacing: FGSpacing.xxs) {
                        ForEach(style.characteristics.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(FGTypography.captionBold)
                                .foregroundColor(isSelected ? FGColors.accentPrimary : FGColors.textTertiary)
                                .padding(.horizontal, FGSpacing.xs)
                                .padding(.vertical, FGSpacing.xxxs)
                                .background(
                                    isSelected ? FGColors.accentPrimary.opacity(0.15) : FGColors.backgroundTertiary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(FGColors.accentPrimary)
                }
            }
            .padding(FGSpacing.cardPadding)
            .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? FGColors.accentPrimary.opacity(0.2) : .clear,
                radius: 8
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

// MARK: - VisualStyle Extensions for UI

extension VisualStyle {
    var description: String {
        switch self {
        case .modernMinimal:
            return "Clean lines, lots of white space, simple typography"
        case .boldVibrant:
            return "High contrast, saturated colors, impactful visuals"
        case .elegantLuxury:
            return "Sophisticated, refined, premium feel"
        case .retroVintage:
            return "Nostalgic charm with classic design elements"
        case .playfulFun:
            return "Bright, energetic, and approachable"
        case .corporateProfessional:
            return "Clean, trustworthy, business-appropriate"
        case .handDrawnOrganic:
            return "Natural, artistic, hand-crafted aesthetic"
        case .neonGlow:
            return "Electric, vibrant, futuristic glow effects"
        case .gradientModern:
            return "Smooth color transitions, contemporary feel"
        case .watercolorArtistic:
            return "Soft, artistic, painterly texture"
        }
    }

    var characteristics: [String] {
        switch self {
        case .modernMinimal:
            return ["Clean", "Minimal", "Sans-serif"]
        case .boldVibrant:
            return ["High contrast", "Energetic", "Eye-catching"]
        case .elegantLuxury:
            return ["Refined", "Premium", "Serif"]
        case .retroVintage:
            return ["Classic", "Nostalgic", "Textured"]
        case .playfulFun:
            return ["Colorful", "Friendly", "Rounded"]
        case .corporateProfessional:
            return ["Professional", "Clean", "Trustworthy"]
        case .handDrawnOrganic:
            return ["Artistic", "Natural", "Unique"]
        case .neonGlow:
            return ["Glowing", "Electric", "Dark mode"]
        case .gradientModern:
            return ["Smooth", "Modern", "Colorful"]
        case .watercolorArtistic:
            return ["Soft", "Painterly", "Delicate"]
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return VisualStyleStepView(viewModel: vm)
}
