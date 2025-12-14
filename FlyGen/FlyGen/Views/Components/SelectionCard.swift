import SwiftUI

/// A reusable selection card for category, style, mood, etc.
/// Updated with FlyGen dark theme design system
struct SelectionCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .padding(FGSpacing.cardPadding)
                .background(cardBackground)
                .overlay(cardBorder)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                .shadow(
                    color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
                    radius: isSelected ? 12 : 0,
                    x: 0,
                    y: 0
                )
        }
        .buttonStyle(FGCardButtonStyle())
        .onHover { hovering in
            withAnimation(FGAnimations.quickEaseOut) {
                isHovered = hovering
            }
        }
        .animation(FGAnimations.spring, value: isSelected)
    }

    private var cardBackground: some View {
        ZStack {
            // Base layer
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .fill(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)

            // Gradient overlay for selected state
            if isSelected {
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .fill(FGGradients.selectedGlow)
            }

            // Shine effect
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .fill(FGGradients.cardShine)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
            .stroke(
                isSelected ? FGColors.accentPrimary :
                    (isHovered ? FGColors.borderDefault : FGColors.borderSubtle),
                lineWidth: isSelected ? 2 : 1
            )
    }
}

/// Simple text selection card with icon
struct IconSelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? FGColors.accentPrimary : FGColors.textSecondary)
                    .symbolEffect(.bounce, value: isSelected)

                Text(title)
                    .font(FGTypography.label)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 80)
        }
    }
}

/// Emoji selection card for categories
struct EmojiSelectionCard: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.xs) {
                Text(emoji)
                    .font(.largeTitle)

                Text(title)
                    .font(FGTypography.label)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 90)
        }
    }
}

/// Color palette preview card
struct ColorPaletteCard: View {
    let preset: ColorSchemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.xs) {
                HStack(spacing: FGSpacing.xxs) {
                    ForEach(Array(preset.previewColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(FGColors.borderSubtle, lineWidth: 1)
                            )
                    }
                }

                Text(preset.displayName)
                    .font(FGTypography.label)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
            }
            .frame(height: 70)
        }
    }
}

/// Large color palette card for horizontal scrolling
struct LargeColorPaletteCard: View {
    let preset: ColorSchemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.sm) {
                // Large color swatch preview
                HStack(spacing: 0) {
                    ForEach(Array(preset.previewColors.enumerated()), id: \.offset) { _, color in
                        Rectangle()
                            .fill(color)
                    }
                }
                .frame(width: 140, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                )

                Text(preset.displayName)
                    .font(FGTypography.label)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
            }
            .padding(FGSpacing.sm)
            .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .shadow(
                color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0
            )
        }
        .buttonStyle(FGCardButtonStyle())
        .animation(FGAnimations.spring, value: isSelected)
    }
}

/// Aspect ratio preview card
struct AspectRatioCard: View {
    let ratio: AspectRatio
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: FGSpacing.xs) {
                // Visual representation of aspect ratio
                let size = aspectPreviewSize(for: ratio)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? FGColors.accentPrimary : FGColors.textTertiary.opacity(0.3))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(FGColors.borderDefault, lineWidth: 1)
                    )

                VStack(spacing: FGSpacing.xxxs) {
                    Text(ratio.displayName)
                        .font(FGTypography.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)

                    Text(ratio.subtitle)
                        .font(FGTypography.captionSmall)
                        .foregroundColor(FGColors.textTertiary)
                }
            }
            .frame(height: 100)
        }
    }

    private func aspectPreviewSize(for ratio: AspectRatio) -> CGSize {
        let maxHeight: CGFloat = 50
        let maxWidth: CGFloat = 60

        switch ratio {
        case .square:
            return CGSize(width: 40, height: 40)
        case .portrait:
            return CGSize(width: 32, height: 40)
        case .story:
            return CGSize(width: 28, height: maxHeight)
        case .landscape:
            return CGSize(width: maxWidth, height: 34)
        case .letter, .a4:
            return CGSize(width: 35, height: 45)
        }
    }
}

/// Mood selection card with gradient background
struct MoodSelectionCard: View {
    let title: String
    let icon: String
    let moodName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xs) {
                // Mood-colored gradient circle
                ZStack {
                    Circle()
                        .fill(FGGradients.moodGradient(for: moodName))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(FGTypography.label)
                    .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.sm)
            .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
            radius: isSelected ? 8 : 0
        )
        .animation(FGAnimations.spring, value: isSelected)
    }
}

/// Language picker for selecting flyer output language
struct LanguagePicker: View {
    @Binding var selection: FlyerLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            HStack(spacing: FGSpacing.xxs) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(FGColors.textSecondary)

                Text("Output Language")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)
            }

            Menu {
                ForEach(FlyerLanguage.allCases, id: \.self) { language in
                    Button {
                        withAnimation(FGAnimations.quickEaseOut) {
                            selection = language
                        }
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if selection == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.displayName)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(.horizontal, FGSpacing.sm)
                .padding(.vertical, FGSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: FGSpacing.chipRadius)
                        .fill(FGColors.surfaceSelected)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.chipRadius)
                        .stroke(FGColors.accentPrimary, lineWidth: 1)
                )
            }
        }
        .padding(FGSpacing.sm)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview("Selection Cards - Dark Theme") {
    ScrollView {
        VStack(spacing: FGSpacing.lg) {
            Text("Selection Cards")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)

            // Emoji cards
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Category Cards")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    EmojiSelectionCard(title: "Event", emoji: "🎪", isSelected: true) {}
                    EmojiSelectionCard(title: "Sale", emoji: "🏷️", isSelected: false) {}
                }
            }

            // Icon cards
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Style Cards")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    IconSelectionCard(title: "Modern", icon: "square", isSelected: true) {}
                    IconSelectionCard(title: "Bold", icon: "flame", isSelected: false) {}
                }
            }

            // Color palette cards
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Color Palettes")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    ColorPaletteCard(preset: .warm, isSelected: true) {}
                    ColorPaletteCard(preset: .cool, isSelected: false) {}
                }
            }

            // Aspect ratio cards
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Aspect Ratios")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    AspectRatioCard(ratio: .portrait, isSelected: true) {}
                    AspectRatioCard(ratio: .story, isSelected: false) {}
                }
            }

            // Mood cards
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Mood Cards")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.sm) {
                    MoodSelectionCard(title: "Urgent", icon: "exclamationmark.triangle.fill", moodName: "urgent", isSelected: true) {}
                    MoodSelectionCard(title: "Calm", icon: "leaf.fill", moodName: "calm", isSelected: false) {}
                    MoodSelectionCard(title: "Elegant", icon: "sparkles", moodName: "elegant", isSelected: false) {}
                }
            }
        }
        .padding(FGSpacing.screenHorizontal)
    }
    .background(FGColors.backgroundPrimary)
}
