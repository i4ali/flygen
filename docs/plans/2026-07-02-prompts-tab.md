# Prompts Tab Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 5th "Prompts" tab: a browsable library of curated starter prompts (from `test-prompts.txt`) plus the user's own saved prompts, where tapping any prompt opens the chat with that text pre-filled.

**Architecture:** Curated prompts are a static Swift array (`PromptLibrary`, mirroring `SampleLibrary`). The user's prompts are a SwiftData `@Model` (`SavedPrompt`, mirroring `SavedFlyer`) synced via the existing private CloudKit DB. The tab reuses the existing `FlyerCategory` enum and `FilterPillButton` for category browsing. Tapping a prompt presents the existing `FlyerChatView` with a new optional `prefillText` parameter.

**Tech Stack:** SwiftUI, SwiftData + CloudKit, Xcode project (no SPM). iOS app in `FlyGen/FlyGen/`.

**Design doc:** `docs/plans/2026-07-02-prompts-tab-design.md`

---

## Conventions for this plan

- **No TDD / no Swift test target.** This repo's Swift side has no unit-test target, and the owner's workflow is to verify via **build + simulator**. So each task ends by **building** and, for UI tasks, a **manual simulator check** - not a failing-test-first loop.
- **Build command** (compile check, no booted sim needed):
  ```bash
  cd /Users/muhammadimranali/Documents/development/flygen/FlyGen
  xcodebuild -project FlyGen.xcodeproj -scheme FlyGen -destination 'generic/platform=iOS Simulator' build
  ```
  Expected: `** BUILD SUCCEEDED **`. (Or just press Cmd+B / Cmd+R in Xcode.)
- **⚠️ Target membership gotcha.** This `.xcodeproj` does **not** use file-system-synchronized folders. Creating a `.swift` file on disk does **not** add it to the build. For each NEW file below, you must add it to the **FlyGen target** (in Xcode: drag it into the matching group and check the "FlyGen" target, or via File > Add Files with the target ticked). If a build fails with "Cannot find type X in scope" right after adding a file, this is almost always the cause.
- **Commits.** Work is on `main` (no feature branches). Per the owner's preference, **commit only when the owner asks** - the "Commit" steps below are suggested checkpoints; batch or defer them to the owner's cadence.
- **New files (3):** `Models/SavedPrompt.swift`, `Data/PromptLibrary.swift`, `Views/Tabs/PromptsTab.swift`. To minimize target edits, `PromptTemplate` lives inside `PromptLibrary.swift`, and `PromptCard` / `PromptEditorSheet` / `PromptLaunch` live inside `PromptsTab.swift`.

---

## Task 1: `SavedPrompt` SwiftData model + schema registration

**Files:**
- Create: `FlyGen/FlyGen/Models/SavedPrompt.swift`
- Modify: `FlyGen/FlyGen/App/FlyGenApp.swift:29`

**Step 1: Create the model**

`FlyGen/FlyGen/Models/SavedPrompt.swift`:
```swift
import Foundation
import SwiftData

/// A prompt the user saved to reuse later. Mirrors `SavedFlyer`'s CloudKit-safe shape
/// (all non-optional stored properties have defaults + a no-arg init).
@Model
final class SavedPrompt {
    var id: UUID = UUID()
    var title: String = ""
    var text: String = ""
    var categoryRawValue: String = FlyerCategory.announcement.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {}   // required for CloudKit

    init(title: String, text: String, category: FlyerCategory) {
        self.id = UUID()
        self.title = title
        self.text = text
        self.categoryRawValue = category.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Typed accessor over the CloudKit-safe raw string.
    var category: FlyerCategory {
        get { FlyerCategory(rawValue: categoryRawValue) ?? .announcement }
        set { categoryRawValue = newValue.rawValue }
    }
}
```

**Step 2: Register it in the model container**

`FlyGen/FlyGen/App/FlyGenApp.swift:29` - add `SavedPrompt.self` to the schema:
```swift
let schema = Schema([SavedFlyer.self, UserProfile.self, BrandKit.self, SavedPrompt.self])
```

**Step 3: Add `SavedPrompt.swift` to the FlyGen target** (see the target-membership note above).

**Step 4: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

**Step 5: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Models/SavedPrompt.swift FlyGen/FlyGen/App/FlyGenApp.swift
git commit -m "feat(iOS): add SavedPrompt SwiftData model for the Prompts tab"
```

---

## Task 2: `PromptTemplate` + `PromptLibrary` (with seed entries)

Curated starters. This task adds the type and a few entries so the tab has content to test; Task 9 fills out the full set.

**Files:**
- Create: `FlyGen/FlyGen/Data/PromptLibrary.swift`

**Step 1: Create the file**

`FlyGen/FlyGen/Data/PromptLibrary.swift`:
```swift
import Foundation

/// A read-only starter prompt shown in the Prompts tab.
/// Curated from test-prompts.txt (QA scaffolding stripped).
struct PromptTemplate: Identifiable {
    let id: String
    let title: String        // user-facing, e.g. "School Newsletter Column"
    let subtitle: String     // one-line description shown on the card
    let promptText: String   // the actual text dropped into the chat composer
    let category: FlyerCategory
}

enum PromptLibrary {
    static let prompts: [PromptTemplate] = [
        PromptTemplate(
            id: "starter_newsletter_health",
            title: "School Newsletter Column",
            subtitle: "A health column for a school newsletter",
            promptText: """
            Need a flyer for the Health Corner column in our Northwest Saturday School newsletter. \
            Headline: Health Corner. It's the newsletter's health column for our school families. \
            Article: "Why Screen Time Matters" by Dr. Pareesa Nathani, Pediatrician. Keep it warm and \
            gentle, it's for parents. Add a "Learn More" and our site www.nwsaturdayschool.org
            """,
            category: .announcement
        ),
        PromptTemplate(
            id: "starter_majlis_program",
            title: "Majlis / Mourning Program",
            subtitle: "A solemn multi-night religious program",
            promptText: """
            Ashra-e-Sani majlis program at Markazi Imambargah Al-Murtaza, nightly from June 28th to \
            July 5th 2026. Program starts 8:40 PM each night right after Maghribain prayers. Guest \
            speaker Dr. Hasan Shaeba Rizvi from Canada. Hosted by Anjuman Alamdar e Hussain at 14903 \
            Belaire Blvd, Houston TX. al-murtaza.org
            """,
            category: .churchReligious
        ),
        PromptTemplate(
            id: "starter_grand_opening",
            title: "Grand Opening",
            subtitle: "Announce a new business opening",
            promptText: "Grand opening of Nova Nail Bar on Saturday, first 10 people get 50% off",
            category: .grandOpening
        )
    ]
}
```

**Step 2: Add `PromptLibrary.swift` to the FlyGen target.**

**Step 3: Build.** Expected: `** BUILD SUCCEEDED **`.

**Step 4: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Data/PromptLibrary.swift
git commit -m "feat(iOS): add PromptLibrary curated starter prompts (seed set)"
```

---

## Task 3: `FlyerChatView` accepts `prefillText`

Lets the tab open the chat with a prompt already in the composer (editable, not sent).

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatView.swift:8-9` (init) and `:44` (onAppear)

**Step 1: Add the parameter**

Replace lines 8-9:
```swift
    let seed: SampleFlyer?
    /// When present, the composer opens pre-filled with this text (editable, not auto-sent).
    let prefillText: String?
    init(seed: SampleFlyer? = nil, prefillText: String? = nil) {
        self.seed = seed
        self.prefillText = prefillText
    }
```

**Step 2: Add a one-shot guard state** (near the other `@State`/`@Environment` at the top of the struct, e.g. after line 13):
```swift
    @State private var didApplyPrefill = false
```

**Step 3: Apply it on appear**

Replace line 44 (`.onAppear { vm.start(seed: seed) }`) with:
```swift
            .onAppear {
                vm.start(seed: seed)
                if !didApplyPrefill, let prefillText, vm.composerText.isEmpty {
                    vm.composerText = prefillText
                    didApplyPrefill = true
                }
            }
```

**Step 4: Build.** Expected: success. Existing callers (`FlyerChatView(seed:)`, `FlyerChatView()`) are unaffected because `prefillText` defaults to `nil`.

**Step 5: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Chat/FlyerChatView.swift
git commit -m "feat(iOS): FlyerChatView can open with a pre-filled composer"
```

---

## Task 4: `FlyerChatViewModel.firstUserPrompt` helper

Used by "Save prompt from chat" (Task 8) to grab the user's first message.

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatViewModel.swift` (add near `canSend`, ~line 174)

**Step 1: Add the computed property**
```swift
    /// The first thing the user typed in this chat - the "prompt" worth saving to the library.
    var firstUserPrompt: String? {
        for bubble in transcript {
            if case .user(let text) = bubble.kind { return text }
        }
        return nil
    }
```

**Step 2: Build.** Expected: success.

**Step 3: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Chat/FlyerChatViewModel.swift
git commit -m "feat(iOS): expose firstUserPrompt on the chat view model"
```

---

## Task 5: `PromptsTab` scaffold - `PromptLaunch`, `PromptCard`, `PromptEditorSheet`

Create the tab file with its supporting pieces first (so Task 6 can assemble the body). `PromptEditorSheet` is `internal` (not `private`) so `FlyerChatView` can reuse it in Task 8.

**Files:**
- Create: `FlyGen/FlyGen/Views/Tabs/PromptsTab.swift`

**Step 1: Create the file with the supporting types** (the `PromptsTab` body itself is filled in Task 6 - start with a placeholder body so it compiles):
```swift
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

    /// `existing` = edit an existing saved prompt; `initialText` = prefill for a brand-new one.
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

// MARK: - Tab (body filled in Task 6)

struct PromptsTab: View {
    var body: some View {
        Text("Prompts").foregroundColor(FGColors.textPrimary)
    }
}
```

**Step 2: Add `PromptsTab.swift` to the FlyGen target.**

**Step 3: Build.** Expected: success. (`Form` inherits the app's global `.preferredColorScheme(.dark)`.)

**Step 4: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Views/Tabs/PromptsTab.swift
git commit -m "feat(iOS): add Prompts tab scaffold (card + editor sheet)"
```

---

## Task 6: Fill in the `PromptsTab` body

Replace the placeholder `PromptsTab` struct from Task 5 with the full implementation.

**Files:**
- Modify: `FlyGen/FlyGen/Views/Tabs/PromptsTab.swift` (the `PromptsTab` struct)

**Step 1: Replace the placeholder `struct PromptsTab` with:**
```swift
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
```

**Step 2: Build.** Expected: success. (`FilterPillButton` is the internal struct already defined in `ExploreTab.swift`, same module - reused here.)

**Step 3: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Views/Tabs/PromptsTab.swift
git commit -m "feat(iOS): implement Prompts tab body (browse, filter, save, edit, delete)"
```

---

## Task 7: Add the 5th tab to `ContentView`

**Files:**
- Modify: `FlyGen/FlyGen/App/ContentView.swift:195-206` (inside `MainTabView`'s `TabView`)

**Step 1: Insert the Prompts tab between Explore (tag 2) and Profile, and renumber Profile to tag 4.** Replace the `ExploreTab`/`ProfileTab` block:
```swift
            ExploreTab(viewModel: viewModel)
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }
                .tag(2)

            PromptsTab()
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble.fill")
                }
                .tag(3)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
```

**Step 2: Build + run in the simulator (Xcode Cmd+R).**

Manual checks:
- A "Prompts" tab appears (speech-bubble icon), 5 tabs total, no "More" overflow.
- The tab shows an empty "Your Prompts" nudge + "Starter Prompts" with the 3 seed cards.
- Tapping a starter opens the chat with its text already in the composer; you can edit it, then send.
- Category pills filter both sections; "All" restores everything.
- "+" opens the editor; saving a prompt makes it appear under "Your Prompts".
- Long-press a saved prompt -> Edit / Delete both work.

**Step 3: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/App/ContentView.swift
git commit -m "feat(iOS): add Prompts tab to the main tab bar"
```

---

## Task 8: "Save prompt to library" from the chat

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatView.swift` (add state ~line 14, a toolbar item ~line 39-43, and a sheet)

**Step 1: Add state** (after `@State private var didApplyPrefill = false` from Task 3):
```swift
    @State private var showingSavePrompt = false
```

**Step 2: Add a trailing toolbar button** inside the existing `.toolbar { ... }` (alongside the `topBarLeading` "Close"):
```swift
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSavePrompt = true } label: { Image(systemName: "bookmark") }
                        .foregroundColor(FGColors.textSecondary)
                        .disabled(vm.firstUserPrompt == nil)
                }
```

**Step 3: Present the editor sheet** - add after the `.onAppear { ... }` modifier:
```swift
            .sheet(isPresented: $showingSavePrompt) {
                PromptEditorSheet(initialText: vm.firstUserPrompt ?? "")
            }
```
(`PromptEditorSheet` writes through the environment's `modelContext`, which `FlyerChatView` already provides.)

**Step 4: Build + run in the simulator.**

Manual checks:
- Open the chat, send a first message. The bookmark button in the top-right enables.
- Tap it -> the editor opens prefilled with your message (title = first line, category = Announcement). Save.
- Go to the Prompts tab -> the saved prompt is under "Your Prompts".

**Step 5: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Chat/FlyerChatView.swift
git commit -m "feat(iOS): save a prompt to the library from the chat"
```

---

## Task 9: Curate the full starter library

Replace the seed `PromptLibrary.prompts` array (Task 2) with the full curated set drawn from `test-prompts.txt`. Each entry: clean title + one-line subtitle + prompt text (QA scaffolding removed) + a `FlyerCategory`.

**Files:**
- Modify: `FlyGen/FlyGen/Data/PromptLibrary.swift`

**Step 1: Replace the `prompts` array with (~14 entries):**
```swift
    static let prompts: [PromptTemplate] = [
        // Keep the 3 seed entries from Task 2 (newsletter, majlis, grand opening), then add:

        PromptTemplate(
            id: "starter_friday_prayer",
            title: "Friday Prayer (Jumma)",
            subtitle: "A reverent congregational prayer announcement",
            promptText: """
            Namaz-e-Jumma (Friday Prayer) at Markazi Imambargah Al-Murtaza, Friday June 26th 2026 at \
            1:24 PM. Led by the Khateeb of Haram-e-Imam Raza, Maulana Mujahid Hussain Naqvi. Hosted by \
            Anjuman Alamdar e Hussain at 14903 Belaire Blvd, Houston TX. al-murtaza.org
            """,
            category: .churchReligious
        ),
        PromptTemplate(
            id: "starter_weekend_sale",
            title: "Weekend Sale",
            subtitle: "A time-boxed retail promotion",
            promptText: "Summer clearance at Bloom Boutique - 40% off all dresses this weekend only, Sat & Sun 10-6",
            category: .salePromo
        ),
        PromptTemplate(
            id: "starter_live_music",
            title: "Live Music Night",
            subtitle: "A concert or band night",
            promptText: "Indie folk showcase at The Greenhouse, Friday Nov 14, doors 7pm, three bands, $20 advance, tickets at greenhouse.com",
            category: .musicConcert
        ),
        PromptTemplate(
            id: "starter_charity_5k",
            title: "Charity 5K",
            subtitle: "A fundraising run/walk",
            promptText: "Charity 5K for the local food bank, Saturday June 28 at 8am, Riverside Park, register at run.example.org",
            category: .nonprofitCharity
        ),
        PromptTemplate(
            id: "starter_open_house",
            title: "Open House",
            subtitle: "A real-estate showing",
            promptText: "Open house this Sunday 1-4pm at 14 Maple Court, modern 3-bed with a renovated kitchen, hosted by Sarah Lin Realty",
            category: .realEstate
        ),
        PromptTemplate(
            id: "starter_now_hiring",
            title: "Now Hiring",
            subtitle: "A help-wanted flyer",
            promptText: "Now hiring baristas at Daybreak Coffee - part-time, flexible hours, apply in store at 88 Front St",
            category: .jobPosting
        ),
        PromptTemplate(
            id: "starter_pottery_workshop",
            title: "Pottery Workshop",
            subtitle: "A multi-session class",
            promptText: "Beginner pottery workshop Thursday evenings in July, 6-8pm at the Clay Studio, $120 for four sessions",
            category: .classWorkshop
        ),
        PromptTemplate(
            id: "starter_kids_birthday",
            title: "Kids Birthday Party",
            subtitle: "A children's party invite",
            promptText: "Birthday party for my daughter turning 7, Saturday 2pm at our house, superhero theme, RSVP by text",
            category: .partyCelebration
        ),
        PromptTemplate(
            id: "starter_taco_tuesday",
            title: "Taco Tuesday",
            subtitle: "A recurring restaurant special",
            promptText: "Taco Tuesday at El Jardin - $2 street tacos every Tuesday from 5pm, live mariachi at 7",
            category: .restaurantFood
        ),
        PromptTemplate(
            id: "starter_yard_sale",
            title: "Neighborhood Yard Sale",
            subtitle: "A community sale",
            promptText: "Flyer for a neighborhood yard sale, Saturday 8am-2pm on Elm Street, furniture, toys, and tools",
            category: .event
        ),
        PromptTemplate(
            id: "starter_rooftop_yoga",
            title: "Rooftop Yoga",
            subtitle: "A recurring fitness class",
            promptText: "Sunrise rooftop yoga Saturdays at 7am on the Lofthouse terrace, $18 drop-in, mats provided",
            category: .fitnessWellness
        )
    ]
```
Note: subtitles are what the card shows as the preview (cleaner than the full prompt). Adjust wording/entries freely; keep religious prompts on `.churchReligious`.

**Step 2: Build + run.** Manual: the Starter Prompts list shows all entries; the pill row now includes their categories; filtering works.

**Step 3: Commit (suggested checkpoint)**
```bash
git add FlyGen/FlyGen/Data/PromptLibrary.swift
git commit -m "feat(iOS): curate the full starter prompt library"
```

---

## Task 10: Final verification + release checklist

**Step 1: Full build.** Run the build command -> `** BUILD SUCCEEDED **`.

**Step 2: End-to-end simulator pass:**
- All 5 tabs load; existing tabs (Home, My Flyers, Explore, Profile) unchanged.
- Explore's "Use as Starting Point" still opens a seeded chat (regression check - Task 3 changed `FlyerChatView`'s init; the `seed:` path must still work).
- Prompts: browse, filter, tap-to-prefill, "+ New" save, edit, delete, save-from-chat.
- Kill and relaunch the app: saved prompts persist (SwiftData).

**Step 3: No engine redeploy needed.** This change is iOS-only; nothing under `engine/` or the root Python modules changed, so the Cloud Run engine is untouched.

**Step 4: ⚠️ Before any TestFlight/App Store release - deploy the CloudKit schema.** `SavedPrompt` is a new CloudKit record type. In the CloudKit Console, promote the schema **Development -> Production** ("Deploy Schema Changes..."), or saved-prompt sync fails silently in production builds. (Development/simulator auto-creates the schema, so it works locally without this step.)

**Step 5: Commit anything outstanding (suggested checkpoint).**

---

## Out of scope (v1)

Sharing/exporting prompts, folders, manual reordering, editing the curated set (to tweak a starter, save your own copy). A saved prompt stores title + text + category only.
