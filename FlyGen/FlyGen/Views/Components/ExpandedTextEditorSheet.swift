import SwiftUI

/// Fullscreen text editor sheet for composing longer text content
/// Provides more space for typing body text, descriptions, etc.
struct ExpandedTextEditorSheet: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // Background
                FGColors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Text editor (full height)
                    TextEditor(text: $text)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(FGSpacing.md)
                        .focused($isFocused)

                    // Footer with formatting toolbar and character count
                    VStack(spacing: FGSpacing.sm) {
                        // Formatting toolbar
                        HStack(spacing: FGSpacing.lg) {
                            Button {
                                insertBullet()
                            } label: {
                                Label("Bullet List", systemImage: "list.bullet")
                                    .labelStyle(.titleAndIcon)
                            }

                            Button {
                                insertNumberedItem()
                            } label: {
                                Label("Numbered List", systemImage: "list.number")
                                    .labelStyle(.titleAndIcon)
                            }

                            Spacer()
                        }
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                        // Character count
                        HStack {
                            Spacer()
                            Text("\(text.count) characters")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, FGSpacing.md)
                    .padding(.bottom, FGSpacing.md)
                }

                // Placeholder when empty
                if text.isEmpty {
                    Text(placeholder)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textTertiary)
                        .padding(FGSpacing.md)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FGColors.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.accentPrimary)
                }
            }
            .onAppear { isFocused = true }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - List Formatting

    private func insertBullet() {
        if text.isEmpty || text.hasSuffix("\n") {
            text += "• "
        } else {
            text += "\n• "
        }
    }

    private func insertNumberedItem() {
        let nextNumber = countNumberedItems() + 1
        if text.isEmpty || text.hasSuffix("\n") {
            text += "\(nextNumber). "
        } else {
            text += "\n\(nextNumber). "
        }
    }

    private func countNumberedItems() -> Int {
        let lines = text.components(separatedBy: "\n")
        return lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let firstChar = trimmed.first, firstChar.isNumber else { return false }
            return trimmed.contains(". ")
        }.count
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var text = "Sample text that could be much longer..."

        var body: some View {
            Color.black
                .sheet(isPresented: .constant(true)) {
                    ExpandedTextEditorSheet(
                        text: $text,
                        title: "Body Text",
                        placeholder: "Enter your content here..."
                    )
                }
        }
    }

    return PreviewWrapper()
}
