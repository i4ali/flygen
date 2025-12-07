import SwiftUI

struct RefinementSheet: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    let apiKey: String
    @Environment(\.dismiss) private var dismiss

    @State private var feedback: String = ""

    private let quickSuggestions = [
        "Make text bigger",
        "More contrast",
        "Less busy",
        "More exciting",
        "Brighter colors",
        "More professional"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current image preview
                if case .success(let image) = viewModel.generationState {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                }

                // Feedback input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What would you like to change?")
                        .font(.headline)

                    TextEditor(text: $feedback)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // Quick suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick suggestions:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            Button {
                                addSuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }

                Spacer()

                // Apply button
                Button {
                    Task {
                        await viewModel.refineFlyer(feedback: feedback, apiKey: apiKey)
                        dismiss()
                    }
                } label: {
                    HStack {
                        if viewModel.generationState == .generating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Apply Changes")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(feedback.isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(feedback.isEmpty || viewModel.generationState == .generating)
            }
            .padding()
            .navigationTitle("Refine Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addSuggestion(_ suggestion: String) {
        if feedback.isEmpty {
            feedback = suggestion
        } else {
            feedback += ", \(suggestion.lowercased())"
        }
    }
}

/// Simple flow layout for suggestion chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            height = y + rowHeight
        }
    }
}

struct ReformatSheet: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    let apiKey: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRatio: AspectRatio = .portrait

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Select a new format")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AspectRatio.allCases) { ratio in
                        AspectRatioCard(
                            ratio: ratio,
                            isSelected: selectedRatio == ratio
                        ) {
                            selectedRatio = ratio
                        }
                    }
                }

                Spacer()

                // Apply button
                Button {
                    Task {
                        await viewModel.reformatFlyer(newRatio: selectedRatio, apiKey: apiKey)
                        dismiss()
                    }
                } label: {
                    HStack {
                        if viewModel.generationState == .generating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "aspectratio")
                        }
                        Text("Regenerate in \(selectedRatio.displayName)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(viewModel.generationState == .generating)
            }
            .padding()
            .navigationTitle("Resize Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedRatio = viewModel.project?.output.aspectRatio ?? .portrait
            }
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.generationState = .success(UIImage(systemName: "doc.richtext")!)
    return RefinementSheet(viewModel: vm, apiKey: "test")
}
