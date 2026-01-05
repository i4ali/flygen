import SwiftUI

struct CreationFlowView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCancelConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                FGColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress header with step info
                    CreationProgressHeader(
                        currentStep: viewModel.currentStep.rawValue + 1,
                        totalSteps: CreationStep.totalSteps,
                        stepTitle: viewModel.currentStep.subtitle
                    )
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                    .padding(.top, FGSpacing.sm)
                    .padding(.bottom, FGSpacing.md)

                    // Step content with animated transitions
                    Group {
                        switch viewModel.currentStep {
                        case .category:
                            CategoryStepView(viewModel: viewModel)
                        case .textContent:
                            TextContentStepView(viewModel: viewModel)
                        case .visualStyle:
                            VisualStyleStepView(viewModel: viewModel)
                        case .mood:
                            MoodStepView(viewModel: viewModel)
                        case .colors:
                            ColorsStepView(viewModel: viewModel)
                        case .format:
                            FormatStepView(viewModel: viewModel)
                        case .qrCode:
                            QRCodeStepView(viewModel: viewModel)
                        case .extras:
                            ExtrasStepView(viewModel: viewModel)
                        case .review:
                            ReviewStepView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    // Navigation buttons (not shown on review step)
                    if viewModel.currentStep != .review {
                        navigationButtons
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Show confirmation if there's project data
                        if viewModel.project != nil {
                            showingCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: FGSpacing.xxs) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                                .font(FGTypography.label)
                        }
                        .foregroundColor(FGColors.textSecondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    // Empty - we use our custom header instead
                    EmptyView()
                }
            }
            .toolbarBackground(FGColors.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(isPresented: $viewModel.showingResult) {
                ResultView(viewModel: viewModel)
            }
            .confirmationDialog("Save your progress?", isPresented: $showingCancelConfirmation, titleVisibility: .visible) {
                Button("Save Draft") {
                    viewModel.saveDraft()
                    viewModel.cancelCreation()
                    dismiss()
                }
                Button("Discard", role: .destructive) {
                    viewModel.discardDraft()
                    viewModel.cancelCreation()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your flyer will be saved so you can continue later.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: FGSpacing.md) {
            // Back button
            if viewModel.canGoBack {
                Button {
                    withAnimation(FGAnimations.spring) {
                        // Handle intent sub-navigation on category step
                        if viewModel.currentStep == .category && viewModel.selectedIntent != nil {
                            viewModel.backToIntentSelection()
                        } else {
                            viewModel.goToPreviousStep()
                        }
                    }
                } label: {
                    HStack(spacing: FGSpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(FGTypography.button)
                    }
                    .foregroundColor(FGColors.textPrimary)
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

            // Next button
            Button {
                withAnimation(FGAnimations.spring) {
                    viewModel.goToNextStep()
                }
            } label: {
                HStack(spacing: FGSpacing.xs) {
                    Text(nextButtonText)
                        .font(FGTypography.button)
                    Image(systemName: nextButtonIcon)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(FGColors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FGSpacing.md)
                .background(
                    Group {
                        if viewModel.canGoNext {
                            FGGradients.accent
                        } else {
                            FGColors.textTertiary.opacity(0.5)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                .shadow(
                    color: viewModel.canGoNext ? FGColors.accentPrimary.opacity(0.3) : .clear,
                    radius: 8,
                    y: 4
                )
            }
            .disabled(!viewModel.canGoNext)
            .buttonStyle(FGPrimaryButtonStyle())
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .padding(.vertical, FGSpacing.md)
        .background(
            FGColors.backgroundPrimary
                .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        )
    }

    private var nextButtonText: String {
        switch viewModel.currentStep {
        case .extras:
            return "Review"
        default:
            return "Next"
        }
    }

    private var nextButtonIcon: String {
        switch viewModel.currentStep {
        case .extras:
            return "checkmark.circle"
        default:
            return "chevron.right"
        }
    }
}

// MARK: - Creation Progress Header

struct CreationProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitle: String

    var body: some View {
        VStack(spacing: FGSpacing.sm) {
            // Step indicator with animated progress
            HStack(spacing: FGSpacing.xs) {
                ForEach(1...totalSteps, id: \.self) { step in
                    StepIndicatorDot(
                        step: step,
                        currentStep: currentStep,
                        isCompleted: step < currentStep,
                        isCurrent: step == currentStep
                    )
                }
            }

            // Step counter text
            HStack(spacing: FGSpacing.xxs) {
                Text("Step \(currentStep)")
                    .font(FGTypography.captionBold)
                    .foregroundColor(FGColors.accentPrimary)

                Text("of \(totalSteps)")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)

                Text("•")
                    .foregroundColor(FGColors.textTertiary)

                Text(stepTitle)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }
        }
    }
}

// MARK: - Step Indicator Dot

struct StepIndicatorDot: View {
    let step: Int
    let currentStep: Int
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        ZStack {
            if isCompleted {
                // Completed step - filled with checkmark
                Circle()
                    .fill(FGColors.accentPrimary)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FGColors.textOnAccent)
                    )
            } else if isCurrent {
                // Current step - glowing dot
                Circle()
                    .fill(FGGradients.accent)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("\(step)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FGColors.textOnAccent)
                    )
                    .shadow(color: FGColors.accentPrimary.opacity(0.5), radius: 6)
            } else {
                // Future step - outlined
                Circle()
                    .stroke(FGColors.borderSubtle, lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("\(step)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FGColors.textTertiary)
                    )
            }
        }
        .animation(FGAnimations.spring, value: currentStep)

        // Connector line (except after last step)
        if step < 9 {
            Rectangle()
                .fill(step < currentStep ? FGColors.accentPrimary : FGColors.borderSubtle)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .animation(FGAnimations.spring, value: currentStep)
        }
    }
}

#Preview {
    CreationFlowView(viewModel: FlyerCreationViewModel())
}
