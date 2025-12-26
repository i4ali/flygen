import SwiftUI

/// Loading screen with card shuffle animation shown before sample showcase
struct SampleLoadingScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateCards = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: FGSpacing.xl) {
            Spacer()

            // Card shuffle animation
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardGradient(for: index))
                        .frame(width: 70, height: 90)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        .rotationEffect(.degrees(animateCards ? cardRotation(index) : 0))
                        .offset(x: animateCards ? cardOffset(index) : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: animateCards
                        )
                }
            }
            .frame(height: 140)

            VStack(spacing: FGSpacing.sm) {
                Text("Finding perfect samples...")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                Text("Based on your preferences")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 10)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FGColors.backgroundPrimary)
        .onAppear {
            // Start card animation
            withAnimation {
                animateCards = true
            }

            // Fade in text
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showText = true
            }

            // Auto-advance after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewModel.goToNextScreen()
            }
        }
    }

    // MARK: - Card Helpers

    private func cardRotation(_ index: Int) -> Double {
        [-15, 0, 15][index]
    }

    private func cardOffset(_ index: Int) -> CGFloat {
        [-35, 0, 35][index]
    }

    private func cardGradient(for index: Int) -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(
                colors: [FGColors.accentPrimary, FGColors.accentPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                colors: [FGColors.accentSecondary, FGColors.accentSecondary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                colors: [FGColors.warning, FGColors.warning.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ]
        return gradients[index]
    }
}

#Preview {
    SampleLoadingScreen(viewModel: OnboardingViewModel())
}
