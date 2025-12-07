import SwiftUI

struct FormatStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.xl) {
                    // Header
                    FGStepHeader(
                        title: "Select format",
                        subtitle: "Choose the aspect ratio for your flyer",
                        tooltipText: "Different formats work best for different platforms"
                    )

                    // Aspect ratio section
                    VStack(alignment: .leading, spacing: FGSpacing.md) {
                        Text("Aspect Ratio")
                            .font(FGTypography.h3)
                            .foregroundColor(FGColors.textPrimary)
                            .padding(.horizontal, FGSpacing.screenHorizontal)

                        LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                            ForEach(AspectRatio.allCases) { ratio in
                                AspectRatioCard(
                                    ratio: ratio,
                                    isSelected: viewModel.project?.output.aspectRatio == ratio
                                ) {
                                    withAnimation(FGAnimations.spring) {
                                        viewModel.project?.output.aspectRatio = ratio
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                    }

                    // Divider
                    Rectangle()
                        .fill(FGColors.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Text rendering mode section
                    VStack(alignment: .leading, spacing: FGSpacing.md) {
                        HStack {
                            Text("Text Rendering")
                                .font(FGTypography.h3)
                                .foregroundColor(FGColors.textPrimary)

                            FGTooltip(text: "Choose how text appears in the generated image")
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                        VStack(spacing: FGSpacing.sm) {
                            ForEach([ImageryType.illustrated, ImageryType.noText]) { type in
                                TextRenderingCard(
                                    type: type,
                                    isSelected: viewModel.project?.visuals.imageryType == type
                                ) {
                                    withAnimation(FGAnimations.spring) {
                                        viewModel.project?.visuals.imageryType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                    }
                }
                .padding(.vertical, FGSpacing.lg)
            }
        }
        .background(FGColors.backgroundPrimary)
    }
}

/// Text rendering option card
private struct TextRenderingCard: View {
    let type: ImageryType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .fill(isSelected ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? FGColors.accentPrimary : FGColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                    Text(type == .illustrated ? "AI Rendered Text" : "Text-Free Design")
                        .font(FGTypography.labelLarge)
                        .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)

                    Text(type == .illustrated ? "AI generates text directly in the image" : "Clean design for adding text in Canva/Photoshop")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
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
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return FormatStepView(viewModel: vm)
}
