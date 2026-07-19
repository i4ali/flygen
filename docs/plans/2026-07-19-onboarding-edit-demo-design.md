# Onboarding edit demo - design

**Date:** 2026-07-19
**Status:** Approved by owner

## Goal

The onboarding auto-demo currently shows only flyer *creation*. Add a short *editing* demo -
the sent edit message plus the ticking checklist - so new users see the edit feature before
the paywall, which should help conversions.

## Approach

Pure script extension (approved over a bespoke morph animation and an annotate-feature demo).
The onboarding is data-driven (`OnboardingScript.beats`); every visual the edit demo needs
already exists as a beat type: `userTypes` (the sent message), `worklog` (the ticking boxes),
`reveal` (the flyer card), `assistant` (framing lines).

## New beats

Inserted immediately after `.assistant("Three ways to go - and that was one sentence.")`,
before "Your turn":

1. `.assistant("Need a change? Just say it.")`
2. `.userTypes("Love the middle one - make it Sunday instead, and add 'Live music'.")`
3. `.worklog(editWorklogItems)`:
   - "Keeping your layout & colors"
   - "Switching Saturday to Sunday"
   - "Adding 'Live music'"
   - "Re-checking every word"
4. `.reveal(["onboarding_demo_edit"])` - a single updated card
5. `.assistant("Updated in seconds - nothing redone from scratch.")`

The rest of the flow (open question, language chip, CTA) is unchanged.

## View change

`DemoFlyerReveal` assumes three cards (fan angles, middle-card sizing). Add a single-card
presentation: centered, no fan tilt, slightly larger width (~120pt), same glow/sweep. The
existing placeholder fallback in `DemoFlyerCard` covers the new asset until it lands.

## Asset

New imageset `onboarding_demo_edit`: the owner generates it by actually running the demo edit
message on demo flyer 2 through the app (dogfooding the real edit path), then drops the render
in - same process as `onboarding_demo_1..3`.

## Trade-offs accepted

- Adds ~9-10s of autoplay before the interactive "what do you do?" beat.
- No `brief` chip row for the edit (that beat proves fact extraction; the edit demo should
  stay snappy).

## Testing

Build-verify only; owner runs the simulator/device eyeball per usual workflow. Check both
normal and Reduce Motion paths, and the placeholder state before the asset lands.
