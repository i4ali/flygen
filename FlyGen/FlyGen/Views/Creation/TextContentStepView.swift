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
            VStack(spacing: FGSpacing.lg) {
                // Header
                FGStepHeader(
                    title: "Add your content",
                    subtitle: "Enter the text that will appear on your flyer",
                    tooltipText: "Required fields are marked with *"
                )

                // Category indicator
                if let category = viewModel.project?.category {
                    HStack(spacing: FGSpacing.xs) {
                        Text(category.emoji)
                            .font(.system(size: 20))

                        Text(category.displayName)
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(.horizontal, FGSpacing.sm)
                    .padding(.vertical, FGSpacing.xs)
                    .background(FGColors.surfaceDefault)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                }

                // Language picker
                LanguagePicker(selection: viewModel.languageBinding)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Dynamic text fields
                VStack(spacing: FGSpacing.md) {
                    ForEach(fields) { field in
                        if field.isCustomComponent {
                            // Render custom component for special field types
                            switch field {
                            case .scheduleEntries:
                                ScheduleEntriesField(
                                    entries: viewModel.additionalInfoBinding
                                )
                            default:
                                EmptyView()
                            }
                        } else {
                            DynamicTextField(
                                field: field,
                                text: viewModel.binding(for: field),
                                isFocused: $focusedField
                            )
                        }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)

                // Validation indicator
                if let project = viewModel.project {
                    ValidationIndicator(isValid: project.textContent.isValid)
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                }
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Shows validation status for the text content
private struct ValidationIndicator: View {
    let isValid: Bool

    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? FGColors.success : FGColors.warning)

            Text(isValid ? "Ready to continue" : "Fill in required fields to continue")
                .font(FGTypography.caption)
                .foregroundColor(isValid ? FGColors.success : FGColors.textTertiary)

            Spacer()
        }
        .padding(FGSpacing.sm)
        .background(isValid ? FGColors.success.opacity(0.1) : FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.chipRadius)
                .stroke(isValid ? FGColors.success.opacity(0.3) : FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .salePromo)
    return TextContentStepView(viewModel: vm)
}
