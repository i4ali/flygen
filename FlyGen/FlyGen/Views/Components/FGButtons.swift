import SwiftUI

// MARK: - Primary Button

/// Primary action button with gradient background
struct FGPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FGColors.textOnAccent))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(FGTypography.labelLarge)
            }
            .foregroundColor(FGColors.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: FGSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .fill(isEnabled ? FGGradients.accent : LinearGradient(colors: [FGColors.textTertiary], startPoint: .leading, endPoint: .trailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .fill(FGGradients.cardShine)
            )
            .shadow(
                color: isEnabled ? FGColors.accentPrimary.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(FGPrimaryButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Secondary Button

/// Secondary action button with border
struct FGSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(FGTypography.labelLarge)
            }
            .foregroundColor(isEnabled ? FGColors.textPrimary : FGColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: FGSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .fill(FGColors.surfaceDefault)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .stroke(FGColors.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Ghost Button

/// Minimal button with no background
struct FGGhostButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = FGColors.accentPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(FGTypography.labelLarge)
            }
            .foregroundColor(color)
            .frame(height: FGSpacing.buttonHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(FGScaleButtonStyle())
    }
}

// MARK: - Icon Button

/// Circular icon button
struct FGIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var backgroundColor: Color = FGColors.surfaceDefault
    var iconColor: Color = FGColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(FGColors.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(FGScaleButtonStyle())
    }
}

// MARK: - Action Button (for result view)

/// Small action button with icon and label
struct FGActionButton: View {
    let icon: String
    let title: String
    var color: Color = FGColors.accentPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(FGTypography.captionBold)
                    .foregroundColor(FGColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.md)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGCardButtonStyle())
    }
}

// MARK: - Navigation Buttons

/// Back/Next navigation button pair for creation flow
struct FGNavigationButtons: View {
    var canGoBack: Bool = true
    var canGoNext: Bool = true
    var nextTitle: String = "Next"
    var showBack: Bool = true
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            if showBack {
                FGSecondaryButton(title: "Back", icon: "chevron.left", isEnabled: canGoBack) {
                    onBack()
                }
            }

            FGPrimaryButton(title: nextTitle, icon: "chevron.right", isEnabled: canGoNext) {
                onNext()
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .padding(.vertical, FGSpacing.md)
        .background(FGColors.backgroundSecondary)
    }
}

// MARK: - Chip/Tag Button

/// Small pill-shaped button for tags or filters
struct FGChipButton: View {
    let title: String
    var isSelected: Bool = false
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }

                Text(title)
                    .font(FGTypography.label)
            }
            .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textSecondary)
            .padding(.horizontal, FGSpacing.sm)
            .padding(.vertical, FGSpacing.xs)
            .background(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(FGScaleButtonStyle())
        .animation(FGAnimations.spring, value: isSelected)
    }
}

// MARK: - Floating Action Button

/// Large floating action button for primary creation action
struct FGFloatingActionButton: View {
    var icon: String = "plus"
    var size: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(FGColors.textOnAccent)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(FGGradients.accent)
                )
                .overlay(
                    Circle()
                        .fill(FGGradients.cardShine)
                )
                .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(FGPrimaryButtonStyle())
    }
}

// MARK: - Preview

#Preview("FGButtons - Dark Theme") {
    ScrollView {
        VStack(spacing: FGSpacing.xl) {
            Text("Buttons")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)

            // Primary buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Primary")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                FGPrimaryButton(title: "Generate Flyer", icon: "sparkles") {}
                FGPrimaryButton(title: "Loading...", isLoading: true) {}
                FGPrimaryButton(title: "Disabled", isEnabled: false) {}
            }

            Divider().background(FGColors.borderSubtle)

            // Secondary buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Secondary")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                FGSecondaryButton(title: "Cancel", icon: "xmark") {}
                FGSecondaryButton(title: "Disabled", isEnabled: false) {}
            }

            Divider().background(FGColors.borderSubtle)

            // Ghost buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Ghost")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack {
                    FGGhostButton(title: "Skip", icon: "arrow.right") {}
                    FGGhostButton(title: "Learn more", color: FGColors.accentSecondary) {}
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Icon buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Icon Buttons")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    FGIconButton(icon: "xmark") {}
                    FGIconButton(icon: "gear", iconColor: FGColors.textSecondary) {}
                    FGIconButton(icon: "heart.fill", backgroundColor: FGColors.error.opacity(0.2), iconColor: FGColors.error) {}
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Action buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Action Buttons")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    FGActionButton(icon: "arrow.triangle.2.circlepath", title: "Refine", color: .orange) {}
                    FGActionButton(icon: "aspectratio", title: "Resize", color: .purple) {}
                    FGActionButton(icon: "square.and.arrow.down", title: "Save", color: .green) {}
                    FGActionButton(icon: "square.and.arrow.up", title: "Share", color: .blue) {}
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Chip buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Chip Buttons")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.xs) {
                    FGChipButton(title: "All", isSelected: true) {}
                    FGChipButton(title: "Events") {}
                    FGChipButton(title: "Sales", icon: "tag") {}
                }
            }

            Divider().background(FGColors.borderSubtle)

            // Navigation buttons
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Navigation")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                FGNavigationButtons(
                    canGoBack: true,
                    canGoNext: true,
                    onBack: {},
                    onNext: {}
                )
            }

            Divider().background(FGColors.borderSubtle)

            // FAB
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Floating Action Button")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack {
                    Spacer()
                    FGFloatingActionButton {}
                    Spacer()
                }
            }
        }
        .padding(FGSpacing.screenHorizontal)
    }
    .background(FGColors.backgroundPrimary)
}
