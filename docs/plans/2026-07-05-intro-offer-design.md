# Introductory Offer - Design

- **Date:** 2026-07-05
- **Status:** iOS BUILD-COMPLETE (uncommitted), ASC configured by owner; pending sandbox verification
- **Surface:** `FlyGen/FlyGen/Views/Sheets/SubscriptionPaywallView.swift`

## Goal

A first-time-subscriber introductory offer (Apple "Introductory Offer", auto-applied to eligible new
subscribers, one per customer per subscription group). Deflects to the reframed paywall's plan cards.

## Offer (configured in App Store Connect by owner)

- **Monthly** (`com.flygen.premium.monthly.v2`): 50% off first month -> **$4.99**, then $9.99/mo.
- **Weekly** (`com.flygen.premium.weekly.v2`): 50% off first week -> **$2.49**, then $4.99/wk.
- Type: **Pay As You Go**, 1 period, both subs in group "FlyGen Premium". No end date (evergreen).
- Goes live on its own (no app review / no new build required for the ASC side).

## Hard constraint: nothing hardcoded

Every user-facing value is read from the StoreKit `Product` / `introductoryOffer`, so changing the offer
in App Store Connect (amount, duration, type, which plan) flows through with **zero code changes**:
- discount **percent** = computed from `product.price` vs `offer.price`
- **prices** = `offer.displayPrice` / `product.displayPrice`
- **"month" / "week"** = derived from the subscription period
- **disclosure sentence** = built from `paymentMode` + `periodCount` + prices

## iOS implementation (all in `SubscriptionPaywallView.swift`)

- **`IntroOfferInfo`** (new, file-scope): `init?(product:)` returns nil if no offer; otherwise builds
  `badge`, `introPrice`, `standardPrice`, `thenLine`, `disclosure` from StoreKit. Handles free-trial /
  pay-as-you-go / pay-up-front generically (so switching offer type in ASC still renders correctly).
  `PaymentMode` is a StoreKit *struct* (RawRepresentable), so its switch uses `default:`, not
  `@unknown default:`.
- **Eligibility gate:** `@State introEligibility: [String: Bool]`, populated by a `.task(id: products)`
  that awaits `product.subscription?.isEligibleForIntroOffer` per plan. `offerInfo(for:)` returns an
  `IntroOfferInfo` only when eligible **and** an offer exists - so ineligible/returning users see today's
  standard cards, untouched.
- **`PlanCard`:** gains `introOffer: IntroOfferInfo?`. When present: a green "savings" chip
  (`FGColors.success`, distinct from the accent "Best Value" chip) with the badge; a "then $X / period"
  line; and a price column showing the intro price with the standard price struck through. When nil:
  unchanged.
- **Disclosure:** `subscriptionDescription` returns `offer.disclosure` for eligible users, else the
  standard "X is $Y per period." (App Review 3.1.2 - terms shown near the CTA).
- **Purchase: unchanged.** `product.purchase()` auto-applies the intro price for eligible users; no
  offer id / signature needed (that's only for *promotional* offers).

## Testing

The FlyGen **run scheme does not reference a local `.storekit` config** (it was removed in commit
46b962b), so Debug builds use **StoreKit sandbox / live App Store Connect**. To see the offer:
- Sign the device (or simulator) into a **Sandbox Apple Account** that has **never** subscribed in the
  "FlyGen Premium" group (eligibility is per purchase history).
- Open the paywall: eligible -> cards show "50% OFF ..." + struck price; ineligible -> normal cards.
- Reset eligibility between runs by using a fresh sandbox account (or manage/clear sandbox purchases).
- No `.storekit` edit is needed or used at runtime. (If a StoreKit config is ever re-added to the scheme,
  the offer must also be added to `FlyGenProducts.storekit` via Xcode's editor to render locally.)

## Unchanged
Hero, bullets, "Subscribe" button, reviews, restore, entitlement/quota logic, engine. Ineligible users see
the exact paywall from before.

## Notes / follow-ups
- Monthly card now has two chips (accent "Best Value" + green offer) - owner to eyeball the layout.
- Discounted first period still grants the full period quota (50 / 12 flyers); acquisition-cost trade-off
  accepted (see [[flyer-generation-economics]]).
