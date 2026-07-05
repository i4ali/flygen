# Handoff: FlyGen "Aurora" Premium Redesign

## Overview
This package documents the **Aurora** visual direction for FlyGen — an AI flyer-generation iOS app. It is a full restyle of the existing flow to feel premium: a controlled indigo→cyan accent replacing the old electric-purple gradient, glass-like surfaces on a cool near-black base, a single precise typeface (Space Grotesk), and a consistent custom line-icon set replacing the emoji category icons.

The flow itself is unchanged from the PRD (`PRD.md` in the repo): a 9-step guided intake → generation → result, plus Home, Premium/paywall, gallery, and profile. This handoff covers the **8 hero screens** that define the language. Screens not drawn here (Mood, Colors, Format, Text-mode, Extras, My Flyers, Profile/Settings) reuse the exact same components documented below and should be built in the same language.

## About the Design Files
The file in this bundle (`FlyGen Premium Redesign.dc.html`) is a **design reference created in HTML** — a prototype showing the intended look and behavior, not production code to copy. The Aurora direction is the section tagged **`1B`** inside that file (the file also contains two alternate directions, `1A` Studio and `1C` Canvas, which were **not** chosen — ignore them).

The task is to **recreate the Aurora screens in FlyGen's existing SwiftUI codebase** (`uploads/flygen/FlyGen/`), using its established patterns (SwiftUI views, `FlyerProject` models from the PRD, existing navigation and view-models). Do not ship the HTML. Where this doc gives pixel values, reproduce them faithfully with SwiftUI equivalents (`Color(hex:)`, `.font(.custom("SpaceGrotesk-…"))`, `RoundedRectangle`, etc.).

## Fidelity
**High-fidelity.** Final colors, typography, spacing, radii, and interaction intent are specified. Recreate the UI pixel-accurately with the app's existing libraries. All measurements below are given at the mockup's logical scale — a 372pt-wide phone (≈ iPhone screen width), so values map directly to SwiftUI points.

---

## Design Tokens

### Color
| Token | Hex / value | Use |
|---|---|---|
| `bg/base` | `#0A0B0F` | Screen background (cool near-black) |
| `bg/gen` | radial `#161A30` → `#0A0B0F` | Generating & paywall top-glow backgrounds |
| `surface` | `#13151B` | Cards, inputs, pills, secondary buttons, tiles |
| `surface/flyer` | `#12162E` → `#0B0D18` | Result flyer canvas gradient |
| `border/card` | `rgba(255,255,255,0.07)` | Card & input borders |
| `border/hairline` | `rgba(255,255,255,0.06)` | Dividers, hero panel, tab-bar top |
| `text/primary` | `#EDEFF4` | Headlines, primary labels |
| `text/secondary` | `#8A90A0` | Body copy, sublabels |
| `text/tertiary` | `#565C6B` | Field labels, meta, inactive tab, step count |
| `text/onCardBody` | `#DDE0E8` | Filled input values |
| `text/onCardLabel` | `#B4BAC8` | Input field labels |
| `accent/indigo` | `#7C8CF8` | Primary accent: active states, icons, rings |
| `accent/indigoDeep` | `#8B7CF8` | Gradient end for CTAs |
| `accent/cyan` | `#63E6D2` | Secondary accent: live dot, brand gradient, highlights |
| `brand/gradient` | `linear-gradient(140deg,#7C8CF8,#63E6D2)` | Logo mark, premium badge |
| `cta/gradient` | `linear-gradient(135deg,#7C8CF8,#8B7CF8)` | Primary buttons |
| `selection/ring` | `rgba(124,140,248,0.12)`, 3pt outer | Selected card/input glow |
| `segment/inactive` | `#20222C` | Progress dash (unfilled) |

### Typography — **Space Grotesk** (single family, weights 400/500/600/700)
| Role | Size | Weight | Tracking | Color |
|---|---|---|---|---|
| Screen title | 29 | 700 | -0.035em | `text/primary` |
| Hero title (Home) | 30 | 700 | -0.035em | `text/primary` |
| Section / result title | 16 | 600 | -0.02em | `text/primary` |
| Wordmark | 19 | 700 | -0.03em | `text/primary` |
| Body / subtitle | 14.5 | 400 | 0 | `text/secondary` |
| Field value (filled) | 16 | 600 | 0 | `text/primary` |
| Field label | 13 | 400 | 0 | `text/tertiary` |
| Review row label | 11.5 | 500 | +0.08em, UPPERCASE | `text/tertiary` |
| Button label | 16 | 600 | 0 | `#FFFFFF` on gradient |
| Step count / meta | 12–12.5 | 500 | 0 | `text/tertiary` |
| Tab label | 11 | 400/600 | 0 | active `accent/indigo` / inactive `text/tertiary` |

iOS: bundle the Space Grotesk `.ttf` weights and register in Info.plist, or use the closest available. Numerals read as tabular — fine for the credit counter and step counts.

### Radius
| Element | Value (pt) |
|---|---|
| Phone screen (mock only) | 36 |
| Cards (category, style, review row, action tile) | 14–18 |
| Inputs | 12 |
| Primary/secondary buttons | 15 |
| Pills, credit chip, required chip | 100 (full) |
| Logo mark | 8 |
| Icon chips (in cards) | 12 |
| Small squares (QR, tiles) | 6–8 |

### Spacing
- Screen horizontal padding: **24pt** (buttons area 22pt).
- Bottom safe padding: **30pt** for CTA/tab rows.
- Field vertical gap: **15pt**; card grid gap: **12–13pt**.
- Input padding: **15pt v / 16pt h**; card padding: **18pt v / 16pt h**.
- Section header → content: **~12–14pt**.

### Shadow / Elevation
- Primary CTA glow: `0 14px 34px -12px rgba(124,140,248,0.7)` (indigo drop, no spread).
- Result flyer card: `0 24px 50px -18px rgba(0,0,0,0.8)` + `0 0 0 1px rgba(124,140,248,0.2)` ring.
- Selected card: `0 0 0 3px rgba(124,140,248,0.12)` outer ring + `1.5pt #7C8CF8` border.

---

## Screens / Views

Every screen shares a **status bar** (system) and a **24pt-padded content column** on `bg/base`. Screen order follows the PRD's 9-step wizard.

### 1. Home
- **Purpose:** Entry point — start a flyer, browse templates, see recents.
- **Layout:** Vertical stack. Top nav row → hero panel → headline block → CTA stack → Recent strip → bottom tab bar (pinned).
- **Components:**
  - **Top nav:** left = logo mark (26×26, 8-radius, `brand/gradient`) + wordmark "FlyGen" (19/700). Right = credits pill (`surface`, 1pt `border/card`, 10-radius; 7pt `accent/cyan` dot with `0 0 8px #63E6D2` glow; label "10 credits" 14/600 `text/primary`) + settings gear (21pt, `text/secondary`).
  - **Hero panel:** 158pt tall, 20-radius, `radial-gradient(90% 120% at 30% 10%, #1C2140, #0D0F18)`, 1pt `border/hairline`. Overlaid 26pt dotted grid (`rgba(124,140,248,0.09)`, 26pt cells). Centered: 92pt conic-gradient orb (`from 200deg, #7C8CF8, #63E6D2, #7C8CF8`, blur 1) masked by a 60pt `#0D0F18` disc, white sparkle glyph on top.
  - **Headline:** "Design-grade flyers, generated in seconds" — 30/700/-0.035em, `text/primary`. Sub: "A guided brief in, a polished layout out." 14.5, `text/secondary`.
  - **Primary CTA:** "New flyer" with leading + icon, 56pt, 15-radius, `cta/gradient`, white 16/600, CTA glow.
  - **Secondary CTA:** "Browse templates" with leading stacked-pages icon, 54pt, `surface`, 1pt border, `text/primary` 15/500.
  - **Recent:** header "Recent" (14/600) + "All" (13, `accent/indigo`). Row of 3 cards, 4:5, 12-radius, subtle `#1A1D2B`→`#111420` gradient fills, 1pt hairline. (In production these are the user's last 3 generated flyers.)
  - **Tab bar:** pinned bottom, 1pt `border/hairline` top, `rgba(0,0,0,.15)`-ish. 4 items — Home (active `accent/indigo`), Flyers (grid), Premium (crown), Profile (user). Icons 22pt, labels 11pt.

### 2. Category (Step 1)
- **Purpose:** Pick flyer type; sets which fields appear later.
- **Layout:** Progress row → title block → 2-col category grid → Continue.
- **Components:**
  - **Progress row:** back chevron (22pt `text/secondary`) + **9 segment dashes** (each `flex:1`, 3pt tall, 100-radius, 4pt gap; filled = `accent/indigo`, empty = `segment/inactive`) + step count "01/09" (12/500 `text/tertiary`). This is the wizard's progress indicator across all steps.
  - **Title:** "What are you making?" 29/700. Sub: "Sets the fields for the next steps."
  - **Category card (grid, 2-col, 12 gap):** `surface`, 1pt border, 16-radius, 18/16 padding. Icon chip 42×42, 12-radius, `rgba(255,255,255,0.05)` (or `rgba(124,140,248,0.16)` when selected) with a line icon. Title 15/600 `text/primary`, sub 12 `text/tertiary`. **Selected state:** 1.5pt `#7C8CF8` border + 3pt `selection/ring`, indigo-tinted chip + indigo icon.
  - Six shown in mock (Event selected, Sale, Grand Opening, Restaurant, Workshop, Party) — production shows all 12 from PRD.
  - **Continue button:** primary CTA, "Continue" + trailing arrow.

### 3. Text Content (Step 3)
- **Purpose:** Enter headline + category-specific fields.
- **Layout:** Progress → title → field stack → Continue.
- **Components:**
  - **Field:** label row (label 13 `text/onCardLabel`; a "Required" tag 12 `accent/indigo` on the headline) → input box (15/16 padding, 12-radius, `surface`, 1pt border). **Focused/filled headline:** 1.5pt `#7C8CF8` border + 3pt `selection/ring`, value 16/600 `text/primary`. Empty fields show placeholder in `text/tertiary`.
  - Fields in mock: Headline (required, filled "Summer Nights Market"), Date & time, Venue, Call to action (empty). Field set is **dynamic per category** — see PRD §3.4 / §12.1 mapping.
  - **"More fields":** dashed 1pt `rgba(124,140,248,0.35)` pill, `accent/indigo` label + plus icon — expands optional fields.

### 4. Visual Style (Step 4)
- **Purpose:** Pick the aesthetic; each card previews the look.
- **Layout:** Progress → title → 2-col style grid → Continue.
- **Components:**
  - **Style card:** 15-radius, clipped. Top = 96pt preview swatch (a representative fill: Minimal = light `#EDEFF4` with a bar; Gradient = `#7C8CF8→#63E6D2`; Bold = dark with ring; Neon = blurred cyan glow; Elegant = "Aa"; Retro = diagonal stripes). Footer = `surface`, 11/13 padding, name 13.5/600. **Selected:** 1.5pt `#7C8CF8` border + 3pt ring + filled check-circle (indigo, white check) in footer.
  - 10 styles total per PRD §3.5; 6 shown in mock.

### 5. Review & Generate (Step 9)
- **Purpose:** Summary of all choices; jump back to edit; trigger generation.
- **Layout:** Progress (all filled) → title → summary rows → Generate CTA + credit note.
- **Components:**
  - **Review row:** full-width `surface` card, 1pt border, 13-radius, 15/16 padding. Left = uppercase label (11.5/+0.08em `text/tertiary`) + value (15/600 `text/primary`); Palette row shows 3 × 18pt swatches (`#7C8CF8`, `#63E6D2`, `#EDEFF4`). Right = chevron (`text/tertiary`). Tapping a row navigates to that step.
  - Rows: Category, Headline, Style & mood, Palette (Format also in production).
  - **Generate CTA:** primary, sparkle icon + "Generate", CTA glow. Below: "Uses 1 credit · 9 remaining" (12.5 `text/tertiary`, centered).

### 6. Generating (loading)
- **Purpose:** Progress state during AI generation.
- **Layout:** Centered column on `bg/gen` radial background.
- **Components:**
  - **Spinner:** 120pt conic-gradient ring (`from 0deg, #7C8CF8, #63E6D2, #7C8CF8`) rotating (**1.6s linear, infinite**), masked by a 108pt `#0D1020` disc, sparkle glyph centered.
  - Title "Generating your flyer" 26/700. Sub "Compositing type, color and layout…" 14.5 `text/secondary`.
  - **Step checklist** (max 250pt wide, 14 gap): completed rows = filled indigo check-circle + `text/primary` 14; in-progress row = dashed indigo circle + label pulsing (**opacity 0.4↔1, 1.5s ease-in-out**); pending row = hollow `#22242E` circle + `text/tertiary`. Steps: Parsed brief ✓ · Selected typography ✓ · Rendering artwork (active) · Final polish (pending).
  - Footer "~20 seconds remaining" 12.5 `text/tertiary`.

### 7. Result / Your Flyer
- **Purpose:** View the generated flyer; refine, resize, save, or keep.
- **Layout:** Top bar (close / title / share) → flyer preview → action trio → Keep CTA.
- **Components:**
  - **Top bar:** close tile (38×38, 11-radius, `surface`, 1pt border, X icon) · "Your flyer" 16/600 · share tile (same, indigo share-up icon).
  - **Flyer card:** 4:5, 18-radius, result-card shadow + indigo ring. *(The real image is the AI output; the mock shows a representative composition — date kicker in `accent/cyan`, big Space-Grotesk headline, venue + QR block, cyan radial highlight top-right.)*
  - **Action trio:** 3 equal tiles, 14-radius, `surface`, 1pt border, indigo line icon + 12.5 label — **Refine** (refresh), **Resize** (frame/split), **Save** (download).
  - **Keep CTA:** primary "Keep this one", CTA glow.

### 8. Premium / Paywall
- **Purpose:** Convert to FlyGen Pro.
- **Layout:** Close (top-right) → badge + title + sub → feature list → plan cards → trial CTA → legal.
- **Components:**
  - **Badge tile:** 64×64, 20-radius, `brand/gradient`, dark crown glyph, indigo glow.
  - **Title:** "FlyGen **Pro**" — "Pro" filled with `brand/gradient` (gradient text). Sub "Unlimited flyers, no watermark, every style."
  - **Feature rows:** indigo-tinted check-circle (`rgba(124,140,248,0.18)` fill, `#7C8CF8` check) + 14.5 `text/onCardBody`. Items: Unlimited generations · No watermark, HD export · Logo upload & brand kit.
  - **Plan card:** 15-radius, 16/18 padding. **Yearly (selected):** `surface`, 1.5pt `#7C8CF8` border + 3pt ring; "SAVE 50%" badge (`brand/gradient`, dark text, 100-radius, top-right, overlapping) + filled indigo radio-check. "$59.99 / yr · $5/mo". **Monthly:** `surface`, 1pt border, hollow radio. "$9.99 / mo".
  - **Trial CTA:** primary "Start 7-day free trial", CTA glow. Legal "Restore · Terms · Privacy" 11.5 `text/tertiary`.

---

## Interactions & Behavior
- **Wizard nav:** 9 steps; progress dashes fill as steps complete. Back chevron pops one step; each Review row deep-links to its step. Persist draft on every transition (PRD §9.3).
- **Selection:** category/style/plan cards animate to the selected treatment (border + 3pt ring appear) on tap — single-select per screen. Suggested: 150ms ease.
- **Generate:** Review → push Generating → on success push Result; on failure show error state with retry (PRD §9.1). Decrement credits by 1 on success.
- **Result actions:** Refine and Resize open sheets (refine = feedback text + quick chips per PRD §3.14; resize = format picker §3.15). Save writes to Photos. Keep → Done → My Flyers.
- **Animations:** spinner ring 1.6s linear rotate; active checklist row opacity pulse 1.5s ease-in-out; live credit dot may softly pulse its glow. Keep motion subtle and precise — no bounce.
- **Paywall:** tap a plan to select (radios swap); CTA reflects selected plan's trial/price.

## State Management
Reuse the PRD's `FlyerProject` draft model (§4.1) plus:
- `currentStep: Int` (1…9), `selections` (category, textContent, visualStyle, mood, colors, format, textMode, extras).
- `credits: Int`, `subscriptionTier`, `selectedPlan` (paywall).
- `generationStatus: .idle | .generating | .success | .failed` driving the Generating screen.
- Draft autosave/restore per PRD §9.3. Data fetching = existing image-generation service (PRD §5.1) — this redesign changes presentation only, not the API.

## Icons / Assets
The mock uses a **custom line-icon set** (1.6–1.8pt stroke, rounded joins) that replaces the old emoji. On iOS, map to **SF Symbols** (weight ≈ `.regular`/`.medium`, `.hierarchical` or tinted `accent/indigo`):

| Mock icon | SF Symbol |
|---|---|
| Home | `house` |
| Grid (Flyers) | `square.grid.2x2` |
| Crown (Premium) | `crown` |
| User (Profile) | `person` / `person.crop.circle` |
| Settings | `gearshape` |
| Plus | `plus` |
| Chevron / arrow | `chevron.left`, `arrow.right`, `chevron.right` |
| Sparkle (brand/generate) | `sparkles` |
| Refine | `arrow.triangle.2.circlepath` |
| Resize | `rectangle.split.2x1` |
| Save | `arrow.down.to.line` |
| Share | `square.and.arrow.up` |
| Check-circle | `checkmark.circle.fill` |
| Close | `xmark` |
| Category — Event/Sale/Grand Opening/Restaurant/Workshop/Party | `building.columns`/`tag`/`party.popper`/`fork.knife`/`graduationcap`/`balloon` (or brand line icons) |

- **Logo mark & orb / flyer artwork:** decorative; the orb and flyer canvas are built from gradients (no raster asset needed). The real flyer image is the AI generation output.
- **Font:** Space Grotesk (Google Fonts / OFL) — bundle the .ttf weights.

## Files
- `FlyGen Premium Redesign.dc.html` — the HTML prototype. **Aurora = section `1B`.** Open it in the design tool to inspect exact spacing/colors live. (Contains two unused alternates, `1A` and `1C` — ignore.)
- `PRD.md` (in repo root) — source of truth for flow, data models, category→field mapping, monetization, error states. This redesign restyles that flow without changing its logic.
- Target codebase: `uploads/flygen/FlyGen/` (SwiftUI).
