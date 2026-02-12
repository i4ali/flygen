import SwiftUI

/// A styled text field for the creation flow
/// Updated with FlyGen dark theme
struct DynamicTextField: View {
    let field: TextFieldType
    @Binding var text: String
    var isFocused: FocusState<TextFieldType?>.Binding

    @State private var showExpandedEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            // Label with required indicator
            HStack(spacing: FGSpacing.xxs) {
                Text(field.label)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)

                if field.isRequired {
                    Text("*")
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.error)
                }

                Spacer()

                // Character count for multiline
                if field.isMultiline && !text.isEmpty {
                    Text("\(text.count)")
                        .font(FGTypography.captionSmall)
                        .foregroundColor(FGColors.textTertiary)
                }

                // Clear button for multiline fields (in header)
                if field.isMultiline && !text.isEmpty {
                    Button {
                        withAnimation(FGAnimations.quickEaseOut) {
                            text = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(FGColors.textTertiary)
                    }
                }

                // Expand button for multiline fields
                if field.isMultiline {
                    Button {
                        showExpandedEditor = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14))
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
            }

            // Text field
            if field.isMultiline {
                TextEditor(text: $text)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: field == .bodyText ? 140 : 100)
                    .padding(FGSpacing.sm)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                            .stroke(
                                isFocused.wrappedValue == field ? FGColors.accentPrimary : FGColors.borderSubtle,
                                lineWidth: isFocused.wrappedValue == field ? 2 : 1
                            )
                    )
                    .focused(isFocused, equals: field)
            } else {
                HStack(spacing: FGSpacing.xs) {
                    TextField(field.placeholder, text: $text)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .textFieldStyle(.plain)
                        .focused(isFocused, equals: field)
                        .keyboardType(keyboardType)
                        .textContentType(contentType)
                        .textInputAutocapitalization(autocapitalization)

                    // Clear button
                    if !text.isEmpty {
                        Button {
                            withAnimation(FGAnimations.quickEaseOut) {
                                text = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(FGColors.textTertiary)
                        }
                    }
                }
                .padding(FGSpacing.sm)
                .background(FGColors.surfaceDefault)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .stroke(
                            isFocused.wrappedValue == field ? FGColors.accentPrimary : FGColors.borderSubtle,
                            lineWidth: isFocused.wrappedValue == field ? 2 : 1
                        )
                )
            }

        }
        .sheet(isPresented: $showExpandedEditor) {
            ExpandedTextEditorSheet(
                text: $text,
                title: field.label,
                placeholder: field.placeholder
            )
        }
    }

    private var keyboardType: UIKeyboardType {
        switch field.keyboardType {
        case .phone: return .phonePad
        case .email: return .emailAddress
        case .url: return .URL
        case .default: return .default
        }
    }

    private var contentType: UITextContentType? {
        switch field {
        case .phone: return .telephoneNumber
        case .email: return .emailAddress
        case .website: return .URL
        case .address: return .fullStreetAddress
        default: return nil
        }
    }

    private var autocapitalization: TextInputAutocapitalization {
        switch field {
        case .email, .website, .socialHandle:
            return .never
        case .headline:
            return .words
        default:
            return .sentences
        }
    }
}

/// Standalone text input with dark theme styling
struct FGTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isMultiline: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? FGColors.accentPrimary : FGColors.textTertiary)
            }

            if isMultiline {
                TextEditor(text: $text)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
            }
        }
        .padding(FGSpacing.sm)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                .stroke(
                    isFocused ? FGColors.accentPrimary : FGColors.borderSubtle,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(FGAnimations.quickEaseOut, value: isFocused)
    }
}

/// Search field with dark theme styling
struct FGSearchField: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(FGColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)
                .textFieldStyle(.plain)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(FGColors.textTertiary)
                }
            }
        }
        .padding(FGSpacing.sm)
        .background(FGColors.surfaceDefault)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview("DynamicTextField - Dark Theme") {
    struct PreviewWrapper: View {
        @FocusState var focusedField: TextFieldType?
        @State var headline = ""
        @State var bodyText = ""
        @State var search = ""

        var body: some View {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    Text("Text Fields")
                        .font(FGTypography.h2)
                        .foregroundColor(FGColors.textPrimary)

                    DynamicTextField(
                        field: .headline,
                        text: $headline,
                        isFocused: $focusedField
                    )

                    DynamicTextField(
                        field: .bodyText,
                        text: $bodyText,
                        isFocused: $focusedField
                    )

                    Divider().background(FGColors.borderSubtle)

                    Text("Standalone Fields")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    FGTextField(placeholder: "Enter text...", text: $headline, icon: "pencil")

                    FGSearchField(placeholder: "Search...", text: $search)
                }
                .padding(FGSpacing.screenHorizontal)
            }
            .background(FGColors.backgroundPrimary)
        }
    }

    return PreviewWrapper()
}
