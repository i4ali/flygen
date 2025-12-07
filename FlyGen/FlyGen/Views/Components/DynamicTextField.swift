import SwiftUI

/// A styled text field for the creation flow
struct DynamicTextField: View {
    let field: TextFieldType
    @Binding var text: String
    var isFocused: FocusState<TextFieldType?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            HStack {
                Text(field.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            // Text field
            if field.isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused.wrappedValue == field ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .focused(isFocused, equals: field)
            } else {
                TextField(field.placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused.wrappedValue == field ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .focused(isFocused, equals: field)
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .textInputAutocapitalization(autocapitalization)
            }
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

#Preview {
    @FocusState var focusedField: TextFieldType?
    @State var headline = ""
    @State var body = ""

    return VStack(spacing: 16) {
        DynamicTextField(
            field: .headline,
            text: $headline,
            isFocused: $focusedField
        )

        DynamicTextField(
            field: .bodyText,
            text: $body,
            isFocused: $focusedField
        )
    }
    .padding()
}
