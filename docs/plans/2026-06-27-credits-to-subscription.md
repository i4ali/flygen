# Credits to Subscription Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task (TDD is intentionally skipped, see below).

**Goal:** Replace FlyGen's consumable credits with an auto-renewable subscription that grants 50 image-generations per month (resetting each billing period), behind a hard paywall, with a 7-day free trial and a legacy-credit fallback for existing users.

**Architecture:** StoreKit 2 is the source of truth for "is subscribed" (`Transaction.currentEntitlements`). The monthly quota is tracked on the `UserProfile` SwiftData model and synced via CloudKit, exactly like credits today. All "can the user generate / what does this cost" logic is centralized in a new `EntitlementService`, built on small, pure, framework-free value types (`SubscriptionConfig`, `QuotaState`, `GenerationAccess`). No backend.

**Tech Stack:** Swift, SwiftUI, SwiftData, StoreKit 2, CloudKit, Xcode 26.5.

---

## Conventions for this plan

- **Design reference:** `docs/plans/2026-06-27-credits-to-subscription-design.md` (read it first).
- **No TDD / no test target (owner direction).** Do not add a unit-test target or write XCTest cases. The money logic still lives in pure value types because that is good structure, but it is verified by building the app and exercising flows in the simulator, not by unit tests.
- **Commits:** The owner commits only on explicit request. Treat every "Commit checkpoint" as: stage the changes, summarize them, and pause for the owner's go-ahead. Never add an agent name as co-author.
- **Adding new Swift files:** No XcodeGen is in use (stale `project.yml`, tool not installed); the hand-edited `FlyGen/FlyGen.xcodeproj/project.pbxproj` is the source of truth. Each new `.swift` file needs four pbxproj entries, mirroring how `MailComposerView.swift` was added: (1) `PBXBuildFile` (`AA<ID> /* X.swift in Sources */`), (2) `PBXFileReference` (`BB<ID> /* X.swift */`), (3) owning `PBXGroup` membership, (4) app target `PBXSourcesBuildPhase` membership. Use short uppercase synthetic IDs in the existing style (e.g. `AAENTSVC000001` / `BBENTSVC000001`). After any pbxproj edit, run Build verification; a green build proves the wiring.
- **Build verification (the per-task gate, the iOS analog of "run the tests"):**
  ```bash
  xcodebuild -project FlyGen/FlyGen.xcodeproj -scheme FlyGen \
    -sdk iphonesimulator -configuration Debug \
    -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`.
- **StoreKit testing:** Uses the local `FlyGen/FlyGen/Resources/FlyGenProducts.storekit` config (already referenced by the scheme). Subscription flows (purchase, trial, renewal, expiry, restore) are validated by running the app in the simulator.

---

## Phase 1: Pure money logic

### Task 1: SubscriptionConfig constants

**Files:**
- Create: `FlyGen/FlyGen/Models/Subscription/SubscriptionConfig.swift` (wire into pbxproj)

**Step 1: Implement.**
```swift
import Foundation

/// Single source of truth for subscription tunables.
enum SubscriptionConfig {
    static let monthlyQuota = 50

    /// Legacy consumable-credit cost per image action (pre-subscription rules).
    static let legacyCostPerImage = 10

    enum Product {
        static let monthly = "com.flygen.premium.monthly"
        static let annual  = "com.flygen.premium.annual"
        static let all: Set<String> = [monthly, annual]
    }
}
```

**Step 2:** Build verification. Expected: `** BUILD SUCCEEDED **`.

**Commit checkpoint:** "feat: add SubscriptionConfig".

### Task 2: QuotaState value type (the monthly-reset math)

**Files:**
- Create: `FlyGen/FlyGen/Models/Subscription/QuotaState.swift` (wire into pbxproj)

**Step 1: Implement.**
```swift
import Foundation

/// Pure monthly-quota state. Period is anchored to the subscription start and
/// rolls forward one calendar month at a time, resetting usage each roll.
struct QuotaState: Equatable {
    var usedThisPeriod: Int
    var periodStart: Date?

    func remaining(quota: Int) -> Int { max(0, quota - usedThisPeriod) }

    func consuming() -> QuotaState {
        QuotaState(usedThisPeriod: usedThisPeriod + 1, periodStart: periodStart)
    }

    /// Roll the period forward (resetting usage) for every whole month elapsed
    /// since `periodStart`. No-op if `periodStart` is nil or still in-period.
    func advancing(now: Date, calendar: Calendar = .current) -> QuotaState {
        guard var start = periodStart else { return self }
        var used = usedThisPeriod
        while let next = calendar.date(byAdding: .month, value: 1, to: start), next <= now {
            start = next
            used = 0
        }
        return QuotaState(usedThisPeriod: used, periodStart: start)
    }
}
```
Behavior to keep in mind while implementing/verifying: in-period -> unchanged; one month elapsed -> usage 0 and periodStart advances one month; several months elapsed -> rolls to the most recent boundary; nil start -> no-op.

**Step 2:** Build verification.

**Commit checkpoint:** "feat: add QuotaState monthly-reset logic".

### Task 3: GenerationAccess decision

**Files:**
- Create: `FlyGen/FlyGen/Models/Subscription/GenerationAccess.swift` (wire into pbxproj)

**Step 1: Implement.**
```swift
import Foundation

/// How a single image action (new / refine / resize) will be paid for.
enum GenerationAccess: Equatable {
    case subscriptionQuota
    case legacyCredits
    case blocked   // caller must present the paywall

    static func decide(isSubscribed: Bool, quotaRemaining: Int, legacyCredits: Int,
                       legacyCost: Int = SubscriptionConfig.legacyCostPerImage) -> GenerationAccess {
        if isSubscribed && quotaRemaining > 0 { return .subscriptionQuota }
        if legacyCredits >= legacyCost { return .legacyCredits }
        return .blocked
    }
}
```
Rules to preserve: subscription quota is preferred; legacy credits are the fallback (existing users); otherwise blocked.

**Step 2:** Build verification.

**Commit checkpoint:** "feat: add GenerationAccess decision".

---

## Phase 2: Data model

### Task 4: UserProfile quota fields + 0 default

**Files:**
- Modify: `FlyGen/FlyGen/Models/UserProfile.swift`

**Step 1: Implement.** Change `var credits: Int = 15` to `= 0`. Add:
```swift
var quotaUsedThisPeriod: Int = 0
var quotaPeriodStart: Date? = nil
```
SwiftData adds these as new properties with defaults; existing persisted records keep their stored `credits`, so existing users retain their legacy balance while new installs start at 0. Update display fallbacks `userProfiles.first?.credits ?? 3` -> `?? 0` (search the project for `?? 3`).

**Step 2:** Build verification.

**Commit checkpoint:** "feat: UserProfile quota fields; new installs start at 0 credits".

---

## Phase 3: StoreKit + EntitlementService

### Task 5: Subscription products in .storekit

**Files:**
- Modify: `FlyGen/FlyGen/Resources/FlyGenProducts.storekit`

**Step 1:** Add a subscription group "FlyGen Premium" with two auto-renewable products (`com.flygen.premium.monthly`, `com.flygen.premium.annual`), each with a 7-day free-trial introductory offer. Placeholder local prices $9.99 / $59.99 (testing only). Leave the existing consumables in the file; they will no longer be surfaced.

**Step 2:** Build verification (confirm the app still builds and the scheme still loads the config).

**Commit checkpoint:** "feat: add subscription products to StoreKit config".

### Task 6: EntitlementService

**Files:**
- Create: `FlyGen/FlyGen/Services/EntitlementService.swift` (wire into pbxproj)
- Modify: `FlyGen/FlyGen/App/FlyGenApp.swift` (add `@StateObject private var entitlementService = EntitlementService()` and `.environmentObject(entitlementService)`, mirroring `storeKitService`)

**Step 1:** Implement an `@MainActor final class EntitlementService: ObservableObject` that:
- `@Published private(set) var isSubscribed: Bool`, `renewalDate: Date?`, `products: [Product]`.
- Loads `Product.products(for: SubscriptionConfig.Product.all)`.
- Computes `isSubscribed` + `renewalDate` from `Transaction.currentEntitlements` (active, non-revoked subscription in the group).
- `purchase(_:)`, `restore()` (`AppStore.sync()`), and a `Transaction.updates` listener started at init.
- `quotaRemaining(for: UserProfile) -> Int` via `QuotaState(usedThisPeriod:periodStart:).advancing().remaining(quota: SubscriptionConfig.monthlyQuota)`.
- `access(for: UserProfile) -> GenerationAccess` via `GenerationAccess.decide(...)`.
- `consume(for: UserProfile, context: ModelContext, cloudKit: CloudKitService)`: apply the decision (increment quota OR subtract `legacyCostPerImage` from credits), persist, sync to CloudKit.
- `refresh(profile:context:)`: roll the quota period (`advancing`) and cache `isPremium`/`premiumExpiresAt` for display. On first active subscription with `quotaPeriodStart == nil`, set it to now.

**Step 2:** Build verification.

**Step 3 (simulator):** Purchase the monthly product via the `.storekit` config; confirm `isSubscribed` flips true and `renewalDate` is set; test restore.

**Commit checkpoint:** "feat: add EntitlementService (StoreKit 2 entitlements + quota)".

### Task 7: CloudKit sync for quota fields

**Files:**
- Modify: `FlyGen/FlyGen/Services/CloudKitService.swift` (extend the credits record with `quotaUsedThisPeriod` + `quotaPeriodStart`, following the existing `saveCredits`/`syncCredits` pattern, cloud as source of truth)
- Modify: `FlyGen/FlyGen/App/ContentView.swift` (the launch/foreground path that calls `syncCreditsFromCloud()`)

**Step 1:** Add save/fetch/sync for the two quota fields alongside credits. **Step 2:** Build verification. **Step 3:** Relaunch in the simulator and confirm quota usage persists.

**Commit checkpoint:** "feat: sync monthly quota via CloudKit".

---

## Phase 4: Gating refactor (route every image action through EntitlementService)

For each task: replace the credit check/deduction with `entitlement.access(for:)` (present `SubscriptionPaywallView` when `.blocked`) and `entitlement.consume(...)` after a successful generation. End each with Build verification.

### Task 8: HomeTab
**Files:** Modify `FlyGen/FlyGen/Views/Tabs/HomeTab.swift`.
- Remove `credits <= 0` gating on "Create New Flyer" / "Use Template"; if `entitlement.access == .blocked`, present the paywall instead of starting the flow.
- Replace the header credit badge with subscription status ("N left this month" when subscribed; otherwise a subscribe affordance). Remove the "No credits remaining" `WarningBanner`.
- Resume-draft banner: drop the `&& credits > 0` condition.

**Commit checkpoint:** "refactor: HomeTab gates on subscription".

### Task 9: ReviewStepView (initial generate)
**Files:** Modify `FlyGen/FlyGen/Views/Creation/ReviewStepView.swift`.
- Replace the `profile.credits >= 10` gate (button disable + "Insufficient credits" message) and `deductCredit()` with `entitlement.access`/`consume`. Counts as 1.

**Commit checkpoint:** "refactor: gate initial generation on subscription".

### Task 10: ResultView (refine / resize / regenerate)
**Files:** Modify `FlyGen/FlyGen/Views/Result/ResultView.swift`.
- Replace `deductCredit()` (currently 10) with `entitlement.consume(...)`; each refine/resize/regenerate counts as 1. Before each, check `access`; if `.blocked`, present the paywall.

**Commit checkpoint:** "refactor: gate refine/resize on subscription".

### Task 11: SmartExtrasStepView (suggestions now free)
**Files:** Modify `FlyGen/FlyGen/Views/Creation/SmartExtrasStepView.swift`.
- Remove the 5-credit gate and `deductCredits(5)`; smart suggestions are free. Remove the "Not enough credits" path.

**Commit checkpoint:** "refactor: make smart suggestions free".

---

## Phase 5: Paywall + account UI

### Task 12: SubscriptionPaywallView
**Files:**
- Create: `FlyGen/FlyGen/Views/Sheets/SubscriptionPaywallView.swift` (wire into pbxproj)
- Replace `CreditPurchaseSheet` presentations app-wide (HomeTab, ProfileTab, ContentView) with this view.

**Spec:** Monthly/Annual selector (from `entitlement.products`, prices via `product.displayPrice`), trial callout, feature list, Subscribe button (`entitlement.purchase`), "Restore Purchases" (`entitlement.restore`), Terms + Privacy links. Use existing FG design tokens (`FGColors`/`FGSpacing`/`FGTypography`). Dismiss on successful purchase.

**Step:** Build verification, then simulator test of purchase + trial + restore from this UI.

**Commit checkpoint:** "feat: SubscriptionPaywallView replaces credit purchase".

### Task 13: ProfileTab subscription section
**Files:** Modify `FlyGen/FlyGen/Views/Tabs/ProfileTab.swift`.
- Replace "Credits Remaining" with a Subscription section: status, renewal date, "Manage Subscription" (`manageSubscriptionsSheet` / App Store), "Restore Purchases".

**Commit checkpoint:** "feat: ProfileTab subscription management".

### Task 14: Retire NewUserOfferSheet
**Files:** Modify `FlyGen/FlyGen/App/ContentView.swift` (remove the post-onboarding credit-promo trigger; optionally present the paywall/trial after onboarding). Leave `NewUserOfferSheet.swift` unreferenced.

**Commit checkpoint:** "chore: retire credit promo in favor of trial".

---

## Phase 6: Notifications

### Task 15: Repurpose credit notifications
**Files:** Modify `FlyGen/FlyGen/Services/NotificationService.swift` and its call sites.
- Replace "Running Low on Credits" / "out of credits" messaging with "quota almost used this month" + "trial ending soon"; add a lapsed-subscription win-back. Re-point `onCreditsChanged` to a quota/entitlement-aware trigger.

**Commit checkpoint:** "feat: subscription-aware notifications".

---

## Phase 7: Migration + full verification

### Task 16: Migration initialization
**Files:** Modify `FlyGen/FlyGen/App/ContentView.swift` (or `FlyGenApp.swift`) launch path.
- On launch, call `entitlement.refresh(profile:context:)` to roll the quota period and cache entitlement. First active subscription with `quotaPeriodStart == nil` sets it to now. Existing credits untouched.

**Commit checkpoint:** "feat: subscription/quota migration on launch".

### Task 17: Full regression (build + StoreKit simulator matrix)
**Steps (verification only):**
- Build verification: `** BUILD SUCCEEDED **`.
- Simulator StoreKit matrix via `.storekit`: subscribe monthly + annual; 7-day trial; renewal (quota refills); expiry (falls back / paywalls); restore; manage.
- Quota matrix: new+refine+resize each decrement; suggestions free; period reset after a month; annual subscriber refills monthly.
- Legacy matrix: existing-credit profile spends old credits, then hits the paywall; quota preferred over legacy when both exist.
- New-install matrix: 0 credits, not subscribed -> create/refine/resize all paywalled.

**Commit checkpoint:** "chore: subscription migration verified".

---

## Out of scope
- Final pricing (App Store Connect; deferred; remember the `gemini-3-pro-image-preview` COGS flag in the design doc).
- The Chat feature (disabled separately via `FeatureFlags.chatEnabled`).
- Server-side receipt validation (future; UI is decoupled to allow it later).
