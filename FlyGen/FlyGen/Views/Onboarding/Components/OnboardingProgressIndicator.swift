import SwiftUI

/// Progress indicator for onboarding screens (3 dots)
struct OnboardingProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? FGColors.accentPrimary : FGColors.textTertiary.opacity(0.4))
                    .frame(width: dotSize(for: index), height: dotSize(for: index))
                    .scaleEffect(index == currentPage ? 1.0 : 0.8)
                    .animation(FGAnimations.spring, value: currentPage)
            }
        }
    }

    private func dotSize(for index: Int) -> CGFloat {
        index == currentPage ? 10 : 8
    }
}

/// Animated progress bar alternative
struct OnboardingProgressBar: View {
    let progress: CGFloat  // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(FGColors.surfaceDefault)
                    .frame(height: 4)

                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(FGAnimations.spring, value: progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview("Progress Indicators") {
    VStack(spacing: FGSpacing.xxl) {
        VStack(spacing: FGSpacing.md) {
            Text("Dot Indicator")
                .font(FGTypography.label)
                .foregroundColor(FGColors.textSecondary)

            OnboardingProgressIndicator(currentPage: 0, totalPages: 3)
            OnboardingProgressIndicator(currentPage: 1, totalPages: 3)
            OnboardingProgressIndicator(currentPage: 2, totalPages: 3)
        }

        VStack(spacing: FGSpacing.md) {
            Text("Progress Bar")
                .font(FGTypography.label)
                .foregroundColor(FGColors.textSecondary)

            OnboardingProgressBar(progress: 0.33)
                .frame(width: 200)
            OnboardingProgressBar(progress: 0.66)
                .frame(width: 200)
            OnboardingProgressBar(progress: 1.0)
                .frame(width: 200)
        }
    }
    .padding()
    .background(FGColors.backgroundPrimary)
}
