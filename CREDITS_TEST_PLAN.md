# FlyGen Credits System Test Plan

## Overview
This test plan covers credit purchases, deductions, and CloudKit synchronization across multiple devices.

---

## Prerequisites

- Two devices signed into the **same Apple ID** (e.g., iPhone + iPad, or iPhone + Simulator)
- Sandbox test account configured in App Store Connect
- Fresh app install on both devices (or delete app data)

---

## 1. INITIAL CREDIT ALLOCATION

### 1.1 First Launch Credits
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Fresh install app on Device A | App launches, shows onboarding |
| 2 | Complete onboarding | Home screen displays |
| 3 | Check credits in header | Shows **3 credits** |
| 4 | Check Profile tab | Shows **3 credits remaining** |

### 1.2 CloudKit Record Creation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app on Device A (first time) | UserCredits record created in CloudKit |
| 2 | Check Xcode console | Shows "CloudKit: Created new credits record with 3 credits" |

---

## 2. CREDIT DEDUCTION

### 2.1 Flyer Generation Deduction
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start with 3 credits | Credits show 3 |
| 2 | Create a new flyer (complete all steps) | Generation starts |
| 3 | Wait for generation to complete | Flyer displays |
| 4 | Check credits | Shows **2 credits** |
| 5 | Check console | Shows "Credit deducted. Remaining credits: 2" |
| 6 | Check console | Shows "CloudKit: Credits saved successfully (2)" |

### 2.2 Refinement Deduction
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | From generated flyer, tap "Refine" | Refinement sheet opens |
| 2 | Enter feedback and submit | Regeneration starts |
| 3 | Wait for completion | Refined flyer displays |
| 4 | Check credits | **1 credit deducted** |
| 5 | Check console | CloudKit sync message appears |

### 2.3 Resize Deduction
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | From generated flyer, tap "Resize" | Aspect ratio picker opens |
| 2 | Select different format | Regeneration starts |
| 3 | Wait for completion | Resized flyer displays |
| 4 | Check credits | **1 credit deducted** |
| 5 | Check console | CloudKit sync message appears |

### 2.4 Zero Credits Behavior
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Use all credits (0 remaining) | Credits show 0 |
| 2 | Check Home tab buttons | "Create New Flyer" button **disabled** |
| 3 | Check Home tab | Warning banner shows "No credits remaining" |
| 4 | Try to open creation flow | Button doesn't respond |
| 5 | Check Refine button (if in result view) | Shows "No credits remaining" warning |

---

## 3. CREDIT PURCHASES

### 3.1 Purchase 10 Credits
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Premium tab | Credit packs display |
| 2 | Tap price button for "10 Credits" | System purchase dialog appears |
| 3 | Complete purchase (sandbox) | Purchase processes |
| 4 | Wait for confirmation | Success alert: "You've received 10 credits" |
| 5 | Check credits display | Credits increased by 10 |
| 6 | Check console | "CloudKit: Credits saved successfully (X)" |

### 3.2 Purchase 25 Credits
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap price button for "25 Credits" | Purchase dialog appears |
| 2 | Complete purchase | Success alert shows |
| 3 | Check credits | Credits increased by 25 |
| 4 | Verify "Save 20%" badge visible | Badge displays on pack |

### 3.3 Purchase 50 Credits
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap price button for "50 Credits" | Purchase dialog appears |
| 2 | Complete purchase | Success alert shows |
| 3 | Check credits | Credits increased by 50 |
| 4 | Verify "Best Value" badge visible | Badge displays on pack |

### 3.4 Purchase Cancellation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap any credit pack | Purchase dialog appears |
| 2 | Cancel the purchase | Dialog dismisses |
| 3 | Check credits | Credits **unchanged** |
| 4 | No error message | App returns to normal state |

---

## 4. CROSS-DEVICE SYNC

### 4.1 New Device Sync (Cloud Has Credits)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Device A has 12 credits | Verified in app |
| 2 | Install app on Device B (same Apple ID) | App installs |
| 3 | Launch app on Device B | Onboarding/iCloud check |
| 4 | Complete setup on Device B | Home screen shows |
| 5 | Check credits on Device B | Shows **12 credits** (synced from cloud) |
| 6 | Check console | "CloudKit: Local credits updated from 3 to 12" |

### 4.2 Purchase on Device A, Sync to Device B
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Both devices start with 10 credits | Verified |
| 2 | Purchase 25 credits on Device A | Credits now 35 on Device A |
| 3 | On Device B, background then foreground app | App refreshes |
| 4 | Check credits on Device B | Shows **35 credits** |

### 4.3 Deduction on Device A, Sync to Device B
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Both devices have 35 credits | Verified |
| 2 | Generate flyer on Device A | 1 credit deducted, now 34 |
| 3 | On Device B, relaunch app | App syncs on launch |
| 4 | Check credits on Device B | Shows **34 credits** |

### 4.4 Conflict Resolution (Higher Wins)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Device A: 10 credits, Device B: 10 credits | Both synced |
| 2 | Put Device B in airplane mode | Offline |
| 3 | Purchase 25 credits on Device A | Device A now has 35 |
| 4 | Generate 2 flyers on Device B (offline) | Device B now has 8 |
| 5 | Bring Device B online, relaunch app | Sync occurs |
| 6 | Check credits on Device B | Shows **35 credits** (higher wins) |
| 7 | Check credits on Device A | Still **35 credits** |

### 4.5 Simultaneous Usage
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Both devices have 20 credits | Synced |
| 2 | Generate flyer on Device A | Device A: 19 |
| 3 | Immediately generate on Device B | Device B: 19 (from its local) |
| 4 | Wait for both to sync | |
| 5 | Check both devices | Both should show **18 or 19** (no double deduction) |

---

## 5. EDGE CASES

### 5.1 Offline Mode
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enable airplane mode | Device offline |
| 2 | Try to generate flyer | Generation **fails** with network error |
| 3 | Check credits | Credits **unchanged** (no deduction) |
| 4 | Disable airplane mode | Device online |
| 5 | Generate flyer successfully | Credits deducted and synced to CloudKit |

### 5.2 iCloud Sign Out
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Sign out of iCloud in Settings | Account signed out |
| 2 | Launch app | "iCloud Required" screen shows |
| 3 | Cannot access app | Blocked until sign in |

### 5.3 Network Error During Sync
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Purchase credits | Local credits updated |
| 2 | If CloudKit fails | Console shows error |
| 3 | Local credits preserved | App still functional |
| 4 | Next app launch | Retry sync automatically |

### 5.4 Rapid Credit Operations
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Generate flyer | Credit deducted |
| 2 | Immediately refine | Another credit deducted |
| 3 | Immediately resize | Another credit deducted |
| 4 | Check final credits | Exactly 3 credits deducted total |
| 5 | Check CloudKit | Final value synced correctly |

---

## 6. UI VERIFICATION

### 6.1 Credits Display Locations
| Location | Expected Display |
|----------|-----------------|
| Home tab header | Sparkle icon + credit count |
| Premium tab card | "Current Credits: X" |
| Profile tab stats | "Credits Remaining: X" |
| Refine/Resize sheets | Warning if 0 credits |

### 6.2 Real-time Updates
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Note credits on Home tab | e.g., 10 |
| 2 | Go to Premium, purchase | Credits increase |
| 3 | Return to Home tab | Updated credits shown immediately |
| 4 | Generate a flyer | |
| 5 | Check Home tab | Credits reduced immediately |

---

## 7. CONSOLE LOG VERIFICATION

### Expected Log Messages

**On App Launch (with existing CloudKit record):**
```
CloudKit: Local credits updated from X to Y
```

**On First Launch (no CloudKit record):**
```
CloudKit: Created new credits record with 3 credits
```

**On Credit Deduction:**
```
Credit deducted. Remaining credits: X
CloudKit: Credits saved successfully (X)
```

**On Credit Purchase:**
```
CloudKit: Credits saved successfully (X)
```

**On Sync (local higher):**
```
CloudKit: Updated cloud credits from X to Y
```

---

## Test Results Summary

| Test Category | Pass | Fail | Notes |
|---------------|------|------|-------|
| Initial Allocation | | | |
| Credit Deduction | | | |
| Credit Purchases | | | |
| Cross-Device Sync | | | |
| Edge Cases | | | |
| UI Verification | | | |

---

## Sign-Off

| Tester | Date | Device A | Device B | Result |
|--------|------|----------|----------|--------|
| | | | | |
