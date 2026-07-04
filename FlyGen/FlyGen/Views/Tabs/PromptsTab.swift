import SwiftUI
import SwiftData

// MARK: - Chat launch wrapper

/// Identifiable wrapper so a tapped prompt can drive `.fullScreenCover(item:)`.
struct PromptLaunch: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Prompt card (text-first; no image, unlike Explore's thumbnails)

struct PromptCard: View {
    let title: String
    let preview: String
    let category: FlyerCategory

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.xs) {
            Text(title)
                .font(FGTypography.labelLarge)
                .foregroundColor(FGColors.textPrimary)
                .lineLimit(1)
            Text(preview)
                .font(FGTypography.bodySmall)
                .foregroundColor(FGColors.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: FGSpacing.xxs) {
                Image(systemName: category.icon).font(.system(size: 10))
                Text(category.displayName).font(FGTypography.captionSmall)
            }
            .foregroundColor(FGColors.textTertiary)
        }
        .padding(FGSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Editor sheet (used by "+ New", Edit, and Save-from-chat)

struct PromptEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existing: SavedPrompt?
    @State private var title: String
    @State private var text: String
    @State private var category: FlyerCategory

    /// `existing` = edit a saved prompt; `initialText` = prefill for a brand-new one.
    init(existing: SavedPrompt? = nil, initialText: String = "") {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? PromptEditorSheet.defaultTitle(from: initialText))
        _text = State(initialValue: existing?.text ?? initialText)
        _category = State(initialValue: existing?.category ?? .announcement)
    }

    private static func defaultTitle(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return String(firstLine.prefix(48))
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Name this prompt", text: $title)
                }
                Section("Prompt") {
                    TextField("What should the flyer say?", text: $text, axis: .vertical)
                        .lineLimit(4...12)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(FlyerCategory.allCases) { c in
                            Label(c.displayName, systemImage: c.icon).tag(c)
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Prompt" : "Edit Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmed.isEmpty ? PromptEditorSheet.defaultTitle(from: text) : trimmed
        if let existing {
            existing.title = finalTitle
            existing.text = text
            existing.category = category
            existing.updatedAt = Date()
        } else {
            modelContext.insert(SavedPrompt(title: finalTitle, text: text, category: category))
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tab

struct PromptsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedPrompt.updatedAt, order: .reverse) private var savedPrompts: [SavedPrompt]

    @State private var selectedCategory: FlyerCategory? = nil   // nil = All
    @State private var launch: PromptLaunch? = nil              // tapped prompt -> chat
    @State private var showingNew = false
    @State private var editing: SavedPrompt? = nil

    private var filteredSaved: [SavedPrompt] {
        guard let c = selectedCategory else { return savedPrompts }
        return savedPrompts.filter { $0.category == c }
    }
    private var filteredStarters: [PromptTemplate] {
        guard let c = selectedCategory else { return PromptLibrary.prompts }
        return PromptLibrary.prompts.filter { $0.category == c }
    }
    /// Categories present across both sets, for the filter pills.
    private var availableCategories: [FlyerCategory] {
        let all = PromptLibrary.prompts.map { $0.category } + savedPrompts.map { $0.category }
        return Array(Set(all)).sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpacing.lg) {
                    categoryFilterRow
                    yourPromptsSection
                    startersSection
                }
                .padding(.top, FGSpacing.md)
                .padding(.bottom, FGSpacing.xl)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Prompts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .foregroundColor(FGColors.accentPrimary)
                }
            }
            .fullScreenCover(item: $launch) { l in
                FlyerChatView(prefillText: l.text)
            }
            .sheet(isPresented: $showingNew) { PromptEditorSheet() }
            .sheet(item: $editing) { p in PromptEditorSheet(existing: p) }
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FGSpacing.sm) {
                FilterPillButton(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(availableCategories) { c in
                    FilterPillButton(title: c.displayName, icon: c.icon, isSelected: selectedCategory == c) {
                        selectedCategory = c
                    }
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    @ViewBuilder private var yourPromptsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Your Prompts")
                .font(FGTypography.h3).foregroundColor(FGColors.textPrimary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            if filteredSaved.isEmpty {
                Text("Save prompts you'll want to reuse. Tap + above to add one, or save one from a chat.")
                    .font(FGTypography.bodySmall).foregroundColor(FGColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(FGSpacing.cardPadding)
                    .background(FGColors.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.borderSubtle, lineWidth: 1))
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            } else {
                LazyVStack(spacing: FGSpacing.md) {
                    ForEach(filteredSaved) { p in
                        PromptCard(title: p.title, preview: p.text, category: p.category)
                            .onTapGesture { launch = PromptLaunch(text: p.text) }
                            .contextMenu {
                                Button { editing = p } label: { Label("Edit", systemImage: "pencil") }
                                Button(role: .destructive) { delete(p) } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
        }
    }

    @ViewBuilder private var startersSection: some View {
        if !filteredStarters.isEmpty {
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Starter Prompts")
                    .font(FGTypography.h3).foregroundColor(FGColors.textPrimary)
                    .padding(.horizontal, FGSpacing.screenHorizontal)
                LazyVStack(spacing: FGSpacing.md) {
                    ForEach(filteredStarters) { t in
                        PromptCard(title: t.title, preview: t.subtitle, category: t.category)
                            .onTapGesture { launch = PromptLaunch(text: t.promptText) }
                    }
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
        }
    }

    private func delete(_ p: SavedPrompt) {
        modelContext.delete(p)
        try? modelContext.save()
    }
}
