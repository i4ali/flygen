import SwiftUI

/// Expandable tooltip component for contextual guidance
struct FGTooltip: View {
    let text: String
    var icon: String = "info.circle"

    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(FGAnimations.spring) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FGColors.accentSecondary)

                if isExpanded {
                    Text(text)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .padding(.horizontal, FGSpacing.sm)
            .padding(.vertical, FGSpacing.xs)
            .background(FGColors.surfaceDefault)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGScaleButtonStyle())
    }
}

/// Static tooltip with always-visible text
struct FGInfoBadge: View {
    let text: String
    var icon: String = "lightbulb.fill"
    var color: Color = FGColors.accentSecondary

    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)

            Text(text)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)
        }
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Section header with optional tooltip
struct FGSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var tooltipText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            HStack(spacing: FGSpacing.xs) {
                Text(title)
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                if let tooltipText = tooltipText {
                    FGTooltip(text: tooltipText)
                }

                Spacer()
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
            }
        }
    }
}

/// Step header with title, subtitle and optional tooltip
struct FGStepHeader: View {
    let title: String
    var subtitle: String? = nil
    var tooltipText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            HStack(spacing: FGSpacing.xs) {
                Text(title)
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                if let tooltipText = tooltipText {
                    FGTooltip(text: tooltipText)
                }

                Spacer()
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }
}

/// Inline help text with icon
struct FGHelpText: View {
    let text: String
    var icon: String = "questionmark.circle"

    var body: some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(FGColors.textTertiary)

            Text(text)
                .font(FGTypography.bodySmall)
                .foregroundColor(FGColors.textTertiary)
        }
    }
}

#Preview("FGTooltip & Headers") {
    ScrollView {
        VStack(alignment: .leading, spacing: FGSpacing.xl) {
            Text("Tooltips & Headers")
                .font(FGTypography.h1)
                .foregroundColor(FGColors.textPrimary)

            // Tooltips
            VStack(alignment: .leading, spacing: FGSpacing.md) {
                Text("Tooltips")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    FGTooltip(text: "This is a helpful tip")
                    FGTooltip(text: "Another tooltip", icon: "lightbulb")
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Info badges
            VStack(alignment: .leading, spacing: FGSpacing.md) {
                Text("Info Badges")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                VStack(alignment: .leading, spacing: FGSpacing.sm) {
                    FGInfoBadge(text: "Pro tip: Use high contrast colors")
                    FGInfoBadge(text: "Warning message", icon: "exclamationmark.triangle.fill", color: FGColors.warning)
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Section headers
            VStack(alignment: .leading, spacing: FGSpacing.md) {
                Text("Section Headers")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                FGSectionHeader(
                    title: "Choose a Style",
                    subtitle: "This affects typography, layout, and visual effects",
                    tooltipText: "The style sets the overall visual direction"
                )
            }

            Divider().background(FGColors.borderSubtle)

            // Step header
            FGStepHeader(
                title: "Set the Mood",
                subtitle: "This affects colors, imagery, and overall feel",
                tooltipText: "Mood influences the emotional tone"
            )

            Divider().background(FGColors.borderSubtle)

            // Help text
            VStack(alignment: .leading, spacing: FGSpacing.md) {
                Text("Help Text")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                FGHelpText(text: "Enter a short, catchy headline that grabs attention")
            }
        }
        .padding(FGSpacing.screenHorizontal)
    }
    .background(FGColors.backgroundPrimary)
}
