# FlyGen iOS App - Product Requirements Document (PRD)

**Version:** 1.0
**Date:** December 6, 2024
**Status:** Draft

---

## 1. Executive Summary

### 1.1 Product Vision
FlyGen is an AI-powered flyer generation iOS app that transforms user intent into professional marketing materials through intelligent guided intake. The app's competitive advantage lies in its structured prompt engineering system that reduces iterations and improves AI output quality.

### 1.2 Problem Statement
Creating professional flyers typically requires:
- Design software expertise (Canva, Photoshop)
- Understanding of design principles
- Multiple iterations to achieve desired results
- Time investment of 30-60 minutes per design

FlyGen solves this by guiding users through a structured 7-step intake process that captures their intent and translates it into optimized AI prompts, generating professional results in under 2 minutes.

### 1.3 Target Users
| Segment | Description | Primary Use Cases |
|---------|-------------|-------------------|
| General Consumers | Individuals creating personal flyers | Parties, garage sales, community events, personal announcements |
| Small Business Owners | Local businesses without design resources | Sales, grand openings, promotions, hiring, menus |
| Marketing Teams | Professionals needing quick iterations | Mockups, A/B testing concepts, rapid prototyping |

---

## 2. Core User Flow

### 2.1 Complete Flow Diagram

```
┌─────────────────┐
│   Onboarding    │ (First launch only)
└────────┬────────┘
         ▼
┌─────────────────┐
│    Home/Dashboard│
└────────┬────────┘
         ▼
┌─────────────────┐
│ 1. Category     │ Select flyer type (12 options)
└────────┬────────┘
         ▼
┌─────────────────┐
│ 2. Text Content │ Enter headline, details (dynamic fields)
└────────┬────────┘
         ▼
┌─────────────────┐
│ 3. Visual Style │ Choose aesthetic (10 styles)
└────────┬────────┘
         ▼
┌─────────────────┐
│ 4. Mood/Tone    │ Select emotional direction (9 moods)
└────────┬────────┘
         ▼
┌─────────────────┐
│ 5. Colors       │ Palette, background type
└────────┬────────┘
         ▼
┌─────────────────┐
│ 6. Format       │ Aspect ratio for platform
└────────┬────────┘
         ▼
┌─────────────────┐
│ 6b. Text Mode   │ AI-rendered vs Text-free
└────────┬────────┘
         ▼
┌─────────────────┐
│ 7. Extras       │ Include/avoid, audience, logo
└────────┬────────┘
         ▼
┌─────────────────┐
│   Review        │ Summary before generation
└────────┬────────┘
         ▼
┌─────────────────┐
│   Generation    │ AI creates flyer (loading state)
└────────┬────────┘
         ▼
┌─────────────────┐
│   Result        │ View, refine, reformat, or save
└────────┴─────┬──┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌───────┐ ┌────────┐ ┌─────────┐
│Refine │ │Reformat│ │  Done   │
└───┬───┘ └───┬────┘ └────┬────┘
    │         │           │
    └─────────┴───────────┘
              ▼
     ┌────────────────┐
     │  My Flyers     │ (Gallery/History)
     └────────────────┘
```

---

## 3. Screen Specifications

### 3.1 Onboarding (First Launch)

**Purpose:** Introduce app value and collect essential permissions

| Screen | Content | Actions |
|--------|---------|---------|
| Welcome | App logo, tagline "Professional flyers in seconds" | Continue |
| Value Props | 3 slides: Speed, Quality, Simplicity | Swipe/Skip |
| Permissions | Photo library access request | Allow/Deny |
| Account | Sign up / Sign in options | Apple, Google, Email |

### 3.2 Home Dashboard

**Purpose:** Entry point for new creations and access to history

**Layout:**
```
┌─────────────────────────────────┐
│  [Profile]     FlyGen    [⚙️]   │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │   + Create New Flyer      │  │
│  │   (Large CTA button)      │  │
│  └───────────────────────────┘  │
│                                 │
│  Credits: 5 remaining          │
│  ─────────────────────────     │
│                                 │
│  Recent Flyers                  │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │     │ │     │ │     │       │
│  │ img │ │ img │ │ img │       │
│  │     │ │     │ │     │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│  Templates (Coming Soon)        │
│                                 │
├─────────────────────────────────┤
│  [🏠]    [📁]    [⭐]    [👤]   │
│  Home   Flyers  Premium Profile │
└─────────────────────────────────┘
```

### 3.3 Screen 1: Category Selection

**Purpose:** Determine flyer type to customize subsequent fields

**Categories (12 options):**
| Category | Icon | Description |
|----------|------|-------------|
| Event | 🎪 | Conferences, meetups, festivals |
| Sale / Promotion | 🏷️ | Discounts, deals, clearance |
| Grand Opening | 🎉 | New business, location launch |
| Restaurant / Food | 🍽️ | Menus, specials, food trucks |
| Class / Workshop | 📚 | Educational, training, seminars |
| Party / Celebration | 🎈 | Birthdays, weddings, gatherings |
| Fitness / Wellness | 💪 | Gym, yoga, health services |
| Music / Concert | 🎵 | Shows, performances, DJ nights |
| Job Posting | 💼 | Hiring, recruitment |
| Real Estate | 🏠 | Listings, open houses |
| Nonprofit / Charity | ❤️ | Fundraisers, awareness |
| Announcement | 📢 | General notices, updates |

**Layout:**
```
┌─────────────────────────────────┐
│  ←  What are you creating?      │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🎪  Event               │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🏷️  Sale / Promotion    │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🎉  Grand Opening       │    │
│  └─────────────────────────┘    │
│          ... etc               │
│                                 │
│  Progress: ●○○○○○○             │
└─────────────────────────────────┘
```

### 3.4 Screen 2: Text Content

**Purpose:** Capture all text elements for the flyer

**Dynamic Field Mapping by Category:**

| Category | Required | Optional Fields |
|----------|----------|-----------------|
| Event | Headline | Date, Time, Venue, Address, Price, CTA, Website |
| Sale/Promotion | Headline | Discount Text, Valid Dates, Address, CTA, Fine Print |
| Grand Opening | Headline | Date, Time, Address, Special Offers, CTA |
| Restaurant/Food | Headline | Address, Phone, Website, Price/Menu Items |
| Class/Workshop | Headline | Date, Time, Venue, Price, Instructor, CTA |
| Party/Celebration | Headline | Date, Time, Venue, RSVP Info |
| Fitness/Wellness | Headline | Schedule, Location, Price, CTA |
| Music/Concert | Headline | Date, Time, Venue, Ticket Price, Lineup |
| Job Posting | Headline | Subheadline, Description, Requirements, Email, Website |
| Real Estate | Headline | Price, Address, Features, Phone, Email, Website |
| Nonprofit/Charity | Headline | Date, Venue, Donation Info, CTA |
| Announcement | Headline | Subheadline, Body Text, Date, CTA |

**Layout:**
```
┌─────────────────────────────────┐
│  ←  Add your text               │
├─────────────────────────────────┤
│                                 │
│  Headline *                     │
│  ┌─────────────────────────┐    │
│  │ MEGA SUMMER SALE        │    │
│  └─────────────────────────┘    │
│                                 │
│  Discount (e.g., "50% OFF")     │
│  ┌─────────────────────────┐    │
│  │ UP TO 70% OFF           │    │
│  └─────────────────────────┘    │
│                                 │
│  Valid Dates                    │
│  ┌─────────────────────────┐    │
│  │ July 1-15               │    │
│  └─────────────────────────┘    │
│                                 │
│  Address                        │
│  ┌─────────────────────────┐    │
│  │ 123 Main St, Downtown   │    │
│  └─────────────────────────┘    │
│                                 │
│  [Show More Fields ▼]           │
│                                 │
├─────────────────────────────────┤
│  Progress: ●●○○○○○    [Next →] │
└─────────────────────────────────┘
```

### 3.5 Screen 3: Visual Style

**Purpose:** Select the design aesthetic

**Styles (10 options):**

| Style | Preview Description | Prompt Expansion |
|-------|---------------------|------------------|
| Modern & Minimal | Clean lines, white space | "clean lines, generous white space, contemporary sans-serif typography, uncluttered composition, sophisticated simplicity" |
| Bold & Vibrant | High contrast, saturated | "bold vibrant design with strong saturated colors, high contrast, impactful heavy typography, energetic dynamic composition" |
| Elegant & Luxury | Gold accents, serif fonts | "elegant luxury design with refined serif typography, gold accents, premium sophisticated color palette" |
| Playful & Fun | Rounded shapes, bright | "playful fun design with rounded shapes, bright cheerful colors, whimsical elements, friendly casual typography" |
| Hand-drawn & Organic | Illustrations, sketchy | "hand-drawn organic aesthetic with illustrated elements, natural textures, artisanal handcrafted feel" |
| Retro / Vintage | 70s-80s inspired | "retro vintage design inspired by classic advertising, nostalgic color palette, decorative typography" |
| Corporate / Professional | Business formal | "corporate professional design with clean business aesthetic, trust-building colors, formal typography" |
| Neon Glow | Dark background, glowing | "neon glow design with dark background, vibrant glowing elements, electric colors, nightlife energy" |
| Gradient Modern | Smooth color transitions | "modern gradient design with smooth color transitions, contemporary layout, fresh aesthetic" |
| Watercolor Artistic | Soft, painted look | "watercolor artistic design with soft painted textures, organic color bleeds, creative artistic expression" |

**Layout:** Grid of 2x5 visual style cards with preview thumbnails

### 3.6 Screen 4: Mood/Tone

**Purpose:** Add emotional direction to the design

**Moods (9 options):**

| Mood | Description | Prompt Addition |
|------|-------------|-----------------|
| Friendly & Welcoming | Approachable, warm | "warm inviting approachable atmosphere, welcoming friendly tone" |
| Exciting & Energetic | Dynamic, high-energy | "dynamic exciting high-energy vibe, movement and action" |
| Urgent (Act Now!) | Time-sensitive, bold | "urgency-driven design, compelling call-to-action, limited-time feel" |
| Professional | Trustworthy, business | "professional trustworthy business tone, credibility and reliability" |
| Elegant & Sophisticated | Refined, upscale | "sophisticated refined elegance, upscale premium feel" |
| Calm & Peaceful | Serene, relaxing | "calm peaceful serene atmosphere, soothing relaxing vibe" |
| Festive & Celebratory | Party, joyful | "festive celebratory joyful mood, celebration and excitement" |
| Inspirational | Motivating, uplifting | "inspirational motivating uplifting message, positive empowering" |
| Serious & Important | Formal, significant | "serious important formal tone, significance and gravity" |

**Layout:** Single-select pill buttons or cards

### 3.7 Screen 5: Colors

**Purpose:** Define color scheme and background

**Color Presets (8 palettes):**
- Warm (reds, oranges, yellows)
- Cool (blues, greens, teals)
- Pastel (soft muted tones)
- Earth Tones (browns, greens, terracotta)
- Neon (bright fluorescent)
- Monochrome (single color variations)
- Black & Gold (luxury)
- Custom (user-defined)

**Background Types:**
- Light (white/cream)
- Dark (black/navy)
- Gradient (smooth transition)
- Textured (subtle patterns)
- Solid (single color)

**Custom Color Picker (if Custom selected):**
- Primary Color (color wheel)
- Secondary Color (color wheel)
- Accent Color (color wheel)

**Layout:**
```
┌─────────────────────────────────┐
│  ←  Choose colors               │
├─────────────────────────────────┤
│                                 │
│  Color Palette                  │
│  ┌─────┐┌─────┐┌─────┐┌─────┐  │
│  │Warm ││Cool ││Past ││Earth│  │
│  └─────┘└─────┘└─────┘└─────┘  │
│  ┌─────┐┌─────┐┌─────┐┌─────┐  │
│  │Neon ││Mono ││B&G  ││Cust │  │
│  └─────┘└─────┘└─────┘└─────┘  │
│                                 │
│  Background Style               │
│  ○ Light  ○ Dark  ○ Gradient   │
│  ○ Textured  ○ Solid           │
│                                 │
│  [Advanced: Custom Colors ▼]    │
│                                 │
├─────────────────────────────────┤
│  Progress: ●●●●●○○    [Next →] │
└─────────────────────────────────┘
```

### 3.8 Screen 6: Format/Aspect Ratio

**Purpose:** Select output dimensions for intended platform

**Formats (6 options):**

| Format | Ratio | Dimensions | Use Case |
|--------|-------|------------|----------|
| Instagram Post | 4:5 | 1080x1350 | Social feed posts |
| Square | 1:1 | 1080x1080 | Universal social |
| Story/Reel | 9:16 | 1080x1920 | Instagram/TikTok stories |
| Banner/Landscape | 16:9 | 1920x1080 | Facebook covers, web |
| Print - Letter | 8.5x11 | 2550x3300 | US standard printing |
| Print - A4 | 210x297mm | 2480x3508 | International printing |

**Layout:** Visual cards showing aspect ratio previews with platform icons

### 3.9 Screen 6b: Text Rendering Mode

**Purpose:** Choose how text is handled in the design

**Options:**

| Mode | Description | When to Use |
|------|-------------|-------------|
| Illustrated | AI renders all text directly in image | Quick use, social sharing |
| Text-Free | Clean design without text for manual overlay | Professional editing in Canva/Photoshop |

**Layout:** Two large option cards with visual examples

### 3.10 Screen 7: Finishing Touches

**Purpose:** Final customization options

**Fields:**
- **Include Elements:** Comma-separated list (e.g., "balloons, confetti, stars")
- **Avoid Elements:** Comma-separated list (e.g., "people, faces, hands")
- **Target Audience:** Free text description
- **Special Instructions:** Additional notes for AI
- **Logo Upload:** Photo picker / camera option

**Layout:**
```
┌─────────────────────────────────┐
│  ←  Finishing touches           │
├─────────────────────────────────┤
│                                 │
│  Elements to include            │
│  ┌─────────────────────────┐    │
│  │ shopping bags, price ta │    │
│  └─────────────────────────┘    │
│  💡 Suggested: sale tags, burst │
│                                 │
│  Elements to avoid              │
│  ┌─────────────────────────┐    │
│  │ people, faces           │    │
│  └─────────────────────────┘    │
│                                 │
│  Target audience                │
│  ┌─────────────────────────┐    │
│  │ Young professionals 25-4│    │
│  └─────────────────────────┘    │
│                                 │
│  Special instructions           │
│  ┌─────────────────────────┐    │
│  │ Make the discount very  │    │
│  │ prominent and eye-catch │    │
│  └─────────────────────────┘    │
│                                 │
│  Logo (optional)                │
│  ┌─────────────────────────┐    │
│  │  📷  Add Logo           │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  Progress: ●●●●●●●   [Review →]│
└─────────────────────────────────┘
```

### 3.11 Review Screen

**Purpose:** Summary before generation with edit capability

**Layout:**
```
┌─────────────────────────────────┐
│  ←  Review your flyer           │
├─────────────────────────────────┤
│                                 │
│  Category        [Edit]         │
│  Sale / Promotion               │
│  ───────────────────────        │
│  Text Content    [Edit]         │
│  Headline: MEGA SUMMER SALE     │
│  Discount: UP TO 70% OFF        │
│  ───────────────────────        │
│  Visual Style    [Edit]         │
│  Bold & Vibrant                 │
│  ───────────────────────        │
│  Mood            [Edit]         │
│  Urgent (Act Now!)              │
│  ───────────────────────        │
│  Colors          [Edit]         │
│  Warm palette, Dark background  │
│  ───────────────────────        │
│  Format          [Edit]         │
│  Instagram Post (4:5)           │
│  ───────────────────────        │
│                                 │
│  ┌─────────────────────────┐    │
│  │    ✨ Generate Flyer    │    │
│  │    (Uses 1 credit)      │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

### 3.12 Generation Screen

**Purpose:** Loading state during AI generation

**States:**
1. **Generating** - Animated loading with progress messages
   - "Crafting your design..."
   - "Adding finishing touches..."
   - "Almost there..."
2. **Error** - Retry option with error message
3. **Complete** - Auto-transition to Result screen

**Estimated Time:** 10-30 seconds depending on model

### 3.13 Result Screen

**Purpose:** View generated flyer with action options

**Layout:**
```
┌─────────────────────────────────┐
│  ×                    [Share]   │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │                         │    │
│  │                         │    │
│  │    [Generated Flyer     │    │
│  │     Image Display]      │    │
│  │                         │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌───────┐ ┌───────┐ ┌───────┐ │
│  │🔄     │ │📐     │ │💾     │ │
│  │Refine │ │Resize │ │ Save  │ │
│  └───────┘ └───────┘ └───────┘ │
│                                 │
│  ┌─────────────────────────┐    │
│  │   ✅ Done - Keep This   │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

### 3.14 Refinement Flow

**Purpose:** Iterate on generated design based on feedback

**Refinement Input:**
```
┌─────────────────────────────────┐
│  ←  Refine your flyer           │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Current flyer preview]  │  │
│  └───────────────────────────┘  │
│                                 │
│  What would you like to change? │
│  ┌─────────────────────────┐    │
│  │ Make the headline bigger│    │
│  │ and add more contrast   │    │
│  └─────────────────────────┘    │
│                                 │
│  Quick suggestions:             │
│  [Make text bigger]             │
│  [More contrast]                │
│  [Less busy]                    │
│  [More exciting]                │
│  [Change colors]                │
│                                 │
│  ○ Edit existing image          │
│  ○ Create new from scratch      │
│                                 │
│  ┌─────────────────────────┐    │
│  │   ✨ Apply Changes      │    │
│  │   (Uses 1 credit)       │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Refinement Translations (from Python):**
| User Feedback | Prompt Modification |
|---------------|---------------------|
| "make text bigger" | "larger, more prominent text that commands attention" |
| "too busy" | "simplified composition with more white space" |
| "more exciting" | "more dynamic, energetic, and attention-grabbing design" |
| "brighter colors" | "more vibrant, saturated, eye-catching colors" |
| "more professional" | "cleaner, more corporate and business-appropriate design" |

### 3.15 Reformat Flow

**Purpose:** Generate same design in different aspect ratio

**Layout:** Quick format selector with preview of new dimensions

---

## 4. Data Models

### 4.1 Core Models (Swift)

```swift
// MARK: - Enums

enum FlyerCategory: String, Codable, CaseIterable {
    case event = "Event"
    case salePromotion = "Sale / Promotion"
    case grandOpening = "Grand Opening"
    case restaurantFood = "Restaurant / Food"
    case classWorkshop = "Class / Workshop"
    case partyCelebration = "Party / Celebration"
    case fitnessWellness = "Fitness / Wellness"
    case musicConcert = "Music / Concert"
    case jobPosting = "Job Posting"
    case realEstate = "Real Estate"
    case nonprofitCharity = "Nonprofit / Charity"
    case announcement = "Announcement"
}

enum VisualStyle: String, Codable, CaseIterable {
    case modernMinimal = "Modern & Minimal"
    case boldVibrant = "Bold & Vibrant"
    case elegantLuxury = "Elegant & Luxury"
    case playfulFun = "Playful & Fun"
    case handDrawnOrganic = "Hand-drawn & Organic"
    case retroVintage = "Retro / Vintage"
    case corporateProfessional = "Corporate / Professional"
    case neonGlow = "Neon Glow"
    case gradientModern = "Gradient Modern"
    case watercolorArtistic = "Watercolor Artistic"
}

enum Mood: String, Codable, CaseIterable {
    case friendlyWelcoming = "Friendly & Welcoming"
    case excitingEnergetic = "Exciting & Energetic"
    case urgent = "Urgent (Act Now!)"
    case professional = "Professional"
    case elegantSophisticated = "Elegant & Sophisticated"
    case calmPeaceful = "Calm & Peaceful"
    case festiveCelebratory = "Festive & Celebratory"
    case inspirational = "Inspirational"
    case seriousImportant = "Serious & Important"
}

enum AspectRatio: String, Codable, CaseIterable {
    case instagramPost = "4:5"      // 1080x1350
    case square = "1:1"             // 1080x1080
    case storyReel = "9:16"         // 1080x1920
    case bannerLandscape = "16:9"   // 1920x1080
    case printLetter = "letter"     // 2550x3300
    case printA4 = "a4"             // 2480x3508
}

enum ColorSchemePreset: String, Codable, CaseIterable {
    case warm, cool, pastel, earthTones
    case neon, monochrome, blackAndGold, custom
}

enum BackgroundType: String, Codable, CaseIterable {
    case light, dark, gradient, textured, solid
}

enum TextRenderingMode: String, Codable {
    case illustrated = "ILLUSTRATED"
    case textFree = "NO_TEXT"
}

// MARK: - Data Structures

struct TextContent: Codable {
    var headline: String
    var subheadline: String?
    var bodyText: String?
    var date: String?
    var time: String?
    var venueName: String?
    var address: String?
    var price: String?
    var discountText: String?
    var ctaText: String?
    var phone: String?
    var email: String?
    var website: String?
    var socialHandle: String?
    var additionalInfo: [String]?
    var finePrint: String?
}

struct ColorSettings: Codable {
    var preset: ColorSchemePreset
    var primaryColor: String?      // Hex color
    var secondaryColor: String?    // Hex color
    var accentColor: String?       // Hex color
    var backgroundType: BackgroundType
    var backgroundColor: String?   // Hex color
    var gradientColors: [String]?  // Hex colors
}

struct VisualSettings: Codable {
    var style: VisualStyle
    var mood: Mood
    var textRenderingMode: TextRenderingMode
    var includeElements: [String]
    var avoidElements: [String]
}

struct OutputSettings: Codable {
    var aspectRatio: AspectRatio
    var quality: String = "hd"
}

struct FlyerProject: Codable, Identifiable {
    let id: UUID
    var category: FlyerCategory
    var textContent: TextContent
    var colors: ColorSettings
    var visuals: VisualSettings
    var output: OutputSettings
    var targetAudience: String?
    var specialInstructions: String?
    var logoImageData: Data?
    var createdAt: Date
    var updatedAt: Date
}

struct GeneratedFlyer: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let imageData: Data
    let prompt: String
    let model: String
    let createdAt: Date
}
```

### 4.2 User & Subscription Models

```swift
struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var displayName: String?
    var subscriptionTier: SubscriptionTier
    var creditsRemaining: Int
    var createdAt: Date
}

enum SubscriptionTier: String, Codable {
    case free = "Free"
    case starter = "Starter"
    case pro = "Pro"
    case business = "Business"
}

struct CreditTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Int          // Positive = added, Negative = used
    let reason: String       // "generation", "purchase", "subscription_renewal"
    let timestamp: Date
}
```

---

## 5. API Specifications

### 5.1 Image Generation API

**Endpoint:** OpenAI / OpenRouter API

**Request Flow:**
1. App builds prompt using PromptBuilder logic
2. Send request to image generation API
3. Receive image URL or base64 data
4. Save to local storage and display

**Supported Models:**
| Model | Provider | Cost Estimate | Features |
|-------|----------|---------------|----------|
| DALL-E 3 | OpenAI | ~$0.04-0.08 | Best text rendering |
| GPT-Image-1 | OpenAI | ~$0.08 | Newer model |
| Gemini Flash | OpenRouter | Variable | Logo support |

**API Request (OpenAI):**
```json
POST https://api.openai.com/v1/images/generations
{
    "model": "dall-e-3",
    "prompt": "[Generated prompt from PromptBuilder]",
    "n": 1,
    "size": "1024x1792",
    "quality": "hd"
}
```

**API Response:**
```json
{
    "created": 1234567890,
    "data": [
        {
            "url": "https://...",
            "revised_prompt": "..."
        }
    ]
}
```

### 5.2 Backend API (Future)

For user management, subscription handling, and analytics:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/signup` | POST | Create account |
| `/auth/login` | POST | Authenticate |
| `/users/me` | GET | Get current user |
| `/credits/balance` | GET | Check credit balance |
| `/credits/purchase` | POST | Buy credits |
| `/flyers` | GET | List user's flyers |
| `/flyers` | POST | Save flyer project |
| `/flyers/{id}` | DELETE | Delete flyer |

---

## 6. Prompt Engineering System

### 6.1 Prompt Structure (14 Components)

Port the Python `prompt_builder.py` logic to Swift:

1. **Category Context** - Category-specific design guidance
2. **Aspect Ratio** - Dimension specifications
3. **Visual Style** - Expanded style description
4. **Mood/Tone** - Emotional direction
5. **Color Palette** - Detailed color instructions
6. **Text Content** - All text with spelling emphasis
7. **Text Prominence** - How prominent text should be
8. **Text Rendering Mode** - Illustrated vs text-free
9. **Include Elements** - Specific elements to add
10. **Category Hints** - Category-specific suggestions
11. **Target Audience** - Who it's for
12. **Special Instructions** - Custom notes
13. **Logo Instructions** - If logo provided
14. **Quality & Critical Requirements** - Final reminders

### 6.2 Text Spelling Strategy

Critical for AI text accuracy:

```swift
func emphasizeSpelling(_ text: String) -> String {
    // Short text: spell character by character
    if text.count <= 20 {
        return text.map { String($0) }.joined(separator: " ")
        // "SALE" -> "S A L E"
    }

    // Long text: chunk into 5-word segments
    let words = text.split(separator: " ")
    var chunks: [String] = []
    for i in stride(from: 0, to: words.count, by: 5) {
        let chunk = words[i..<min(i+5, words.count)].joined(separator: " ")
        chunks.append("'\(chunk)'")
    }
    return chunks.joined(separator: ", then ")
}
```

### 6.3 Negative Prompts

Always included to prevent common issues:

**Universal:**
- "blurry text, misspelled words, cluttered composition"
- "clipart, amateur design, excessive drop shadows"
- "too many fonts, watermarks, stock photo feel"

**Category-Specific:**
- Sale: "subtle hidden pricing, calm muted urgency"
- Food: "unappetizing imagery, cold sterile colors"
- Professional: "casual unprofessional elements, clip art"

---

## 7. Monetization Strategy

### 7.1 Pricing Tiers

| Tier | Price | Credits/Month | Features |
|------|-------|---------------|----------|
| Free | $0 | 3 | Basic styles, watermark, standard quality |
| Starter | $4.99/mo | 20 | All styles, no watermark, HD quality |
| Pro | $12.99/mo | 60 | + Logo upload, priority generation, refinements |
| Business | $29.99/mo | 200 | + API access, bulk generation, team sharing |

### 7.2 Credit System

| Action | Credits Used |
|--------|--------------|
| Generate flyer | 1 |
| Refine flyer | 1 |
| Reformat flyer | 0.5 |
| HD export | 0 (included in tier) |

### 7.3 Credit Packs (One-time Purchase)

| Pack | Price | Credits | Savings |
|------|-------|---------|---------|
| Small | $2.99 | 5 | - |
| Medium | $7.99 | 15 | 10% |
| Large | $14.99 | 35 | 20% |
| XL | $29.99 | 80 | 25% |

### 7.4 Revenue Model

```
Monthly Revenue = (Subscribers × Tier Price) + (Credit Pack Sales)
Target:
- 10K free users (funnel)
- 2K Starter ($9,980/mo)
- 500 Pro ($6,495/mo)
- 50 Business ($1,500/mo)
- Credit packs: ~$3,000/mo
Total: ~$21K/mo at scale
```

---

## 8. Technical Architecture

### 8.1 App Architecture

```
┌─────────────────────────────────────────┐
│               SwiftUI Views              │
│  (Screens, Components, Navigation)       │
├─────────────────────────────────────────┤
│             ViewModels (MVVM)            │
│  (FlyerCreationVM, GalleryVM, etc.)     │
├─────────────────────────────────────────┤
│               Services                   │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │PromptBuilder│ │ImageGenerationSvc│   │
│  └─────────────┘ └─────────────────┘    │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │ AuthService │ │ CreditsService  │    │
│  └─────────────┘ └─────────────────┘    │
├─────────────────────────────────────────┤
│            Data Layer                    │
│  ┌─────────────┐ ┌─────────────────┐    │
│  │  SwiftData  │ │   Keychain      │    │
│  │  (Local DB) │ │  (Credentials)  │    │
│  └─────────────┘ └─────────────────┘    │
├─────────────────────────────────────────┤
│           Network Layer                  │
│  ┌─────────────────────────────────┐    │
│  │     URLSession / Async-Await    │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 8.2 Key Dependencies

- **SwiftUI** - UI framework
- **SwiftData** - Local persistence
- **StoreKit 2** - In-app purchases
- **AuthenticationServices** - Sign in with Apple
- **PhotosUI** - Photo picker for logos

### 8.3 Minimum Requirements

- iOS 17.0+
- iPhone only (initial release)
- iPad support (v1.1)

---

## 9. Edge Cases & Error Handling

### 9.1 Generation Failures

| Error | Cause | User Message | Recovery |
|-------|-------|--------------|----------|
| API Timeout | Slow response | "Taking longer than expected..." | Auto-retry x2, then manual retry |
| Content Policy | Rejected prompt | "We couldn't generate this design. Try different text." | Edit text content |
| Rate Limit | Too many requests | "Please wait a moment..." | Automatic backoff |
| Network Error | No connection | "Check your internet connection" | Retry when online |
| Credit Exhausted | No credits | "You're out of credits" | Upsell to purchase |

### 9.2 Input Validation

| Field | Validation | Error Message |
|-------|------------|---------------|
| Headline | Required, max 100 chars | "Headline is required" / "Headline too long" |
| Email | Valid format | "Enter a valid email" |
| Phone | Numeric with optional formatting | "Enter a valid phone number" |
| Website | Valid URL | "Enter a valid website" |
| Logo | Image file, max 5MB | "Logo must be an image under 5MB" |

### 9.3 State Preservation

- Save draft on every screen transition
- Restore draft if app terminated during creation
- Clear draft only after successful generation or explicit discard

---

## 10. Analytics & Metrics

### 10.1 Key Events

| Event | Properties | Purpose |
|-------|------------|---------|
| `onboarding_complete` | method (apple/google/email) | Conversion tracking |
| `creation_started` | category | Feature usage |
| `screen_completed` | screen_number, time_spent | Funnel analysis |
| `generation_requested` | model, category, style | Usage patterns |
| `generation_success` | duration, model | Performance |
| `generation_failed` | error_type, model | Error tracking |
| `refinement_used` | feedback_type | Feature adoption |
| `flyer_saved` | format, category | Completion rate |
| `flyer_shared` | platform | Virality |
| `credits_purchased` | pack, price | Revenue |
| `subscription_started` | tier, price | Revenue |

### 10.2 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Onboarding completion | >70% | Complete / Started |
| Creation completion | >50% | Generated / Started |
| Refinement rate | <30% | Refinements / Generations |
| Free-to-paid conversion | >5% | Paid / Free users |
| Monthly retention | >40% | MAU returning |
| NPS | >50 | Survey |

---

## 11. Launch Plan

### 11.1 MVP Features (v1.0)

- [ ] Complete 7-screen creation flow
- [ ] 12 categories with dynamic fields
- [ ] 10 visual styles, 9 moods
- [ ] 6 aspect ratios
- [ ] DALL-E 3 integration
- [ ] Basic refinement (new generation)
- [ ] Photo library save
- [ ] Credit system (free tier: 3)
- [ ] Sign in with Apple

### 11.2 v1.1 Features

- [ ] Reformat existing flyers
- [ ] Edit refinement (modify existing)
- [ ] Logo upload support
- [ ] iPad support
- [ ] Template gallery
- [ ] Share directly to social

### 11.3 v1.2 Features

- [ ] Multiple AI model support
- [ ] Saved brand kits (colors, logos)
- [ ] Flyer history with search
- [ ] Offline draft editing
- [ ] Widget for quick creation

---

## 12. Appendix

### 12.1 Category to Text Field Mapping

```swift
let categoryTextFields: [FlyerCategory: [TextFieldType]] = [
    .event: [.headline, .date, .time, .venueName, .address, .price, .ctaText, .website],
    .salePromotion: [.headline, .discountText, .date, .address, .ctaText, .finePrint],
    .grandOpening: [.headline, .date, .time, .address, .ctaText, .website],
    .restaurantFood: [.headline, .address, .phone, .website, .price],
    .classWorkshop: [.headline, .date, .time, .venueName, .price, .ctaText],
    .partyCelebration: [.headline, .date, .time, .venueName, .ctaText],
    .fitnessWellness: [.headline, .date, .time, .address, .price, .ctaText],
    .musicConcert: [.headline, .date, .time, .venueName, .price, .ctaText],
    .jobPosting: [.headline, .subheadline, .bodyText, .ctaText, .email, .website],
    .realEstate: [.headline, .price, .address, .bodyText, .phone, .email, .website],
    .nonprofitCharity: [.headline, .date, .venueName, .ctaText, .website],
    .announcement: [.headline, .subheadline, .bodyText, .date, .ctaText]
]
```

### 12.2 Style Expansion Mappings

```swift
let styleExpansions: [VisualStyle: String] = [
    .modernMinimal: "clean lines, generous white space, contemporary sans-serif typography, uncluttered composition, sophisticated simplicity",
    .boldVibrant: "bold vibrant design with strong saturated colors, high contrast, impactful heavy typography, energetic dynamic composition",
    .elegantLuxury: "elegant luxury design with refined serif typography, gold accents, premium sophisticated color palette",
    .playfulFun: "playful fun design with rounded shapes, bright cheerful colors, whimsical elements, friendly casual typography",
    .handDrawnOrganic: "hand-drawn organic aesthetic with illustrated elements, natural textures, artisanal handcrafted feel",
    .retroVintage: "retro vintage design inspired by classic advertising, nostalgic color palette, decorative typography",
    .corporateProfessional: "corporate professional design with clean business aesthetic, trust-building colors, formal typography",
    .neonGlow: "neon glow design with dark background, vibrant glowing elements, electric colors, nightlife energy",
    .gradientModern: "modern gradient design with smooth color transitions, contemporary layout, fresh aesthetic",
    .watercolorArtistic: "watercolor artistic design with soft painted textures, organic color bleeds, creative artistic expression"
]
```

### 12.3 Refinement Pattern Translations

```swift
let refinementPatterns: [String: String] = [
    "bigger": "larger, more prominent text that commands attention",
    "smaller": "more compact, refined text sizing",
    "too busy": "simplified composition with more white space",
    "more exciting": "more dynamic, energetic, and attention-grabbing design",
    "brighter": "more vibrant, saturated, eye-catching colors",
    "darker": "deeper, richer, more dramatic tones",
    "more professional": "cleaner, more corporate and business-appropriate design",
    "more fun": "more playful, energetic, and engaging elements",
    "more contrast": "higher contrast between elements for better visibility",
    "softer": "gentler, more subtle tones and transitions",
    "bolder": "stronger, more impactful visual presence",
    "cleaner": "more organized, less cluttered layout",
    "warmer": "warmer color tones with reds, oranges, and yellows",
    "cooler": "cooler color tones with blues, greens, and purples",
    "more modern": "more contemporary, trendy design elements",
    "more traditional": "more classic, timeless design approach"
]
```

### 12.4 Category Context Strings

```swift
let categoryContexts: [FlyerCategory: String] = [
    .event: "event promotional flyer with clear date/time placement and venue information",
    .salePromotion: "sale promotional flyer with urgency-driving design elements and prominent discount display",
    .grandOpening: "grand opening announcement with celebratory elements and location prominence",
    .restaurantFood: "food/restaurant flyer with appetizing appeal and clear contact information",
    .classWorkshop: "educational workshop flyer with informative layout and registration details",
    .partyCelebration: "party invitation flyer with festive celebratory atmosphere",
    .fitnessWellness: "fitness/wellness flyer with energetic healthy lifestyle imagery",
    .musicConcert: "music event flyer with dynamic artistic expression and performer prominence",
    .jobPosting: "job recruitment flyer with professional appeal and clear application instructions",
    .realEstate: "real estate listing flyer with property showcase and contact details",
    .nonprofitCharity: "nonprofit charity flyer with emotional appeal and donation call-to-action",
    .announcement: "general announcement flyer with clear message hierarchy"
]
```

---

**Document History:**
- v1.0 (Dec 6, 2024) - Initial PRD based on Python prototype analysis
