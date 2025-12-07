# FlyGen: CloudKit Integration Plan

## Overview
Add CloudKit integration for authentication, cloud sync, and credits/premium management using SwiftData + CloudKit automatic sync.

**Status:** Previous phases (Tab Navigation, Onboarding, Gallery, Credits) are complete and committed.

---

## CloudKit Integration Approach

### Chosen Options
- **Integration Method:** SwiftData + CloudKit (automatic sync)
- **iCloud Requirement:** Required - show message if not signed in

### What CloudKit Provides
| Feature | Implementation |
|---------|----------------|
| Authentication | Automatic via iCloud (no login screens) |
| User Identity | `CKContainer.default().fetchUserRecordID()` |
| Cloud Storage | Private database in user's iCloud quota |
| Cross-device Sync | SwiftData + CloudKit automatic sync |
| Credits/Premium | Store in UserProfile SwiftData model |

---

## Implementation Details

### Phase 1: Xcode Configuration

**Enable Capabilities:**
1. Sign in with Apple
2. iCloud → Check "CloudKit"
3. Add CloudKit container: `iCloud.com.flygen.app`
4. Background Modes → Remote notifications (for sync)

**Modify:** `FlyGen.entitlements`

---

### Phase 2: SwiftData Models for CloudKit

**Requirements for CloudKit sync:**
- All properties must be optional OR have default values
- All relationships must be optional
- Use `@Attribute(.externalStorage)` for large data (images)

**New Model:** `UserProfile.swift`
```swift
@Model
final class UserProfile {
    var id: UUID = UUID()
    var credits: Int = 3
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var createdAt: Date = Date()
    var lastSyncedAt: Date = Date()
}
```

**Update Model:** `SavedFlyer.swift`
```swift
@Model
final class SavedFlyer {
    var id: UUID = UUID()
    var projectData: Data = Data()
    @Attribute(.externalStorage) var imageData: Data?
    var prompt: String = ""
    var model: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // ... rest of implementation
}
```

---

### Phase 3: iCloud Account Status Service

**New File:** `Services/CloudKitService.swift`

```swift
import CloudKit

@MainActor
class CloudKitService: ObservableObject {
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var userRecordID: CKRecord.ID?
    @Published var isSignedIn: Bool = false

    func checkAccountStatus() async
    func fetchUserRecordID() async
}
```

**Features:**
- Check if user is signed into iCloud
- Get unique user identifier
- Listen for account status changes
- Show alert if not signed in

---

### Phase 4: Update App Entry Point

**Modify:** `FlyGenApp.swift`

```swift
@main
struct FlyGenApp: App {
    @StateObject private var cloudKitService = CloudKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
        }
        .modelContainer(for: [SavedFlyer.self, UserProfile.self],
                        cloudKitDatabase: .private(iCloudContainerIdentifier))
    }
}
```

---

### Phase 5: iCloud Required Screen

**Modify:** `ContentView.swift`

Add iCloud check before onboarding:
```swift
if !cloudKitService.isSignedIn {
    iCloudRequiredView()
} else if hasCompletedOnboarding {
    MainTabView()
} else {
    OnboardingContainerView()
}
```

**New View:** `Views/iCloudRequiredView.swift`
- Explain why iCloud is needed
- Link to Settings to sign in
- Retry button to check status

---

### Phase 6: Credits from CloudKit

**Modify:** `HomeTab.swift` and `ProfileTab.swift`

Replace `@AppStorage` with SwiftData query:
```swift
@Query private var userProfiles: [UserProfile]

var credits: Int {
    userProfiles.first?.credits ?? 3
}
```

**Modify:** `ResultView.swift`

Deduct credits from UserProfile model instead of UserDefaults.

---

### Phase 7: Premium Status Check

**New File:** `Services/PremiumService.swift`

```swift
class PremiumService: ObservableObject {
    @Published var isPremium: Bool = false

    func checkPremiumStatus(profile: UserProfile)
    func syncWithStoreKit() async  // Verify with App Store
}
```

**Note:** For real premium validation, use StoreKit 2 to verify receipts. CloudKit stores the cached status for offline access.

---

## File Changes Summary

### New Files
```
FlyGen/
├── Models/
│   └── UserProfile.swift           # User profile with credits/premium
├── Services/
│   └── CloudKitService.swift       # iCloud account management
│   └── PremiumService.swift        # Premium status handling
├── Views/
│   └── iCloudRequiredView.swift    # Sign-in required screen
```

### Modified Files
```
FlyGen/
├── FlyGen.entitlements             # Add iCloud/CloudKit capabilities
├── App/
│   ├── FlyGenApp.swift             # CloudKit container setup
│   └── ContentView.swift           # iCloud status check
├── Models/
│   └── SavedFlyer.swift            # Make CloudKit-compatible
├── Views/
│   ├── Tabs/HomeTab.swift          # Use UserProfile for credits
│   ├── Tabs/ProfileTab.swift       # Show iCloud sync status
│   └── Result/ResultView.swift     # Deduct credits from UserProfile
```

---

## Implementation Order

1. **Xcode Capabilities** - Enable CloudKit, add container
2. **UserProfile Model** - Credits and premium status
3. **Update SavedFlyer** - Make CloudKit-compatible (optional defaults)
4. **CloudKitService** - Account status checking
5. **iCloudRequiredView** - Require sign-in screen
6. **Update ContentView** - Check iCloud before showing app
7. **Migrate Credits** - From UserDefaults to UserProfile
8. **PremiumService** - Premium status management

---

## User Decisions

- **CloudKit Approach:** SwiftData + CloudKit (automatic sync)
- **iCloud Requirement:** Required - must be signed in to use app
- **Payment Model:** One-time credit packs (consumable IAP) - Phase 2
- **Phase 1 (This Plan):** CloudKit sync + free 3 credits
- **Phase 2 (Future):** StoreKit 2 credit purchases

---

## Phase 2: StoreKit Credit Purchases (Future)

After CloudKit integration is complete, add paid credit packs:

**App Store Connect Setup:**
- Create consumable IAP products (e.g., 10/25/50 credit packs)

**Implementation:**
- StoreKitService using StoreKit 2
- Update PremiumTab with purchase UI
- On successful purchase: increment `UserProfile.credits`
- Credits sync across devices via CloudKit
