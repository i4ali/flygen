# Design: Credits to Subscription Migration

- Date: 2026-06-27
- Status: Approved (final pricing deferred)
- Scope: FlyGen iOS app monetization. Replace consumable credits with an auto-renewable subscription.

## 1. Context and goal

FlyGen today monetizes with consumable credit packs. New installs get 15 credits; a generation/refine/resize costs 10 credits each; smart suggestions cost 5. Balance is stored on the `UserProfile` SwiftData model and synced via CloudKit (cloud is source of truth). StoreKit 2 is integrated, but only consumable products exist (`FlyGenProducts.storekit`). `UserProfile` already has unused `isPremium` + `premiumExpiresAt` fields.

Goal: move to a subscription model where generating requires an active subscription, with a fixed monthly quota of flyers that resets each billing period.

## 2. Decisions (locked)

| Decision | Choice |
| --- | --- |
| Subscription grant | Monthly quota that resets each billing period |
| Quota size | 50 images / month (config constant) |
| What counts against quota | Every AI image = 1 unit: new flyer, refine, resize |
| Smart suggestions | Free (not counted) |
| Free / non-subscriber tier | Hard paywall, no free sample. Must subscribe to generate. |
| New installs | Start with 0 credits (today: 15) |
| Offer | Monthly + Annual products, both with a 7-day free trial intro offer |
| Existing credits | Kept as a legacy balance, spent under old rules until depleted |
| Consumption order | Subscription quota consumed first; legacy credits are the fallback |
| Entitlement source of truth | StoreKit 2 (`Transaction.currentEntitlements`); no backend |

## 3. Entitlement and quota design

- "Is subscribed" is derived from StoreKit 2 `Transaction.currentEntitlements` (auto-renewable in the subscription group). A transaction listener updates state on renewal/expiry/refund.
- `isPremium` + `premiumExpiresAt` on `UserProfile` are a cached mirror of entitlement for cross-device display only; StoreKit is authoritative on-device.
- Monthly quota tracked locally and synced via CloudKit:
  - `quotaUsedThisPeriod: Int`
  - `quotaPeriodStart: Date?`
- Reset cadence: monthly, anchored to the subscription start date. On launch/foreground, if `now >= quotaPeriodStart + 1 month`, roll the period forward (handling multiple elapsed months) and reset `quotaUsedThisPeriod` to 0. Annual subscribers still refill monthly.
- Quota size is a config constant `SubscriptionConfig.monthlyQuota = 50`, not scattered literals.

## 4. Data model changes (`UserProfile`)

- `credits: Int` default `15` -> `0`. Existing users keep their persisted balance (SwiftData/CloudKit do not re-initialize existing records); only new installs get 0.
- Add `quotaUsedThisPeriod: Int = 0`.
- Add `quotaPeriodStart: Date?`.
- Keep `isPremium` / `premiumExpiresAt` as the cached entitlement mirror.
- Display fallbacks like `userProfiles.first?.credits ?? 3` change to `?? 0`.

## 5. StoreKit products and config

- New subscription group: "FlyGen Premium".
- Products:
  - `com.flygen.premium.monthly`
  - `com.flygen.premium.annual`
- Both carry a 7-day free trial introductory offer.
- Old consumable credit products are retired: removed from the paywall, no longer sold. Legacy credits are spent, never re-purchased.
- Local `.storekit` placeholder prices for sandbox testing only: $9.99/mo, $59.99/yr (real prices set in App Store Connect, changeable anytime without an app update). See Open Items.

## 6. Consumption and gating logic

A single decision used at every image-producing action:

```
func canGenerate() -> Bool {
    (isSubscribed && quotaRemaining > 0) || legacyCredits >= legacyCost
}

func consumeOne() {
    if isSubscribed && quotaRemaining > 0 { quotaUsedThisPeriod += 1 }
    else if legacyCredits >= legacyCost   { credits -= legacyCost }   // old rules
    // else: caller should have shown the paywall
}
```

- `quotaRemaining = max(0, SubscriptionConfig.monthlyQuota - quotaUsedThisPeriod)`.
- Legacy credits follow the OLD rules (10 per image action) so existing balances retain their original value; they are not re-denominated into quota units.
- If neither path is available -> present the paywall.

Call sites to update (from the architecture map):
- `ReviewStepView` (generate button + `deductCredit`) -> use `canGenerate`/`consumeOne`.
- `ResultView` (refine / resize / regenerate `deductCredit`) -> same; each counts as 1.
- `SmartExtrasStepView` (suggestions, currently 5 credits) -> now FREE; remove its credit gate/deduction.
- `HomeTab` create/template buttons -> no longer gated on `credits <= 0`; tapping without entitlement opens the paywall.

## 7. UI changes

- New `SubscriptionPaywallView` replaces `CreditPurchaseSheet`:
  - Monthly / Annual selector, trial callout, feature list.
  - Subscribe button, Restore Purchases (required by App Store), Terms + Privacy links.
- `HomeTab`: header credit badge -> subscription status ("N left this month" when subscribed, otherwise a subscribe affordance). Remove the "No credits remaining" warning banner; replace with subscribe/quota messaging.
- `ProfileTab`: "Credits Remaining" -> Subscription section (status, renewal date, Manage Subscription deep link, Restore).
- `NewUserOfferSheet` (credit-discount promo) retired in favor of the trial.

## 8. Code architecture

Introduce a single `EntitlementService` (an `ObservableObject`, or an extension of `StoreKitService`) that owns:
- `isSubscribed`, `quotaRemaining`, `renewalDate`
- `canGenerate()`, `consumeOne()`
- subscription products, `purchase()`, `restore()`
- transaction listener + entitlement refresh

This centralizes logic currently scattered across `ReviewStepView`, `ResultView`, and `SmartExtrasStepView`, giving one source of truth for "can the user generate, and what does this action cost."

## 9. Migration

- Lower the default `credits` to 0; existing balances are preserved automatically.
- Initialize `quotaUsedThisPeriod = 0`, `quotaPeriodStart = nil` (set on first active subscription).
- No destructive migration. Legacy credits simply continue to work as a fallback until depleted.

## 10. CloudKit sync

- `quotaUsedThisPeriod` and `quotaPeriodStart` sync alongside the existing credits record (same pattern, cloud as source of truth) so quota is consistent across a user's devices.
- Entitlement (`isPremium`) is evaluated from StoreKit per device and cached for display.

## 11. Notifications

Repurpose the existing credit notifications:
- "Low on credits" -> "Quota almost used this month" and/or "Trial ending soon".
- Add a win-back trigger when a subscription lapses.

## 12. Open items (deferred)

- Final pricing for monthly/annual. Decoupled from code (App Store Connect config), changeable anytime. To be set after a margin calc.
- COGS flag for the pricing pass: production iOS generation uses `google/gemini-3-pro-image-preview` (OpenRouterService.swift:42), which is more expensive per image than the Gemini 2.5 Flash (~$0.04) assumed in `PROFIT_ANALYSIS.md`. With 50 counted images/month, model the cost floor against the real per-image price before finalizing.
- Trial length assumed 7 days (adjustable in App Store Connect).

## 13. Testing

- StoreKit testing via the `.storekit` config: subscribe (monthly + annual), free trial, renewal, expiry, refund, restore.
- Quota: decrement on each counted action, period reset after a month, multi-month rollover, annual subscriber monthly refill.
- Legacy fallback: existing-credit user can spend down old credits, then hits the paywall.
- Gating: new install (0 credits, not subscribed) is paywalled on create/refine/resize; smart suggestions remain free.
- Unit tests for the quota period math and the consume/gate decision.

## 14. Out of scope

- The conversational Chat feature is disabled separately via `FeatureFlags.chatEnabled` and is unrelated to this work.
- Server-side receipt validation / cross-platform entitlement: future option; the UI is decoupled so it can be added later without rework.
