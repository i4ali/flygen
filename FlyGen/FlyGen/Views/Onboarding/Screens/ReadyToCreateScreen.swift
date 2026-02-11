import SwiftUI

/// Screen 10: Final screen with preference summary and CTA
struct ReadyToCreateScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false
    @State private var showCelebration = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lottie celebration animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FGColors.accentGradientStart.opacity(0.4),
                                FGColors.accentGradientEnd.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
                    .opacity(showCelebration ? 1 : 0)

                LottieAnimationView(animationName: "celebration", loopMode: .playOnce)
                    .frame(width: 240, height: 240)
                    .scaleEffect(showCelebration ? 1 : 0.5)
                    .opacity(showCelebration ? 1 : 0)
            }

            Spacer()
                .frame(height: FGSpacing.xl)

            // Greeting and heading
            VStack(spacing: FGSpacing.sm) {
                Text(timeBasedGreeting)
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.accentPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("You're all set!")
                    .font(FGTypography.displayMedium)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
                .frame(height: FGSpacing.lg)

            // Preference summary chips
            if hasPreferences {
                preferenceSummary
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
            withAnimation(FGAnimations.spring.delay(0.5)) {
                showCelebration = true
            }
        }
    }

    // MARK: - Time-based Greeting

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        default:
            return "Good evening!"
        }
    }

    // MARK: - Preference Summary

    private var hasPreferences: Bool {
        viewModel.selectedUserRole != nil ||
        viewModel.selectedVisualStyle != nil ||
        !viewModel.selectedFlyerCategories.isEmpty
    }

    private var preferenceSummary: some View {
        VStack(spacing: FGSpacing.sm) {
            Text("Your preferences")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)

            // Wrap flow of chips
            PreferenceSummaryFlowLayout(spacing: FGSpacing.xs) {
                // Role chip
                if let role = viewModel.selectedUserRole {
                    SummaryChip(icon: role.icon, text: role.displayName)
                }

                // Style chip
                if let style = viewModel.selectedVisualStyle {
                    SummaryChip(icon: style.icon, text: style.displayName)
                }

                // Mood chip
                if let mood = viewModel.selectedMood {
                    SummaryChip(icon: mood.icon, text: mood.displayName)
                }

                // Top category chip (just show first one if any)
                if let firstCategory = viewModel.selectedFlyerCategories.first {
                    SummaryChip(icon: firstCategory.icon, text: firstCategory.displayName)
                }

                // Show count if more categories
                if viewModel.selectedFlyerCategories.count > 1 {
                    SummaryChip(
                        icon: "plus.circle",
                        text: "+\(viewModel.selectedFlyerCategories.count - 1) more"
                    )
                }
            }
            .padding(.horizontal, FGSpacing.lg)
        }
    }
}

// MARK: - Summary Chip

private struct SummaryChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: FGSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(FGColors.accentPrimary)

            Text(text)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(FGColors.surfaceSelected)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(FGColors.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout

private struct PreferenceSummaryFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxAvailableWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxAvailableWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview("Ready To Create Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        ReadyToCreateScreen(viewModel: OnboardingViewModel())
    }
}
