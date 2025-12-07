import SwiftUI

struct MoodStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    IconSelectionCard(
                        title: mood.displayName,
                        icon: mood.icon,
                        isSelected: viewModel.project?.visuals.mood == mood
                    ) {
                        viewModel.project?.visuals.mood = mood
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
    return MoodStepView(viewModel: vm)
}
