import SwiftUI

struct TextContentStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @FocusState private var focusedField: TextFieldType?

    private var fields: [TextFieldType] {
        guard let category = viewModel.project?.category else { return [] }
        return CategoryConfiguration.fieldsFor(category)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category indicator
                if let category = viewModel.project?.category {
                    HStack {
                        Text(category.emoji)
                        Text(category.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Dynamic text fields
                ForEach(fields) { field in
                    DynamicTextField(
                        field: field,
                        text: viewModel.binding(for: field),
                        isFocused: $focusedField
                    )
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .salePromo)
    return TextContentStepView(viewModel: vm)
}
