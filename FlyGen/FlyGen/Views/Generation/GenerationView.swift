import SwiftUI

struct GenerationView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @State private var animationPhase = 0
    @State private var progressMessages = [
        "Crafting your design...",
        "Adding visual elements...",
        "Applying your style...",
        "Rendering text...",
        "Almost there..."
    ]

    var currentMessage: String {
        progressMessages[animationPhase % progressMessages.count]
    }

    var body: some View {
        VStack(spacing: FGSpacing.xxl) {
            Spacer()

            // Animated icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Middle ring
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.15))
                    .frame(width: 120, height: 120)

                // Inner ring
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.25))
                    .frame(width: 100, height: 100)

                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(FGColors.accentPrimary)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: FGSpacing.md) {
                Text("Generating Your Flyer")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                Text(currentMessage)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .animation(.easeInOut, value: animationPhase)

                ProgressView()
                    .tint(FGColors.accentPrimary)
                    .scaleEffect(1.2)
                    .padding(.top, FGSpacing.sm)
            }

            Spacer()

            // Estimated time
            Text("This usually takes 10-30 seconds")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
                .padding(.bottom, FGSpacing.xl)
        }
        .padding(FGSpacing.screenHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FGColors.backgroundPrimary)
        .onAppear {
            startMessageRotation()
        }
    }

    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            if viewModel.generationState != .generating {
                timer.invalidate()
            } else {
                withAnimation {
                    animationPhase += 1
                }
            }
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.generationState = .generating
    return GenerationView(viewModel: vm)
}
