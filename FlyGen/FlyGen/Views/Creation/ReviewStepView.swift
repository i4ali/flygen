import SwiftUI

struct ReviewStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    let apiKey: String

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Summary sections
                    if let project = viewModel.project {
                        ReviewSection(title: "Category", icon: project.category.icon) {
                            Text(project.category.displayName)
                        } editAction: {
                            viewModel.goToStep(.category)
                        }

                        ReviewSection(title: "Text Content", icon: "text.alignleft") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.textContent.headline)
                                    .fontWeight(.medium)

                                if let sub = project.textContent.subheadline {
                                    Text(sub)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } editAction: {
                            viewModel.goToStep(.textContent)
                        }

                        ReviewSection(title: "Visual Style", icon: project.visuals.style.icon) {
                            Text(project.visuals.style.displayName)
                        } editAction: {
                            viewModel.goToStep(.visualStyle)
                        }

                        ReviewSection(title: "Mood", icon: project.visuals.mood.icon) {
                            Text(project.visuals.mood.displayName)
                        } editAction: {
                            viewModel.goToStep(.mood)
                        }

                        ReviewSection(title: "Colors", icon: "paintpalette") {
                            HStack {
                                ForEach(project.colors.preset.previewColors.indices, id: \.self) { i in
                                    Circle()
                                        .fill(project.colors.preset.previewColors[i])
                                        .frame(width: 20, height: 20)
                                }
                                Text(project.colors.preset.displayName)
                                    .font(.subheadline)
                            }
                        } editAction: {
                            viewModel.goToStep(.colors)
                        }

                        ReviewSection(title: "Format", icon: project.output.aspectRatio.icon) {
                            Text(project.output.aspectRatio.displayName)
                        } editAction: {
                            viewModel.goToStep(.format)
                        }

                        if !project.visuals.includeElements.isEmpty || project.logoImageData != nil {
                            ReviewSection(title: "Extras", icon: "sparkles") {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !project.visuals.includeElements.isEmpty {
                                        Text(project.visuals.includeElements.joined(separator: ", "))
                                            .font(.subheadline)
                                    }
                                    if project.logoImageData != nil {
                                        Label("Logo included", systemImage: "checkmark.circle")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            } editAction: {
                                viewModel.goToStep(.extras)
                            }
                        }
                    }
                }
                .padding()
            }

            // Generate button
            VStack(spacing: 12) {
                if apiKey.isEmpty {
                    Text("Add your API key in Settings to generate")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Button {
                    Task {
                        await viewModel.generateFlyer(apiKey: apiKey)
                    }
                } label: {
                    HStack {
                        if viewModel.generationState == .generating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.generationState == .generating ? "Generating..." : "Generate Flyer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(apiKey.isEmpty || viewModel.generationState == .generating)

                if case .error(let message) = viewModel.generationState {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    let editAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Edit") {
                    editAction()
                }
                .font(.subheadline)
            }

            content()
                .padding(.leading, 32)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .salePromo)
    vm.project?.textContent.headline = "MEGA SUMMER SALE"
    vm.project?.textContent.subheadline = "Up to 70% off everything"
    return ReviewStepView(viewModel: vm, apiKey: "test")
}
