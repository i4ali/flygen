# FlyGen Project Guidelines

## Critical Requirements

### Keep Python and iOS Field Configurations in Sync

The category text field configurations **MUST** stay in sync between:

- **iOS (source of truth):** `FlyGen/FlyGen/Models/CategoryConfiguration.swift`
- **Python:** `models.py` → `CATEGORY_TEXT_FIELDS`

When modifying which fields are available for a flyer category:

1. Update iOS `CategoryConfiguration.swift` first (this is the source of truth)
2. Update Python `models.py` `CATEGORY_TEXT_FIELDS` to match
3. Update any test cases in `test_flyer.py` that use affected categories

**Note:** iOS uses `scheduleEntries` for multi-date picker in EVENT and CLASS_WORKSHOP categories. Python uses `date` as the equivalent field.

### Template Field Validation

Templates in `FlyGen/FlyGen/Data/TemplateLibrary.swift` must only use fields that are defined in their category's configuration.

**When modifying templates or category configurations:**

1. If adding a new template, verify all `TextContent` fields used are in the category's allowed fields in `CategoryConfiguration.swift`
2. If removing fields from a category configuration, check that no existing templates use those fields
3. If adding fields to a template, either use existing allowed fields or expand the category configuration (and sync to Python)

**Quick validation:** For each template, its `textContent` fields must be a subset of `CategoryConfiguration.textFields[category]`.

### Test Case Field Validation

Test cases in `test_flyer.py` must only use fields defined in `CATEGORY_TEXT_FIELDS` (in `models.py`) for each category.

**When creating or editing test cases:**

1. Check `CATEGORY_TEXT_FIELDS` in `models.py` for the category's allowed fields
2. Only use `TextContent` fields that are in the allowed list for that category
3. If you need a field that isn't allowed, either:
   - Combine info into an allowed field (e.g., time into date: "January 15, 2025 | 5 PM")
   - Move content to body_text or another appropriate field
   - Change the test case to use a different category that supports those fields

**Quick reference (common categories):**
- EVENT: `headline`, `subheadline`, `date`, `venue_name`, `address`, `cta_text`, `website`
- SALE_PROMO: `headline`, `subheadline`, `discount_text`, `date`, `address`, `cta_text`, `fine_print`, `website`

**Quick validation:** For each test case, its `TextContent` fields must be a subset of `CATEGORY_TEXT_FIELDS[category]`.

### Test Case Settings Must Match iOS Enums Exactly

**CRITICAL:** When adding test cases to `test_flyer.py`, all enum values and settings must use the exact values defined in Python `models.py`, which mirror the iOS app enums.

**Before using any setting, verify it exists:**

| Setting | Python File | iOS File |
|---------|-------------|----------|
| `AspectRatio` | `models.py` | `OutputSettings.swift` |
| `VisualStyle` | `models.py` | `VisualSettings.swift` |
| `Mood` | `models.py` | `VisualSettings.swift` |
| `ColorSchemePreset` | `models.py` | `ColorSettings.swift` |
| `BackgroundType` | `models.py` | `ColorSettings.swift` |
| `TextProminence` | `models.py` | `VisualSettings.swift` |
| `FlyerCategory` | `models.py` | `FlyerCategory.swift` |

**Common mistakes to avoid:**
- `AspectRatio.PORTRAIT` ❌ → `AspectRatio.PORTRAIT_4_5` ✅
- `VisualStyle.LUXURY` ❌ → `VisualStyle.ELEGANT_LUXURY` ✅
- Check `models.py` enum definitions before using any value

**Quick validation:** Run `python test_flyer.py --list` to verify syntax, or `python -c "import test_flyer"` to check for import errors.

### iOS Build Device

Use **iPhone 17 Pro** simulator for building and testing.

### App Store Connect Screenshot Dimensions

**iPhone screenshots must be one of these sizes:**

| Orientation | Size |
|-------------|------|
| Portrait | 1284 × 2778px |
| Landscape | 2778 × 1284px |
| Portrait | 1242 × 2688px |
| Landscape | 2688 × 1242px |

**Resize command:**
```bash
sips -z 2778 1284 "input.png" --out "output.png"
```

### Adding Files to Xcode Project Programmatically

When adding new resource files (like Lottie animations, images, etc.) to the iOS project, you must edit `FlyGen.xcodeproj/project.pbxproj` in **4 places**:

1. **PBXBuildFile section** - Add build file entry:
   ```
   AAONBAIANALYS01 /* filename.json in Resources */ = {isa = PBXBuildFile; fileRef = BBONBAIANALYS01 /* filename.json */; };
   ```

2. **PBXFileReference section** - Add file reference:
   ```
   BBONBAIANALYS01 /* filename.json */ = {isa = PBXFileReference; lastKnownFileType = text.json; path = "filename.json"; sourceTree = "<group>"; };
   ```

3. **PBXGroup section** - Add to the appropriate group (e.g., Animations):
   ```
   BBONBAIANALYS01 /* filename.json */,
   ```

4. **PBXResourcesBuildPhase section** - Add to Resources build phase:
   ```
   AAONBAIANALYS01 /* filename.json in Resources */,
   ```

**Tips:**
- Use unique IDs (e.g., `AAONBAIANALYS01` for build file, `BBONBAIANALYS01` for file reference)
- Search for similar existing files to find the exact insertion points
- Use `grep -n "existing-file.json" project.pbxproj` to find all 4 locations
- `lastKnownFileType` values: `text.json` for JSON, `image.png` for PNG, `sourcecode.swift` for Swift
