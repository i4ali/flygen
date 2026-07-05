# Aurora Redesign - Design Spec

**Date:** 2026-07-03
**Status:** Design (awaiting owner review before implementation plan)
**Source:** `design_handoff_aurora_redesign/` (Aurora = section `1B`; ignore `1A` Studio and `1C` Canvas)

## Goal

Restyle the **existing chat-first FlyGen app** into the Aurora visual language: a controlled
indigo→cyan accent on a cool near-black base, glass-like surfaces, a single precise typeface
(Space Grotesk), and a consistent SF-Symbol line-icon set.

This is **presentation only**. No flow changes, no features added or removed, no engine / CloudKit /
StoreKit changes. The handoff draws the old 9-step wizard, but that flow is disabled in the app
(`FeatureFlags.classicCreationEnabled = false`); chat is the only live creation path. We apply
Aurora's *language* to the current screens - we do **not** rebuild the wizard.

## Confirmed decisions

1. **Typeface → bundle Space Grotesk** (OFL weights 400/500/600/700). Faithful to Aurora's identity.
2. **Tab bar → custom Aurora tab bar** (flat `#0A0B0F`, hairline top, indigo active). Native `TabView`
   in iOS 26 resists exact flat-dark styling; a custom bar guarantees fidelity.
3. **Home hero → Aurora hero panel** (dotted-grid glass card + conic indigo/cyan orb + sparkle),
   replacing the animated flyer-card stack.

**Confirmed product decisions (2026-07-04):**
4. **No Recents strip on Home.** Aurora draws one, but we deliberately exclude it (honors
   "don't add"). Home = orb hero panel + CTA only. Do not re-add it during implementation.
5. **Generate + result stay inline in the chat thread**, restyled to Aurora (tinted progress, ringed
   flyer card, Refine/Resize/Save trio, "Keep this one" CTA). No dedicated full-screen
   Generating/Result screens - that would be a flow change, not a restyle.
6. **Global 24pt margins.** `FGSpacing.screenHorizontal` 16→24 applies app-wide (including secondary
   tabs Aurora never drew); tune any screen that ends up cramped case-by-case.
7. **Full indigo/cyan, retire pink.** Commit to Aurora's monochromatic-accent discipline: no pink,
   the 11 `moodGradient` entries desaturated into indigo/cyan tints. Semantic colors
   (success/warning/error/info) keep their meaning-colors.

## Why this is mostly a token swap

The theme is centralized. `FGColors` is referenced **1,125×**, `FGSpacing` **1,114×**, `FGTypography`
**429×** outside `Theme/`. Color/spacing/animation hardcoding is rare and mostly lives in the token
files themselves or in dead wizard code. So **editing the 5 `Theme/` files carries ~90% of the app**;
the rest is a short cleanup list + component/screen polish. **Typography is the real labor**: no custom
font exists today, and ~77 active `.font(.system(...))` sites bypass the scale and must be routed
through `FGTypography` to inherit Space Grotesk.

---

## 1. Design tokens

Property **names stay the same** (so all call sites keep working); only **values change**. New Aurora
concepts are added as new tokens.

### 1a. `FGColors.swift` - value remap

| Token (name kept) | Old | New (Aurora) |
|---|---|---|
| `backgroundPrimary` | `#0D0D0D` | `#0A0B0F` (bg/base) |
| `backgroundSecondary` | `#1A1A1A` | `#0F1116` |
| `backgroundTertiary` | `#262626` | `#1B1E27` |
| `backgroundElevated` | `#2D2D2D` | `#1E2129` |
| `surfaceDefault` | `#1F1F1F` | `#13151B` (surface) |
| `surfaceHover` | `#2A2A2A` | `#191C24` |
| `surfaceSelected` | `#3D3D3D` | `#1C2033` (indigo-tinted) |
| `accentPrimary` | `#7C3AED` | `#7C8CF8` (indigo) |
| `accentSecondary` | `#06B6D4` | `#63E6D2` (cyan) |
| `accentGradientStart` | `#7C3AED` | `#7C8CF8` |
| `accentGradientEnd` | `#EC4899` | `#8B7CF8` (indigoDeep - retires pink) |
| `textPrimary` | `Color.white` | `#EDEFF4` |
| `textSecondary` | `#A3A3A3` | `#8A90A0` |
| `textTertiary` | `#737373` | `#565C6B` |
| `textOnAccent` | white | white (unchanged - text on gradient) |
| `borderDefault` | `#404040` | `Color.white.opacity(0.12)` |
| `borderSubtle` | `#2D2D2D` | `Color.white.opacity(0.07)` (border/card) |
| `borderFocus` | accent | `accentPrimary` (indigo, unchanged ref) |

Semantic colors (`success/warning/error/info`) unchanged.

**New tokens to add:**
- `accentIndigoDeep = #8B7CF8`
- `textOnCardBody = #DDE0E8`, `textOnCardLabel = #B4BAC8`
- `borderCard = white.opacity(0.07)`, `borderHairline = white.opacity(0.06)`
- `selectionRing = Color(hex:"7C8CF8").opacity(0.12)`
- `segmentInactive = #20222C`

### 1b. `FGTypography.swift` - Space Grotesk

Re-point every existing role to Space Grotesk (family swap is free inheritance for 429 sites), keeping
sizes so layouts don't reflow. Add Aurora-exact named styles for hero roles. Font names once bundled:
`SpaceGrotesk-Regular` (400), `-Medium` (500), `-SemiBold` (600), `-Bold` (700).

**Aurora type table** (used on hero screens for pixel fidelity):

| Role | Size | Weight | Tracking |
|---|---|---|---|
| Screen title | 29 | 700 | -0.035em |
| Hero title (Home) | 30 | 700 | -0.035em |
| Section / result title | 16 | 600 | -0.02em |
| Wordmark | 19 | 700 | -0.03em |
| Body / subtitle | 14.5 | 400 | 0 |
| Field value (filled) | 16 | 600 | 0 |
| Field label | 13 | 400 | 0 |
| Review row label | 11.5 | 500 | +0.08em UPPERCASE |
| Button label | 16 | 600 | 0 |
| Step / meta | 12-12.5 | 500 | 0 |
| Tab label | 11 | 400 / 600 | 0 |

**Tracking note:** SwiftUI `Font` cannot carry tracking; it is a `Text`/`View` modifier. Convert em→pt
(`em × size`) and apply `.tracking()` explicitly on the display/title roles where Aurora specifies it
(e.g. -0.035em @ 29pt ≈ `-1.0`). Body/label roles use Space Grotesk's natural metrics (no tracking).
Recommended: add convenience styles that pair font + tracking for the ~6 title roles; leave the rest
as font-only.

### 1c. `FGSpacing.swift` - radii + padding

| Token | Old | New (Aurora) |
|---|---|---|
| `cardRadius` | 16 | 16 (Aurora cards 14-18; 16 = default) |
| `buttonRadius` | 12 | **15** |
| `inputRadius` | 10 | **12** |
| `chipRadius` | 8 | 8 (small squares); add `iconChipRadius = 12` |
| `pillRadius` | 999 | 999 |
| `screenHorizontal` | **16** | **24** (wider premium margins) |

**New:** `screenHorizontalButtons = 22`, `heroPanelRadius = 20`, `flyerCardRadius = 18`,
`logoMarkRadius = 8`, `bottomSafePadding = 30`.

### 1d. `FGGradients.swift`

- `accent` (was violet→pink) → **CTA gradient**: 135° `#7C8CF8 → #8B7CF8`.
- `accentSecondary` (was cyan→violet) → **brand gradient**: 140° `#7C8CF8 → #63E6D2`.
- **New:** `heroPanelRadial` (radial 90% 120% at 30% 10%, `#1C2140 → #0D0F18`),
  `generatingRadial` (radial 120% 55% at 50% 24%, `#161A30 → #0A0B0F`),
  `paywallRadial` (radial 120% 50% at 50% 0%, `#1A1F3D → #0A0B0F`),
  `flyerCanvas` (165° `#12162E → #0B0D18`), `orbConic` (conic `#7C8CF8, #63E6D2, #7C8CF8`).
- `rainbow`, `moodGradient(for:)`, `selectedGlow`, `cardShine`, `borderGlow` → recolor into the
  indigo/cyan family (desaturate the 11 mood gradients; most usage is dead wizard, low-risk).

### 1e. Shadows / glow (SwiftUI approximations - no CSS spread)

- **CTA glow:** `.shadow(color: accentPrimary.opacity(0.45), radius: 20, y: 12)`.
- **Result flyer card:** `.shadow(color: .black.opacity(0.8), radius: 25, y: 12)` + 1pt indigo ring
  (`accentPrimary.opacity(0.2)`).
- **Selection ring:** 1.5pt `accentPrimary` border + 3pt outer `selectionRing` ring (double overlay).
- **Live dot glow (cyan):** `.shadow(color: accentSecondary, radius: 4)` on the 7pt dot.

---

## 2. Shared components

- **`FGPrimaryButton`** → height **56**, radius 15, CTA gradient, white 16/600, CTA glow.
  (`FGSecondaryButton` → surface `#13151B`, hairline border, radius 15, text primary 15/500.)
- **Selection ring modifier** `.auroraSelectionRing(_ isSelected:)` - reusable: 1.5pt indigo border +
  3pt outer ring when selected. Applied by `SelectionCard`, plan cards, category/style cards.
- **Glass card modifier** `.auroraCard(radius:)` - surface fill + `borderCard` hairline stroke.
- **Status pill** - surface + hairline + cyan live-dot (with glow) + label. (Home top-right; maps the
  Aurora "credits" pill onto the current subscription/quota status - content unchanged, style applied.)
- **`FGChipButton`** → Aurora selected/inactive treatment (Explore filter pills, chip questions).
- **`DynamicTextField` / `FGTextField`** → radius 12, surface, focus ring, label 13 tertiary,
  value 16/600.
- **`AuroraTabBar`** (new) - custom bar replacing native `TabView` in `MainTabView`: flat `#0A0B0F`,
  1pt `borderHairline` top, 5 items kept (Home / My Flyers / Explore / Prompts / Profile), SF Symbols
  22pt, labels 11pt, active `accentPrimary` / inactive `textTertiary`. Owns selection state; must
  preserve keyboard avoidance, safe-area inset, and per-tab `NavigationStack`s.

### Icons

Map emoji / ad-hoc glyphs to the SF Symbols the handoff specifies (`house`, `square.grid.2x2`, `crown`,
`person`, `gearshape`, `sparkles`, `arrow.triangle.2.circlepath` (Refine), `rectangle.split.2x1`
(Resize), `arrow.down.to.line` (Save), `square.and.arrow.up` (Share), `checkmark.circle.fill`, etc.),
weight `.regular`/`.medium`, tinted `accentPrimary`.

---

## 3. Screen application (live screens only)

**Hero screens (pixel-faithful to Aurora):**
- **Home** (`Views/Tabs/HomeTab.swift`): nav row (logo mark 26×26 r8 brand gradient + wordmark 19/700;
  status pill + gear). **Hero panel** 158pt r20 (`heroPanelRadial` + 26pt dotted grid + conic orb +
  sparkle) replacing `FlyerStackAnimation`. Aurora headline type. Primary "Chat to Create" CTA in the
  Aurora CTA style. (No Recents strip - that would be a feature add; out of scope.)
- **Chat** (`Chat/FlyerChatView.swift` + `ChatBubbleViews.swift`): user bubble → indigo CTA-gradient
  pill + indigo glow (fix the `#8B5CF6…#6D28D9` hardcode); assistant → `#8A90A0`; typing → cyan
  spinner. Proposal cards → glass surfaces. **Inline result** → Aurora Result mapping: ringed 4:5 flyer
  card, Refine/Resize/Save action trio, "Keep this one" CTA. **Inline generating** → Aurora conic
  spinner + step checklist.
- **Paywall** (`Views/Sheets/SubscriptionPaywallView.swift`): Aurora "Premium" - 64pt r20 brand-gradient
  badge (crown), "FlyGen **Pro**" with gradient "Pro", feature check rows, plan cards with selection
  ring + "SAVE 50%" badge, trial CTA, legal row. Map current plans/pricing into the Aurora layout.
- **Onboarding** (`Views/Onboarding/`): re-tint `AuroraBackground` to indigo/cyan (drop pink, base
  `#0A0B0F`); bubbles/chip-questions/demo-reveal inherit the new components.

**Language-inheritance screens** (no Aurora drawing; apply the system): `GalleryTab`, `ExploreTab`,
`PromptsTab`, `ProfileTab`, `SettingsView`, `BrandKitView` - surfaces, type, accent pills, section
headers, filter chips, thumbnail cards (r12 + hairline), stat rows (glass cards).

**Optional / low priority:** `CreditPurchaseSheet`, `NewUserOfferSheet` - built but **not wired** to any
call site; they inherit tokens automatically. Light touch only.

---

## 4. Font bundling steps

1. Fetch Space Grotesk static TTFs (Regular/Medium/SemiBold/Bold) - Google Fonts, OFL (free to bundle).
2. Place in `FlyGen/FlyGen/Resources/Fonts/`.
3. Add to the app target. The `.xcodeproj` is classic (objectVersion 63, no synchronized groups), so
   register files via the `xcodeproj` ruby gem, then `xcodebuild` to verify.
4. Add `UIAppFonts` array (the 4 filenames) to `FlyGen/FlyGen/Info.plist`.
5. Rewrite `FGTypography` to `Font.custom("SpaceGrotesk-<Weight>", size:)`; add tracking helpers.
6. Convert the ~77 active `.font(.system(...))` bypass sites to `FGTypography` roles so they inherit.
   Priority (active): `FlyerChatView` (10), `SubscriptionPaywallView` (7), `FGButtons` (7),
   `DynamicTextField` (6). Lower (unwired): `CreditPurchaseSheet` (13), `NewUserOfferSheet` (8).

---

## 5. Out of scope (dead code - not hand-polished)

Behind `classicCreationEnabled = false`, unreachable; they inherit token changes for free but get no
bespoke work: entire `Views/Creation/`, `Views/Templates/`, `Views/Generation/`, standalone
`Views/Result/` (`ResultView`, `RefinementSheet`, `ReformatSheet`), `Views/Home/HomeView.swift`.
**Do not delete** `RefinementSheet.swift` - it defines a shared `FlowLayout` the live
`OnboardingChipQuestionView` imports.

---

## 6. Risks & notes

- **Tracking:** `Font` can't carry tracking - apply `.tracking()` on title roles only (§1b).
- **Custom tab bar:** must preserve per-tab navigation, keyboard avoidance, and safe-area inset; this is
  the highest-risk piece. Build behind the same 5-tab structure; verify no regressions in deep flows.
- **`textPrimary` white → `#EDEFF4`:** subtle contrast reduction; still AA on `#0A0B0F`.
- **UIKit appearance:** `FlyGenApp.swift` sets `UITabBar`/`UINavigationBar` appearance with raw
  `UIColor(red:)` - update or remove (custom tab bar supersedes the tab appearance).
- **No backend impact:** engine, CloudKit schema, StoreKit products all untouched.

---

## 7. Suggested phasing (for the implementation plan)

1. **Foundation:** the 5 `Theme/` files + font bundling → global inheritance.
2. **Components:** buttons, selection ring, glass card, status pill, chips, text field, `AuroraTabBar`.
3. **Hero screens:** Home (hero panel), Chat + inline result/generating, Paywall, Onboarding.
4. **Language pass:** Gallery, Explore, Prompts, Profile, Settings, BrandKit.
5. **Cleanup + verify:** hardcoded stragglers, `.font(.system)` conversion, build; owner does the visual
   / simulator verification.
