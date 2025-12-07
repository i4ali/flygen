import SwiftUI

struct CreationFlowView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("openrouter_api_key") private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                StepProgressBar(
                    currentStep: viewModel.currentStep.rawValue + 1,
                    totalSteps: CreationStep.totalSteps
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Step content
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
                    case .extras:
                        ExtrasStepView(viewModel: viewModel)
                    case .review:
                        ReviewStepView(viewModel: viewModel, apiKey: apiKey)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                if viewModel.currentStep != .review {
                    HStack(spacing: 16) {
                        if viewModel.canGoBack {
                            Button {
                                viewModel.goToPreviousStep()
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }

                        Button {
                            viewModel.goToNextStep()
                        } label: {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canGoNext ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.canGoNext)
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.currentStep.subtitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelCreation()
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingResult) {
                ResultView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    CreationFlowView(viewModel: FlyerCreationViewModel())
}
