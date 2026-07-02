# Save chat flyers to My Flyers - design

Date: 2026-07-01
Status: Approved, implementing

## Problem

The chat flow produces flyer concepts (`ConceptDTO`: a base64 image + `version_id`), and
its only "Save" action writes to the iOS Photos camera roll (`PhotoLibraryService`). A
chat-made flyer never enters the SwiftData store, so it never appears in the **My Flyers**
tab (`GalleryTab`, driven by `@Query` over `SavedFlyer`). The classic step-by-step flow, by
contrast, persists via `ResultView.saveToGallery()`.

Goal: let the user save a chat concept into My Flyers, alongside the existing Save-to-Photos.

## Decisions (approved)

1. **Add a second button.** Keep "Save to Photos" as-is; add a distinct "+ My Flyers"
   button on each concept card.
2. **Origin flag lives inside `FlyerProject`** (Option B), not as a new `SavedFlyer`
   property. `FlyerProject` is JSON-encoded into `SavedFlyer.projectData`, which CloudKit
   treats as one opaque blob, so this is **not** a CloudKit schema change and needs no
   schema deploy. Backward-compatible: existing flyers decode `origin == nil` = classic.
3. **Hide "Use as Template"** in the flyer detail sheet for chat-origin flyers (their
   design recipe is only a lightweight approximation, so reopening the classic wizard would
   be misleading). They keep Save-to-Photos + Share.

## Data flow

```
Concept card "+ My Flyers" tap
  -> ExtractedBriefDTO (viewModel.brief) -> FlyerProject  (category + all captured text, origin = .chat)
  -> concept image -> GeneratedFlyer
  -> SavedFlyer(project:generatedFlyer:)                  (existing initializer, reused)
  -> modelContext.insert + save                           (GalleryTab @Query auto-updates + iCloud sync)
```

`FlyerChatView` gains `@Environment(\.modelContext)`. The `ExtractedBriefDTO -> FlyerProject`
mapping lives in `FlyerChatViewModel.chatFlyerProject()` (Chat layer, keeps `brief` private and
`Models/` decoupled from chat DTOs). It is a view-model method rather than a new file because the
Xcode project uses the classic `.pbxproj` format (no synchronized file groups), so a new source
file would need manual project registration.

## Mapping: ExtractedBriefDTO -> FlyerProject

`brief.category` (String) -> `FlyerCategory(rawValue:)` (engine uses the same snake_case
vocabulary, e.g. `church_religious`); fallback `.announcement` if unrecognized.

TextContent is near 1:1:

| brief            | TextContent    |
|------------------|----------------|
| headline         | headline       |
| subheadline      | subheadline    |
| body_text        | bodyText       |
| date             | date           |
| time             | time           |
| venue_name       | venueName      |
| address          | address        |
| price            | price          |
| discount_text    | discountText   |
| cta_text         | ctaText        |
| phone            | phone          |
| email            | email          |
| website          | website        |
| social_handle    | socialHandle   |
| additional_info  | additionalInfo |

`brief.purpose` -> `FlyerProject.specialInstructions` (if present). Colors/visuals/output
keep their defaults (the chat engine chose the real look server-side; not captured).

## UX details

- After a successful add, the button flips to "Added" + disables for that concept
  (tracked by `version_id`) to prevent duplicate inserts within the session.
- The detail sheet's "model" info row is hidden when the stored model string is empty
  (chat flyers have no per-concept model name).

## Non-goals

- No change to the engine, the classic creation flow, or Save-to-Photos.
- No "continue in chat" / resume-from-saved (future work; that is why Use-as-Template is
  hidden rather than repurposed for chat flyers).

## Verification

Build + run in the simulator: make a flyer in chat -> "+ My Flyers" -> confirm it appears in
My Flyers, opens in detail without "Use as Template," and that classic flyers still show it.
