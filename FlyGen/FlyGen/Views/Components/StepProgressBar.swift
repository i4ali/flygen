import SwiftUI

/// Segmented progress indicator for the creation flow
/// Updated with FlyGen dark theme design system
struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var stepTitles: [String] = []

    var body: some View {
        VStack(spacing: FGSpacing.xs) {
            // Segmented progress bar
            GeometryReader { geometry in
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(segmentColor(for: index))
                            .frame(height: 4)
                    }
                }
            }
            .frame(height: 4)

            // Current step title and count
            HStack {
                if !stepTitles.isEmpty, currentStep > 0, currentStep <= stepTitles.count {
                    Text(stepTitles[currentStep - 1])
                        .font(FGTypography.labelSmall)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()

                Text("\(currentStep)/\(totalSteps)")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textTertiary)
            }
        }
        .animation(FGAnimations.spring, value: currentStep)
    }

    private func segmentColor(for index: Int) -> Color {
        if index < currentStep {
            return FGColors.accentPrimary
        } else if index == currentStep {
            return FGColors.accentPrimary.opacity(0.5)
        } else {
            return FGColors.borderDefault
        }
    }
}

/// Alternative dot-style progress indicator with dark theme
struct StepDots: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index < currentStep ? FGColors.accentPrimary : FGColors.borderDefault)
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentStep - 1 ? 1.2 : 1.0)
            }
        }
        .animation(FGAnimations.spring, value: currentStep)
    }
}

/// Compact progress indicator with percentage
struct StepProgressCompact: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(FGColors.borderDefault, lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(FGColors.accentPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(percentage)%")
                    .font(FGTypography.captionBold)
                    .foregroundColor(FGColors.textPrimary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textSecondary)

                Text("Creating your flyer")
                    .font(FGTypography.captionSmall)
                    .foregroundColor(FGColors.textTertiary)
            }
        }
        .animation(FGAnimations.spring, value: currentStep)
    }
}

/// Full-width progress header for creation flow (standalone version)
struct StandaloneCreationProgressHeader: View {
    let currentStep: CreationStep

    var body: some View {
        VStack(spacing: FGSpacing.md) {
            // Segmented progress
            StepProgressBar(
                currentStep: currentStep.rawValue + 1,
                totalSteps: CreationStep.totalSteps,
                stepTitles: CreationStep.allCases.map { $0.title }
            )

            // Current step info
            VStack(spacing: FGSpacing.xxs) {
                Text(currentStep.title)
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                Text(currentStep.subtitle)
                    .font(FGTypography.bodySmall)
                    .foregroundColor(FGColors.textSecondary)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .padding(.vertical, FGSpacing.sm)
        .background(FGColors.backgroundSecondary)
    }
}

#Preview("Step Progress - Dark Theme") {
    ScrollView {
        VStack(spacing: FGSpacing.xl) {
            Text("Progress Indicators")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)

            // Segmented bar
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Segmented Bar")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                StepProgressBar(
                    currentStep: 3,
                    totalSteps: 9,
                    stepTitles: ["Category", "Text", "Style", "Mood", "Colors", "Format", "QR", "Extras", "Review"]
                )
            }

            Divider().background(FGColors.borderSubtle)

            // Dots
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Dot Style")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                StepDots(currentStep: 3, totalSteps: 9)
            }

            Divider().background(FGColors.borderSubtle)

            // Compact
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Compact")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                StepProgressCompact(currentStep: 3, totalSteps: 9)
            }

            Divider().background(FGColors.borderSubtle)

            // Full header
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Full Header")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                StandaloneCreationProgressHeader(currentStep: .visualStyle)
            }
        }
        .padding(.vertical, FGSpacing.lg)
    }
    .background(FGColors.backgroundPrimary)
}
