import SwiftUI

/// Fullscreen text editor sheet for composing longer text content
/// Provides more space for typing body text, descriptions, etc.
struct ExpandedTextEditorSheet: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool

    @State private var showClearConfirmation = false
    @State private var showDocumentPicker = false
    @State private var importedText: String?

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
                        // Row 1: Import/Actions toolbar
                        HStack(spacing: FGSpacing.lg) {
                            Button {
                                pasteFromClipboard()
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                                    .labelStyle(.titleAndIcon)
                            }

                            Button {
                                showDocumentPicker = true
                            } label: {
                                Label("Import", systemImage: "doc.badge.plus")
                                    .labelStyle(.titleAndIcon)
                            }

                            Button {
                                insertDivider()
                            } label: {
                                Label("Divider", systemImage: "minus")
                                    .labelStyle(.titleAndIcon)
                            }

                            Button {
                                showClearConfirmation = true
                            } label: {
                                Label("Clear", systemImage: "trash")
                                    .labelStyle(.titleAndIcon)
                            }
                            .disabled(text.isEmpty)
                            .opacity(text.isEmpty ? 0.5 : 1.0)

                            Spacer()
                        }
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                        // Row 2: Formatting + Character count
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

                            Text("\(text.count) characters")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.textTertiary)
                        }
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)
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
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(importedText: $importedText)
            }
            .onChange(of: importedText) { _, newValue in
                if let content = newValue {
                    if text.isEmpty {
                        text = content
                    } else {
                        text += "\n\n" + content
                    }
                    importedText = nil
                }
            }
        }
        .preferredColorScheme(.dark)
        .overlay {
            if showClearConfirmation {
                clearConfirmationOverlay
            }
        }
    }

    // MARK: - Clear Confirmation Overlay

    private var clearConfirmationOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    showClearConfirmation = false
                }

            // Confirmation card
            VStack(spacing: FGSpacing.lg) {
                VStack(spacing: FGSpacing.sm) {
                    Text("Clear Text")
                        .font(FGTypography.h3)
                        .foregroundColor(FGColors.textPrimary)

                    Text("Are you sure you want to clear all text?")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: FGSpacing.md) {
                    Button {
                        showClearConfirmation = false
                    } label: {
                        Text("Cancel")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.sm)
                            .background(FGColors.surfaceDefault)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }

                    Button {
                        text = ""
                        showClearConfirmation = false
                    } label: {
                        Text("Clear")
                            .font(FGTypography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.sm)
                            .background(FGColors.error)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                }
            }
            .padding(FGSpacing.lg)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .padding(.horizontal, FGSpacing.xl)
        }
    }

    // MARK: - Import/Actions

    private func pasteFromClipboard() {
        if let content = UIPasteboard.general.string {
            if text.isEmpty {
                text = content
            } else {
                text += "\n\n" + content
            }
        }
    }

    private func insertDivider() {
        if text.isEmpty || text.hasSuffix("\n") {
            text += "---\n\n"
        } else {
            text += "\n\n---\n\n"
        }
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
