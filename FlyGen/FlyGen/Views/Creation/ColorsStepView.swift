import SwiftUI

struct ColorsStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.xl) {
                    // Header
                    FGStepHeader(
                        title: "Pick colors",
                        subtitle: "Choose a color palette and background style",
                        tooltipText: "Colors set the visual tone and help convey your message"
                    )

                    // Color palette section - horizontal scroll
                    VStack(alignment: .leading, spacing: FGSpacing.md) {
                        HStack {
                            Text("Color Palette")
                                .font(FGTypography.h3)
                                .foregroundColor(FGColors.textPrimary)

                            Spacer()
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                        // Horizontal scroll of large palette cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FGSpacing.md) {
                                ForEach(ColorSchemePreset.allCases) { preset in
                                    LargeColorPaletteCard(
                                        preset: preset,
                                        isSelected: viewModel.project?.colors.preset == preset
                                    ) {
                                        withAnimation(FGAnimations.spring) {
                                            viewModel.project?.colors.preset = preset
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, FGSpacing.screenHorizontal)
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(FGColors.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    // Background type section
                    VStack(alignment: .leading, spacing: FGSpacing.md) {
                        HStack {
                            Text("Background Style")
                                .font(FGTypography.h3)
                                .foregroundColor(FGColors.textPrimary)

                            FGTooltip(text: "Controls how the background of your flyer appears")

                            Spacer()
                        }
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                        // Background type cards
                        VStack(spacing: FGSpacing.sm) {
                            ForEach(BackgroundType.allCases) { bgType in
                                BackgroundTypeCard(
                                    type: bgType,
                                    isSelected: viewModel.project?.colors.backgroundType == bgType
                                ) {
                                    withAnimation(FGAnimations.spring) {
                                        viewModel.project?.colors.backgroundType = bgType
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

/// Background type selection card with visual preview
private struct BackgroundTypeCard: View {
    let type: BackgroundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.md) {
                // Visual preview of background type
                backgroundPreview
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                    Text(type.displayName)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)

                    Text(type.description)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(FGColors.accentPrimary)
                }
            }
            .padding(FGSpacing.sm)
            .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }

    @ViewBuilder
    private var backgroundPreview: some View {
        switch type {
        case .solid:
            Rectangle()
                .fill(Color(hex: "4F46E5"))

        case .gradient:
            LinearGradient(
                colors: [Color(hex: "7C3AED"), Color(hex: "EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .textured:
            ZStack {
                Rectangle()
                    .fill(Color(hex: "1F2937"))
                // Simple texture pattern
                VStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }

        case .light:
            Rectangle()
                .fill(Color(hex: "F9FAFB"))

        case .dark:
            Rectangle()
                .fill(Color(hex: "1F2937"))
        }
    }
}

// MARK: - BackgroundType Extension

extension BackgroundType {
    var description: String {
        switch self {
        case .solid: return "Single uniform color"
        case .gradient: return "Smooth color transitions"
        case .textured: return "Pattern or texture overlay"
        case .light: return "Light/white background"
        case .dark: return "Dark/black background"
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return ColorsStepView(viewModel: vm)
}
