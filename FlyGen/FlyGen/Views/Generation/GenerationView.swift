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
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: 16) {
                Text("Generating Your Flyer")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(currentMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: animationPhase)

                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }

            Spacer()

            // Estimated time
            Text("This usually takes 10-30 seconds")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
        .padding()
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
