import SwiftUI
import PhotosUI

struct ExtrasStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @State private var includeElementsText: String = ""
    @State private var avoidElementsText: String = ""

    private var suggestedElements: [String] {
        guard let category = viewModel.project?.category else { return [] }
        return CategoryConfiguration.suggestionsFor(category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Include elements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elements to Include")
                        .font(.headline)

                    TextField("e.g., balloons, confetti, stars", text: $includeElementsText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: includeElementsText) { _, newValue in
                            viewModel.project?.visuals.includeElements = newValue
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                        }

                    // Suggestions
                    if !suggestedElements.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Text("Suggestions:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ForEach(suggestedElements, id: \.self) { element in
                                    Button {
                                        addSuggestion(element)
                                    } label: {
                                        Text(element)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentColor.opacity(0.1))
                                            .foregroundColor(.accentColor)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                }

                // Avoid elements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elements to Avoid")
                        .font(.headline)

                    TextField("e.g., people, faces, hands", text: $avoidElementsText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: avoidElementsText) { _, newValue in
                            viewModel.project?.visuals.avoidElements = newValue
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                        }
                }

                Divider()

                // Target audience
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Audience")
                        .font(.headline)

                    TextField("e.g., Young professionals, families", text: Binding(
                        get: { viewModel.project?.targetAudience ?? "" },
                        set: { viewModel.project?.targetAudience = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Special instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Instructions")
                        .font(.headline)

                    TextEditor(text: Binding(
                        get: { viewModel.project?.specialInstructions ?? "" },
                        set: { viewModel.project?.specialInstructions = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Divider()

                // Logo upload
                VStack(alignment: .leading, spacing: 8) {
                    Text("Logo (Optional)")
                        .font(.headline)

                    if let logoData = viewModel.project?.logoImageData,
                       let uiImage = UIImage(data: logoData) {
                        // Show uploaded logo
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                                .cornerRadius(8)

                            Spacer()

                            Button(role: .destructive) {
                                viewModel.clearLogo()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        PhotosPicker(selection: $viewModel.selectedLogoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add Logo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                        .onChange(of: viewModel.selectedLogoItem) { _, _ in
                            Task {
                                await viewModel.loadLogo()
                            }
                        }
                    }

                    Text("Logo will be incorporated into the flyer design")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func addSuggestion(_ element: String) {
        if includeElementsText.isEmpty {
            includeElementsText = element
        } else if !includeElementsText.contains(element) {
            includeElementsText += ", \(element)"
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .partyCelebration)
    return ExtrasStepView(viewModel: vm)
}
