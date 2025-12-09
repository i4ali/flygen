# FlyGen AI - Pre-Submission Test Plan

## Overview
Comprehensive test plan to thoroughly test the FlyGen AI app before App Store submission.

---

## 1. FIRST LAUNCH & ONBOARDING

### 1.1 Fresh Install
- [ ] App launches without crash
- [ ] Onboarding screens display correctly
- [ ] Lottie animations play smoothly
- [ ] Can navigate through all onboarding steps
- [ ] Skip/Continue buttons work
- [ ] Onboarding completion is saved (doesn't show again)

### 1.2 iCloud Requirement
- [ ] App checks iCloud status on launch
- [ ] Error shown if not signed into iCloud
- [ ] "Open Settings" button works
- [ ] App proceeds when iCloud is available

### 1.3 Initial Credits
- [ ] New user receives 3 free credits
- [ ] Credits display correctly in header
- [ ] UserProfile is created in SwiftData

---

## 2. HOME TAB

### 2.1 UI Elements
- [ ] FlyGen logo/title displays
- [ ] Credits counter shows correct amount
- [ ] Settings gear icon visible and tappable
- [ ] Animated flyer stack displays
- [ ] "Create New Flyer" button visible
- [ ] "Use Template" button visible

### 2.2 Button States
- [ ] Buttons enabled when credits > 0
- [ ] Buttons disabled when credits = 0
- [ ] Warning banner shows when 0 credits
- [ ] Tapping disabled button doesn't crash

### 2.3 Navigation
- [ ] Settings button opens Settings sheet
- [ ] "Create New Flyer" opens creation flow
- [ ] "Use Template" opens template picker

---

## 3. FLYER CREATION FLOW (9 Steps)

### 3.1 Step 1: Category Selection
- [ ] All 13 categories display with emoji icons
- [ ] Can select a category
- [ ] Selection is visually highlighted
- [ ] Can change selection
- [ ] Next button works after selection

### 3.2 Step 2: Text Content
- [ ] Headline field is required (validation)
- [ ] All optional fields visible and editable
- [ ] Keyboard appears/dismisses properly
- [ ] Can scroll through all fields
- [ ] Text persists when navigating back/forward
- [ ] Cannot proceed without headline

### 3.3 Step 3: Visual Style
- [ ] All style options display (Modern, Classic, Bold, etc.)
- [ ] Can select a style
- [ ] Selection feedback works
- [ ] Style persists when navigating

### 3.4 Step 4: Mood Selection
- [ ] All mood options display
- [ ] Color gradient previews visible
- [ ] Can select mood
- [ ] Selection persists

### 3.5 Step 5: Color Selection
- [ ] Color presets display with swatches
- [ ] Background type options work (Solid, Gradient, Pattern)
- [ ] Can select color scheme
- [ ] Preview updates with selection

### 3.6 Step 6: Format Selection
- [ ] All aspect ratios show (Portrait, Landscape, Square, Story)
- [ ] Visual previews correct
- [ ] Imagery type toggle works (Text-Free vs AI Text)
- [ ] Selection persists

### 3.7 Step 7: QR Code (Optional)
- [ ] QR toggle enables/disables QR section
- [ ] Content type picker works (URL, vCard, Text, Email, Phone, WiFi)
- [ ] Correct fields appear for each content type
- [ ] QR position selector works (4 corners)
- [ ] Live QR preview generates
- [ ] QR preview is scannable
- [ ] Fields validate properly

### 3.8 Step 8: Extras/Finishing Touches
- [ ] Logo upload from photo library works
- [ ] Logo preview displays
- [ ] Can remove uploaded logo
- [ ] Target audience field works
- [ ] Special instructions field works

### 3.9 Step 9: Review & Generate
- [ ] All selections display correctly
- [ ] Edit buttons navigate to correct steps
- [ ] Generate button visible
- [ ] Credit cost displayed

### 3.10 Navigation Throughout
- [ ] Back button works at each step
- [ ] Cancel/X dismisses entire flow
- [ ] Progress indicator updates
- [ ] State preserved when navigating back

---

## 4. FLYER GENERATION

### 4.1 Generation Process
- [ ] Loading state shows ("Creating Magic...")
- [ ] Cannot dismiss during generation
- [ ] Generation completes successfully
- [ ] Generated image displays
- [ ] 1 credit deducted after success

### 4.2 Error Handling
- [ ] Network error shows message
- [ ] Timeout shows message (2 min limit)
- [ ] Can retry after error
- [ ] Credits NOT deducted on failure

### 4.3 Result View Actions
- [ ] "Refine" button opens refinement sheet
- [ ] "Resize" button opens aspect ratio picker
- [ ] "Save" button saves to Photos
- [ ] "Done" saves to gallery and dismisses

---

## 5. REFINEMENT

### 5.1 Refinement Flow
- [ ] Refinement sheet opens
- [ ] Can enter feedback text
- [ ] Submit button starts regeneration
- [ ] Loading state shows
- [ ] New image displays on success
- [ ] 1 credit deducted on success

### 5.2 Refinement Validation
- [ ] Cannot submit empty feedback
- [ ] Original image preserved if cancelled

---

## 6. RESIZE/REFORMAT

### 6.1 Resize Flow
- [ ] Aspect ratio picker displays
- [ ] All options selectable
- [ ] Regeneration starts on selection
- [ ] New image displays
- [ ] 1 credit deducted on success

---

## 7. SAVE FUNCTIONALITY

### 7.1 Save to Photos
- [ ] Permission prompt appears (first time)
- [ ] Image saves successfully
- [ ] Success message displays
- [ ] Permission denied handled gracefully

### 7.2 Save to Gallery
- [ ] Flyer saved to SwiftData
- [ ] Appears in My Flyers tab
- [ ] All metadata saved (headline, category, date)

---

## 8. MY FLYERS TAB (Gallery)

### 8.1 Empty State
- [ ] Empty state message shows when no flyers
- [ ] Icon displays

### 8.2 Flyer Display
- [ ] Grid layout (2 columns) works
- [ ] Thumbnails display correctly
- [ ] Headline shows
- [ ] Category shows
- [ ] Date shows

### 8.3 Flyer Interaction
- [ ] Tap opens detail sheet
- [ ] Long-press shows context menu
- [ ] Delete option works
- [ ] Flyer removed from list after delete

### 8.4 Detail Sheet
- [ ] Full image displays
- [ ] Category and date info visible
- [ ] Save to Photos works
- [ ] Share button opens share sheet
- [ ] Dismiss works

---

## 9. GET CREDITS TAB (Premium)

### 9.1 UI Display
- [ ] Current credits shown
- [ ] All 3 credit packs display
- [ ] Prices show correctly
- [ ] Badges show ("Save 20%", "Best Value")
- [ ] Features list displays

### 9.2 Purchase Flow
- [ ] Tapping product initiates purchase
- [ ] Loading state shows
- [ ] System purchase dialog appears
- [ ] Success: credits added, alert shown
- [ ] Cancel: returns to screen, no charges
- [ ] Error: error message shown

### 9.3 After Purchase
- [ ] Credits update immediately
- [ ] Home tab reflects new credits
- [ ] Profile tab reflects new credits
- [ ] Can now create flyers

---

## 10. PROFILE TAB

### 10.1 Profile Display
- [ ] iCloud user info shows
- [ ] Sync status displays
- [ ] Last synced timestamp shows

### 10.2 Statistics
- [ ] Flyers created count correct
- [ ] Credits remaining correct

### 10.3 Settings Options
- [ ] "API Settings" opens settings
- [ ] "Show Onboarding Again" works
- [ ] Version number displays (1.0.0)

### 10.4 Credits Promo
- [ ] "Need More Credits" card displays
- [ ] Tapping navigates to Premium tab

---

## 11. SETTINGS

### 11.1 Settings View
- [ ] Model displays (Gemini Flash)
- [ ] Provider displays (OpenRouter)
- [ ] Version displays (1.0.0)
- [ ] Done button dismisses

---

## 12. QR CODE VERIFICATION

### 12.1 QR Types to Test
- [ ] URL: Scan opens correct URL
- [ ] vCard: Scan adds contact correctly
- [ ] Text: Scan shows correct text
- [ ] Email: Scan opens email compose
- [ ] Phone: Scan offers to call number
- [ ] WiFi: Scan offers to join network

### 12.2 QR Positioning
- [ ] Top-left placement correct
- [ ] Top-right placement correct
- [ ] Bottom-left placement correct
- [ ] Bottom-right placement correct

---

## 13. EDGE CASES & ERROR HANDLING

### 13.1 Network Issues
- [ ] Airplane mode during generation shows error
- [ ] Slow network shows timeout appropriately
- [ ] Network recovery allows retry

### 13.2 Credits Edge Cases
- [ ] Exactly 1 credit: can create, then disabled
- [ ] 0 credits: buttons disabled, banner shows
- [ ] Multiple rapid taps don't double-charge

### 13.3 Data Persistence
- [ ] Kill app during creation: state not corrupted
- [ ] Background app: returns correctly
- [ ] Saved flyers persist after restart
- [ ] Credits persist after restart

### 13.4 Input Edge Cases
- [ ] Very long headline handled
- [ ] Special characters in text work
- [ ] Empty optional fields OK
- [ ] Large logo image handled

---

## 14. PERFORMANCE

### 14.1 UI Performance
- [ ] Smooth scrolling in gallery
- [ ] No lag in creation flow
- [ ] Animations are smooth
- [ ] No memory warnings

### 14.2 Generation Performance
- [ ] Generation completes < 2 minutes
- [ ] App remains responsive during generation
- [ ] Can cancel if needed

---

## 15. COMPLETE USER FLOWS

### 15.1 New User Journey
1. [ ] Fresh install → Onboarding
2. [ ] iCloud check passes
3. [ ] 3 free credits shown
4. [ ] Create first flyer (all steps)
5. [ ] Generate successfully
6. [ ] Save to gallery
7. [ ] View in My Flyers
8. [ ] 2 credits remaining

### 15.2 Purchase Journey
1. [ ] 0 credits state
2. [ ] Navigate to Premium
3. [ ] Purchase 10 credits
4. [ ] Success confirmed
5. [ ] Return to Home
6. [ ] Create new flyer works

### 15.3 Refinement Journey
1. [ ] Generate initial flyer
2. [ ] Tap Refine
3. [ ] Enter feedback
4. [ ] Generate refined version
5. [ ] Save refined version

### 15.4 Template Journey
1. [ ] Tap Use Template
2. [ ] Select template
3. [ ] Modify content
4. [ ] Generate
5. [ ] Save

---

## 16. DEVICE TESTING

### 16.1 Device Sizes
- [ ] iPhone SE (small screen)
- [ ] iPhone 14/15 (standard)
- [ ] iPhone 14/15 Pro Max (large)

### 16.2 iOS Versions
- [ ] iOS 17.5 (minimum)
- [ ] iOS 18.x (latest)

---

## 17. APP STORE REQUIREMENTS

### 17.1 Metadata
- [ ] Screenshots uploaded (10)
- [ ] App description complete
- [ ] Keywords set
- [ ] Support URL valid
- [ ] Privacy policy URL valid
- [ ] Copyright set

### 17.2 Build
- [ ] Build uploaded to App Store Connect
- [ ] Build selected for submission
- [ ] No missing compliance info

### 17.3 App Review Info
- [ ] Sign-in not required (no account system)
- [ ] Contact info provided
- [ ] Notes for reviewer (explain credits/IAP)

---

## Test Results Summary

| Category | Pass | Fail | Notes |
|----------|------|------|-------|
| Onboarding | | | |
| Home Tab | | | |
| Creation Flow | | | |
| Generation | | | |
| Refinement | | | |
| Resize | | | |
| Save | | | |
| Gallery | | | |
| Premium/IAP | | | |
| Profile | | | |
| Settings | | | |
| QR Codes | | | |
| Edge Cases | | | |
| Performance | | | |

---

## Notes for App Review

Include in "Notes for Reviewer" field:
```
This app uses AI to generate flyer images. Users receive 3 free credits on first launch. Each flyer generation costs 1 credit. Additional credits can be purchased via in-app purchase.

No sign-in is required - the app uses iCloud for data sync.

To test the full flow:
1. Launch app and complete onboarding
2. Use free credits to generate a flyer
3. Test refinement and resize features
4. Purchase additional credits if needed (use sandbox account)
```
