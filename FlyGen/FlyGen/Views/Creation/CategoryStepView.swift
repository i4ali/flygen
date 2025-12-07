import SwiftUI

struct CategoryStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(FlyerCategory.allCases) { category in
                    EmojiSelectionCard(
                        title: category.displayName,
                        emoji: category.emoji,
                        isSelected: viewModel.project?.category == category
                    ) {
                        viewModel.startNewFlyer(category: category)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    CategoryStepView(viewModel: FlyerCreationViewModel())
}
