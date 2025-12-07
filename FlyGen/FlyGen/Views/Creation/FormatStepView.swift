import SwiftUI

struct FormatStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Aspect ratio section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Aspect Ratio")
                        .font(.headline)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AspectRatio.allCases) { ratio in
                            AspectRatioCard(
                                ratio: ratio,
                                isSelected: viewModel.project?.output.aspectRatio == ratio
                            ) {
                                viewModel.project?.output.aspectRatio = ratio
                            }
                        }
                    }
                }

                Divider()

                // Text rendering mode section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Rendering")
                        .font(.headline)

                    Text("Choose how text appears in the design")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        ForEach([ImageryType.illustrated, ImageryType.noText]) { type in
                            SelectionCard(
                                isSelected: viewModel.project?.visuals.imageryType == type,
                                action: {
                                    viewModel.project?.visuals.imageryType = type
                                }
                            ) {
                                HStack {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                        .foregroundColor(viewModel.project?.visuals.imageryType == type ? .accentColor : .primary)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(type == .illustrated ? "AI Rendered Text" : "Text-Free Design")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text(type == .illustrated ? "AI generates text directly in the image" : "Clean design for adding text in Canva/Photoshop")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if viewModel.project?.visuals.imageryType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .event)
    return FormatStepView(viewModel: vm)
}
