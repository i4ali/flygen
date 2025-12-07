import SwiftUI

/// A reusable selection card for category, style, mood, etc.
struct SelectionCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .primary)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
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
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.largeTitle)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
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
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(Array(preset.previewColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                    }
                }

                Text(preset.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
            }
            .frame(height: 70)
        }
    }
}

/// Aspect ratio preview card
struct AspectRatioCard: View {
    let ratio: AspectRatio
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            VStack(spacing: 8) {
                // Visual representation of aspect ratio
                let size = aspectPreviewSize(for: ratio)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    Text(ratio.displayName)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text(ratio.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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

#Preview {
    VStack(spacing: 16) {
        HStack {
            EmojiSelectionCard(title: "Event", emoji: "🎪", isSelected: true) {}
            EmojiSelectionCard(title: "Sale", emoji: "🏷️", isSelected: false) {}
        }

        HStack {
            IconSelectionCard(title: "Modern", icon: "square", isSelected: true) {}
            IconSelectionCard(title: "Bold", icon: "flame", isSelected: false) {}
        }

        HStack {
            ColorPaletteCard(preset: .warm, isSelected: true) {}
            ColorPaletteCard(preset: .cool, isSelected: false) {}
        }

        HStack {
            AspectRatioCard(ratio: .portrait, isSelected: true) {}
            AspectRatioCard(ratio: .story, isSelected: false) {}
        }
    }
    .padding()
}
