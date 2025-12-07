import SwiftUI

struct ColorsStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let paletteColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Color palette section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Palette")
                        .font(.headline)

                    LazyVGrid(columns: paletteColumns, spacing: 12) {
                        ForEach(ColorSchemePreset.allCases) { preset in
                            ColorPaletteCard(
                                preset: preset,
                                isSelected: viewModel.project?.colors.preset == preset
                            ) {
                                viewModel.project?.colors.preset = preset
                            }
                        }
                    }
                }

                Divider()

                // Background type section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Style")
                        .font(.headline)

                    LazyVGrid(columns: paletteColumns, spacing: 12) {
                        ForEach(BackgroundType.allCases) { bgType in
                            IconSelectionCard(
                                title: bgType.displayName,
                                icon: bgType.icon,
                                isSelected: viewModel.project?.colors.backgroundType == bgType
                            ) {
                                viewModel.project?.colors.backgroundType = bgType
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
    return ColorsStepView(viewModel: vm)
}
