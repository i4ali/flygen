# Prompts tab - a library of starter prompts + the user's saved prompts

Date: 2026-07-02
Status: Approved, ready for implementation plan

## Goal

Add a new tab that gives users a **library of prompts** to feed the chat:

1. **Starter prompts** - a curated, read-only set (sourced from `test-prompts.txt`) so a new user
   can tap one to try the app or use it as a starting point.
2. **Your prompts** - the user's own saved prompts, so a prompt they crafted can be reused later.

Both are **browsable by category** (reusing the existing `FlyerCategory`), so a user can find,
say, the newsletter or church/religious starters quickly. Tapping any prompt opens the chat with
that text pre-filled so they can tweak the details before sending.

This is the text-prompt sibling of the existing Explore tab, which does the same "use as a starting
point" idea but from finished sample *images*. Prompts is text-first.

## Decisions (from brainstorming)

- **Placement = a new dedicated 5th tab** (not folded into Explore). Explore is image samples;
  Prompts is text starters + the user's personal saved prompts. Personal (mutable) data wants its
  own home rather than living inside a browse-inspiration tab. iOS shows 5 tabs with no overflow.
- **Name = "Prompts."** Honest about what it is and teaches the mental model ("text you send the chat").
- **Tap a prompt = open the chat with it pre-filled and editable** (not auto-sent, not clipboard).
  Matches "use as a starting point" and lets the user swap in their own date/venue/etc. first.
- **Saving = both entry points.** A "+ New" composer in the tab, AND a "Save this prompt" action in
  the chat.
- **Category filter drives BOTH sections** (your prompts + starters) at once.
- **"+ New" is a full form** (title + prompt text + category), not a lighter capture.

## Data

Two kinds, mirroring how Explore already separates curated content from saved content.

### Curated starters (static, read-only) - like `SampleLibrary`

```
struct PromptTemplate: Identifiable {
    let id: String
    let title: String        // user-facing, e.g. "School Newsletter Column"
    let subtitle: String     // one line, e.g. "A health column for a school newsletter"
    let promptText: String   // the actual prompt sent to the chat
    let category: FlyerCategory
}

enum PromptLibrary { static let prompts: [PromptTemplate] = [ ... ] }
```

Hand-curated from `test-prompts.txt` with all QA scaffolding stripped. Bundled in-app; no network.

### User's saved prompts (SwiftData + CloudKit) - like `SavedFlyer`

```
@Model final class SavedPrompt {
    var id: UUID = UUID()
    var title: String = ""
    var text: String = ""
    var categoryRawValue: String = ""   // FlyerCategory.rawValue (CloudKit-safe String)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    init() {}                            // required for CloudKit
    var category: FlyerCategory { FlyerCategory(rawValue: categoryRawValue) ?? .announcement }
}
```

All non-optional properties have defaults (CloudKit requirement). Added to the `Schema([...])` in
`FlyGenApp`, so saved prompts sync across the user's devices via the existing private CloudKit DB.

**Release caveat:** adding `SavedPrompt` to the schema is a CloudKit schema change. It must be
deployed Dev -> Production in the CloudKit Console before shipping, or sync fails silently in
TestFlight/App Store builds.

## Information architecture

Tab bar becomes: `Home · My Flyers · Explore · Prompts · Profile`.
- **Name:** "Prompts"  **Icon:** `text.bubble.fill`  **Position:** index 3 (between Explore and Profile).

## Layout (`PromptsTab`)

A single `NavigationStack`, dark theme, reusing FG design tokens (`FGColors`, `FGSpacing`, `FGTypography`).

- Nav title "Prompts"; toolbar trailing **"+"** -> New Prompt composer.
- **Category filter pills** - reuse the existing `FilterPillButton` + "All" default. Categories shown
  are those present across the curated set + the user's saved prompts. The selected category filters
  **both** sections below.
- **"Your Prompts"** section - a vertical list of `PromptCard`s.
  - Tap -> open chat pre-filled. Swipe-to-delete. Long-press / context menu -> Edit.
  - Empty state (no saved prompts): a slim nudge card - "Save prompts you'll reuse. Tap + to add one,
    or save one from a chat."
- **"Starter Prompts"** section - the curated list as `PromptCard`s, filtered by the selected category.
- **`PromptCard`** (text-first, no image): title (`labelLarge`) + a 2-line preview of the prompt text
  (`textSecondary`) + a category chip (`caption`). Styled like `SampleThumbnailView`
  (elevated background, subtle border, card radius) but a single-column list (text reads better than a grid).

## Interactions

### Tap a prompt -> pre-filled chat

Present `FlyerChatView` via a `fullScreenCover(item:)` driven by a small `Identifiable` launch wrapper
carrying the prompt text.

- New optional init param `FlyerChatView(prefillText: String? = nil)`. Default `nil`, so existing
  callers (Explore seed, Home) are untouched.
- On appear: run the normal chat greeting (`start()`), then set the composer's text binding to
  `prefillText`. The text is **editable and not sent** - the user reviews/edits, then taps send.

### "+ New" / Edit -> `PromptEditorSheet`

A sheet with: Title field, multiline Prompt editor, Category picker (the `FlyerCategory` list). Save
inserts a new `SavedPrompt` (or updates an existing one, bumping `updatedAt`). Validation: non-empty text.

### Save from the chat

A "Save prompt to library" action in `FlyerChatView`'s toolbar, enabled once the user has sent their
first message. It opens the same `PromptEditorSheet` prefilled with that message text (title defaults to
the first line, category defaults to `.announcement`), then saves a `SavedPrompt`.

## Curated content

Hand-curate ~12-18 starters from `test-prompts.txt`. Each entry = clean title + one-line subtitle + the
prompt text (the `>` lines, joined) + a `FlyerCategory`. Drop all QA scaffolding ("should hit the design
gate", "what to look for", etc.). Indicative set:

- School Newsletter Column - `announcement`
- Majlis / Mourning Program - `churchReligious`
- Friday Prayer (Jumma) - `churchReligious`
- Grand Opening - `grandOpening`
- Weekend Sale - `salePromo`
- Live Music Night - `musicConcert`
- Charity 5K - `nonprofitCharity`
- Open House - `realEstate`
- Now Hiring - `jobPosting`
- Pottery Workshop - `classWorkshop`
- Kids Birthday Party - `partyCelebration`
- Taco Tuesday (restaurant) - `restaurantFood`

## Files

New:
- `Models/SavedPrompt.swift` - the `@Model`.
- `Data/PromptLibrary.swift` - the `PromptTemplate` struct + the curated `prompts` array.
- `Views/Tabs/PromptsTab.swift` - the tab, `PromptCard`, `PromptEditorSheet` (a launch wrapper too).

Edit:
- `App/FlyGenApp.swift` - add `SavedPrompt.self` to the schema.
- `App/ContentView.swift` - add the 5th tab.
- `Chat/FlyerChatView.swift` - add `prefillText` param + the "Save prompt to library" action.
- `Chat/FlyerChatViewModel.swift` - small helper to expose the composer text / first user message.

## Out of scope (v1)

- No sharing, exporting, or cross-user prompt marketplace.
- No folders, tags beyond category, or manual reordering.
- The curated set is read-only (to tweak a starter, save your own copy).
- A saved prompt stores text + title + category only (no photos or structured color/visual settings).

## Verification

- Build Debug for the simulator; confirm it compiles.
- Manual: add a prompt via "+ New"; filter by category (both sections react); tap a starter -> chat
  opens with the text pre-filled and editable; save a prompt from a chat; edit and delete a saved prompt.
- Confirm existing chat entry points (Explore seed, Home) still work (prefill defaults to nil).
- Before release: deploy the CloudKit schema Dev -> Production (new `SavedPrompt` record type).
