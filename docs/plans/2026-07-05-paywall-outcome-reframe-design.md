# Paywall Outcome Reframe - Design

- **Date:** 2026-07-05
- **Status:** Approved (brainstorm complete), pending implementation
- **Surface:** `FlyGen/FlyGen/Views/Sheets/SubscriptionPaywallView.swift` (+ one already-bundled asset)

## Problem

The subscription paywall sells *features*, not *outcomes*. Today the hero is a crown badge + "FlyGen
Premium / Create flyers all month long", and the four bullets describe capabilities:

- "AI flyer generations, reset each period"
- "Refine & resize your flyers"
- "All styles, formats & languages"
- "Quota resets every billing period"

Every line says what the product *does*; none says what the user *gets*. Two of the bullets restate the
same billing mechanic (quota reset). Inspiration: outcome-led paywalls (e.g. a piano app's "your kid will
learn piano in 7 days") sell a transformation - subject + result + timeframe - which converts far better
than a feature list.

## Decisions (locked)

- **Audience: Universal.** One promise must fit a business sale, a community/religious event, and a
  personal event. Universality is restored in the subhead, not forced into the headline.
- **Scope: Copy-led rewrite + hero image swap.** Keep the existing layout, section order, plan cards, and
  legal. No structural redesign.
- **Positioning: "Get noticed"** (the downstream result - attention / turnout). Sold honestly: we claim
  attention + looking professional (both provable from the flyer itself) and *imply* turnout. No
  guaranteed-sales claims (App Review 3.1.2 / truthfulness).
- **Hero image: `sample_mega_sale`** (already bundled in `SampleFlyers`). Neon-on-black, big crisp type,
  dark background that matches the Aurora paywall, universal, no rights issues.

## New copy

### Hero
- **Image:** `sample_mega_sale`, portrait ~3:4, rounded corners + soft violet-tinted shadow, sitting on the
  existing top radial glow; capped ~220-240pt tall. Replaces the crown badge, the "FlyGen Premium"
  wordmark, and the "Create flyers all month long" subhead. (Brand name still appears on the plan cards, so
  branding + compliance are intact.)
- **Headline** (two lines, display face): **"Get noticed. / Fill the room."**
- **Subhead:** "Professional flyers that make people stop - for your sale, your event, your community."
  (This line does the universality work that "Fill the room" alone doesn't.)

### Benefit bullets (4) - replace the current four
1. Eye-catching designs that get you noticed
2. Look like you hired a designer - no skills needed
3. Just describe it, and it's ready in seconds  *(see Open Items: verify timeframe)*
4. Any style, any language, sized for any post

Order is deliberate: results (the hero angle) -> identity -> speed/magic -> versatility. The "12 / 50
flyers" quota that used to live in the bullets now lives **only** on the plan cards - bullets sell the
outcome, plan cards state the quantity.

### CTA
- **Subscribe button label:** "Make my flyer" (was "Subscribe"). Concrete, first-person, points at the
  payoff. The price/period line stays **directly beneath** it (compliance).

## Unchanged
- Layout, section order, background treatment.
- Plan cards: weekly / monthly, prices, "Best Value" badge, "12 flyers / week" & "50 flyers / month".
- "Cancel anytime", "Restore Purchases", legal links.
- Disclosure paragraph (auto-renew legalese + "$X per month") - compliance-required, kept verbatim.
- Reviews section + "LOVED ON THE APP STORE" header.
  - *Enhancement (optional):* if a **real** review mentions an outcome ("so many people came", "everyone
    asked who made it"), feature it - it becomes proof of the hero promise. Never fabricate (App Store
    2.3.1).

## Honesty & compliance
- No guaranteed-results claims. "Get noticed / fill the room" is aspirational, not a promise.
- Hero uses a genuine FlyGen output.
- Title, length/period, price, and what-you-get all remain clearly shown (App Review 3.1.2).

## Hero image selection (rationale)
Chose `sample_mega_sale` after reviewing the bundled `SampleFlyers`. Notable rejects:
- **`sample_concert_user_photo` (Beatles Tribute):** visually excellent and on-theme, but features The
  Beatles by name + likeness -> trademark / celebrity-likeness risk in App Store marketing. Rejected.
- **`sample_fitness_challenge`:** has literal template placeholder text baked into the image ("MAIN
  HEADLINE", "SECONDARY HEADLINE", "DISCOUNT/OFFER", "CALL-TO-ACTION"). Broken sample - see Open Items.
- **`sample_internet_safety` ("Digital Safety Corner"):** great text rendering, but light background (clashes
  on the dark paywall), too text-dense to read at hero size, and carries school + a specific "Islamic
  Perspective" section that narrows a universal paywall.
- `sample_grand_opening` (black+gold, highest-res, elegant) is the runner-up if a calmer vibe is ever wanted.

`sample_mega_sale` wins because it satisfies both goals at once: bold "get noticed" energy **and** crisp
large-text rendering, on a dark background that integrates with the Aurora look.

## Open items
- **Bullet 3 timeframe:** "in seconds" is a placeholder. Confirm the real typical create time (the engine
  renders 3 images per create); if it's ~1-2 minutes, change to "in about a minute" / "in a snap" to stay
  honest.
- **Taller hero:** the flyer image pushes the CTA a scroll down (normal for a paywall). Optional future
  enhancement: a sticky bottom CTA.
- **Separate cleanup (not this task):** `sample_fitness_challenge` ships with placeholder text baked in and
  is visible wherever `SampleFlyers` are shown; worth regenerating or removing.

## Implementation surface
- **Single file:** `SubscriptionPaywallView.swift` - hero section (`heroSection`), feature list
  (`featureList` / `FeatureRow` text), and subscribe button label.
- **Hero image:** reference the existing `sample_mega_sale` image set (verify the exact asset name string at
  implementation - confirm whether the `SampleFlyers` folder provides a namespace). No new asset needed.
- **No** StoreKit / entitlement / engine changes.
