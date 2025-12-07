import SwiftUI

/// Progress indicator for the creation flow
struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            // Step indicator text
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Dot-style progress indicator
struct StepDots: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index < currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        StepProgressBar(currentStep: 3, totalSteps: 8)
        StepDots(currentStep: 3, totalSteps: 8)
    }
    .padding()
}
