import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("openrouter_api_key") private var apiKey: String = ""

    @State private var showingRefinementSheet = false
    @State private var showingReformatSheet = false
    @State private var showingSaveSuccess = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image display
                if case .generating = viewModel.generationState {
                    GenerationView(viewModel: viewModel)
                } else if case .success(let image) = viewModel.generationState {
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(radius: 8)
                                .padding()

                            // Action buttons
                            HStack(spacing: 12) {
                                ActionButton(
                                    title: "Refine",
                                    icon: "arrow.triangle.2.circlepath",
                                    color: .orange
                                ) {
                                    showingRefinementSheet = true
                                }

                                ActionButton(
                                    title: "Resize",
                                    icon: "aspectratio",
                                    color: .purple
                                ) {
                                    showingReformatSheet = true
                                }

                                ActionButton(
                                    title: "Save",
                                    icon: "square.and.arrow.down",
                                    color: .green
                                ) {
                                    saveToPhotos()
                                }
                            }
                            .padding(.horizontal)

                            // Save feedback
                            if showingSaveSuccess {
                                Label("Saved to Photos!", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .padding()
                            }

                            if let error = saveError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }

                    // Done button
                    Button {
                        viewModel.cancelCreation()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding()

                } else if case .error(let message) = viewModel.generationState {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("Generation Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            Task {
                                await viewModel.generateFlyer(apiKey: apiKey)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Your Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showingResult = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                if case .success = viewModel.generationState {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview("My Flyer", image: shareImage)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingRefinementSheet) {
                RefinementSheet(viewModel: viewModel, apiKey: apiKey)
            }
            .sheet(isPresented: $showingReformatSheet) {
                ReformatSheet(viewModel: viewModel, apiKey: apiKey)
            }
        }
    }

    private var shareImage: Image {
        if case .success(let uiImage) = viewModel.generationState {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    private func saveToPhotos() {
        Task {
            do {
                try await viewModel.saveToPhotos()
                showingSaveSuccess = true
                saveError = nil

                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showingSaveSuccess = false
                }
            } catch {
                saveError = error.localizedDescription
                showingSaveSuccess = false
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.generationState = .success(UIImage(systemName: "doc.richtext")!)
    return ResultView(viewModel: vm)
}
