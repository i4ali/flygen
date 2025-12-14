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
- REAL_ESTATE: `headline`, `price`, `address`, `body_text`, `phone`, `email`, `website`
- ANNOUNCEMENT: `headline`, `subheadline`, `body_text`, `date`, `cta_text`

**Quick validation:** For each test case, its `TextContent` fields must be a subset of `CATEGORY_TEXT_FIELDS[category]`.
