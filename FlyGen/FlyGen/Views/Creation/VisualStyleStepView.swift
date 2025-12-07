import SwiftUI

struct VisualStyleStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(VisualStyle.allCases) { style in
                    IconSelectionCard(
                        title: style.displayName,
                        icon: style.icon,
                        isSelected: viewModel.project?.visuals.style == style
                    ) {
                        viewModel.project?.visuals.style = style
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
    return VisualStyleStepView(viewModel: vm)
}
