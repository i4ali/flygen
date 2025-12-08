import SwiftUI
import SwiftData

struct RefinementSheet: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    @State private var feedback: String = ""

    private var hasCredits: Bool {
        (userProfiles.first?.credits ?? 0) > 0
    }

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
            VStack(spacing: FGSpacing.xl) {
                // Current image preview
                if case .success(let image) = viewModel.generationState {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                        .shadow(color: FGColors.accentPrimary.opacity(0.2), radius: 8)
                }

                // Feedback input
                VStack(alignment: .leading, spacing: FGSpacing.sm) {
                    Text("What would you like to change?")
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    TextEditor(text: $feedback)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .padding(FGSpacing.sm)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                }

                // Quick suggestions
                VStack(alignment: .leading, spacing: FGSpacing.sm) {
                    Text("Quick suggestions:")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    FlowLayout(spacing: FGSpacing.sm) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            Button {
                                addSuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(FGTypography.caption)
                                    .padding(.horizontal, FGSpacing.sm)
                                    .padding(.vertical, FGSpacing.xs)
                                    .background(FGColors.accentPrimary.opacity(0.15))
                                    .foregroundColor(FGColors.accentPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()

                // No credits warning
                if !hasCredits {
                    HStack(spacing: FGSpacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("No credits remaining")
                    }
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.warning)
                    .padding(FGSpacing.sm)
                    .background(FGColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                }

                // Apply button
                Button {
                    Task {
                        await viewModel.refineFlyer(feedback: feedback)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: FGSpacing.sm) {
                        if viewModel.generationState == .generating {
                            ProgressView()
                                .tint(FGColors.textOnAccent)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Apply Changes (1 credit)")
                    }
                    .font(FGTypography.buttonLarge)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                    .background((feedback.isEmpty || !hasCredits) ? FGColors.textTertiary : FGColors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .shadow(color: (feedback.isEmpty || !hasCredits) ? .clear : FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
                }
                .disabled(feedback.isEmpty || !hasCredits || viewModel.generationState == .generating)
            }
            .padding(FGSpacing.screenHorizontal)
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Refine Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
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
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    @State private var selectedRatio: AspectRatio = .portrait

    private var hasCredits: Bool {
        (userProfiles.first?.credits ?? 0) > 0
    }

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm),
        GridItem(.flexible(), spacing: FGSpacing.sm)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: FGSpacing.xl) {
                Text("Select a new format")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
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

                // No credits warning
                if !hasCredits {
                    HStack(spacing: FGSpacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("No credits remaining")
                    }
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.warning)
                    .padding(FGSpacing.sm)
                    .background(FGColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                }

                // Apply button
                Button {
                    Task {
                        await viewModel.reformatFlyer(newRatio: selectedRatio)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: FGSpacing.sm) {
                        if viewModel.generationState == .generating {
                            ProgressView()
                                .tint(FGColors.textOnAccent)
                        } else {
                            Image(systemName: "aspectratio")
                        }
                        Text("Regenerate in \(selectedRatio.displayName) (1 credit)")
                    }
                    .font(FGTypography.buttonLarge)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                    .background(hasCredits ? FGColors.accentPrimary : FGColors.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .shadow(color: hasCredits ? FGColors.accentPrimary.opacity(0.4) : .clear, radius: 12, y: 4)
                }
                .disabled(!hasCredits || viewModel.generationState == .generating)
            }
            .padding(FGSpacing.screenHorizontal)
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Resize Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
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
    return RefinementSheet(viewModel: vm)
}
