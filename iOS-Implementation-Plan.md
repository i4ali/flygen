# FlyGen iOS App - Implementation Plan

## Overview

Create a SwiftUI iOS app that generates professional flyers using AI via OpenRouter's Gemini Flash model. This is the MVP with core flow only (no auth, credits, or subscriptions).

**Scope:** 7-step creation flow → OpenRouter API → Save to Photos

---

## Project Structure

```
FlyGen/
├── FlyGen/
│   ├── App/
│   │   ├── FlyGenApp.swift
│   │   └── ContentView.swift
│   │
│   ├── Models/
│   │   ├── Enums/
│   │   │   ├── FlyerCategory.swift       # 12 categories
│   │   │   ├── VisualStyle.swift         # 10 styles
│   │   │   ├── Mood.swift                # 10 moods
│   │   │   ├── AspectRatio.swift         # 6 formats
│   │   │   ├── ColorSchemePreset.swift   # 8 presets
│   │   │   ├── BackgroundType.swift      # 5 types
│   │   │   ├── TextProminence.swift      # 3 levels
│   │   │   └── ImageryType.swift         # Text rendering modes
│   │   │
│   │   ├── TextContent.swift
│   │   ├── ColorSettings.swift
│   │   ├── VisualSettings.swift
│   │   ├── OutputSettings.swift
│   │   ├── FlyerProject.swift
│   │   └── CategoryConfiguration.swift
│   │
│   ├── Services/
│   │   ├── PromptBuilder/
│   │   │   ├── PromptBuilder.swift
│   │   │   ├── PromptDescriptors.swift
│   │   │   ├── NegativePrompts.swift
│   │   │   └── RefinementBuilder.swift
│   │   │
│   │   ├── ImageGeneration/
│   │   │   └── OpenRouterService.swift
│   │   │
│   │   └── PhotoLibraryService.swift
│   │
│   ├── ViewModels/
│   │   └── FlyerCreationViewModel.swift
│   │
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── Creation/
│   │   │   ├── CreationFlowView.swift
│   │   │   ├── CategoryStepView.swift
│   │   │   ├── TextContentStepView.swift
│   │   │   ├── VisualStyleStepView.swift
│   │   │   ├── MoodStepView.swift
│   │   │   ├── ColorsStepView.swift
│   │   │   ├── FormatStepView.swift
│   │   │   ├── ExtrasStepView.swift
│   │   │   └── ReviewStepView.swift
│   │   │
│   │   ├── Generation/
│   │   │   └── GenerationView.swift
│   │   │
│   │   ├── Result/
│   │   │   ├── ResultView.swift
│   │   │   └── RefinementSheet.swift
│   │   │
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   │
│   │   └── Components/
│   │       ├── SelectionCard.swift
│   │       ├── StepProgressBar.swift
│   │       └── DynamicTextField.swift
│   │
│   └── Extensions/
│       └── Color+Hex.swift
```

---

## Implementation Phases

### Phase 1: Project Setup & Models
1. Create new Xcode project (iOS 17+, SwiftUI)
2. Implement all enum types (port from models.py)
3. Implement data structures (TextContent, ColorSettings, etc.)
4. Create CategoryConfiguration with field mappings

### Phase 2: Prompt Builder Service
1. Port PromptDescriptors (all dictionaries from prompt_builder.py)
2. Port NegativePrompts
3. Implement PromptBuilder class with 14-section prompt construction
4. Implement spelling emphasis (`_spell_out` method)
5. Implement RefinementBuilder

### Phase 3: OpenRouter API Integration
1. Implement OpenRouterService with async/await
2. Handle chat completions API for Gemini Flash
3. Implement base64 image extraction from response
4. Handle aspect ratio mapping for Nano Banana
5. Add error handling

### Phase 4: Creation Flow Views
1. Build HomeView with create button
2. Build CreationFlowView container with navigation
3. Implement each step view (7 screens + review)
4. Create reusable components (SelectionCard, etc.)
5. Implement dynamic text fields based on category

### Phase 5: Generation & Result
1. Build GenerationView with loading states
2. Build ResultView with image display
3. Add save to Photos functionality
4. Implement refinement sheet

### Phase 6: Settings & Polish
1. Add API key settings screen
2. Error handling UI
3. Polish and test

---

## Data Models (Port from Python)

### Enums

#### FlyerCategory (12 options)
```swift
enum FlyerCategory: String, CaseIterable, Codable, Identifiable {
    case event = "event"
    case salePromo = "sale_promo"
    case announcement = "announcement"
    case restaurantFood = "restaurant_food"
    case realEstate = "real_estate"
    case jobPosting = "job_posting"
    case classWorkshop = "class_workshop"
    case grandOpening = "grand_opening"
    case partyCelebration = "party_celebration"
    case fitnessWellness = "fitness_wellness"
    case nonprofitCharity = "nonprofit_charity"
    case musicConcert = "music_concert"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .event: return "Event"
        case .salePromo: return "Sale / Promotion"
        case .announcement: return "Announcement"
        case .restaurantFood: return "Restaurant / Food"
        case .realEstate: return "Real Estate"
        case .jobPosting: return "Job Posting"
        case .classWorkshop: return "Class / Workshop"
        case .grandOpening: return "Grand Opening"
        case .partyCelebration: return "Party / Celebration"
        case .fitnessWellness: return "Fitness / Wellness"
        case .nonprofitCharity: return "Nonprofit / Charity"
        case .musicConcert: return "Music / Concert"
        }
    }

    var icon: String {
        switch self {
        case .event: return "calendar"
        case .salePromo: return "tag"
        case .announcement: return "megaphone"
        case .restaurantFood: return "fork.knife"
        case .realEstate: return "house"
        case .jobPosting: return "briefcase"
        case .classWorkshop: return "book"
        case .grandOpening: return "party.popper"
        case .partyCelebration: return "balloon.2"
        case .fitnessWellness: return "figure.run"
        case .nonprofitCharity: return "heart"
        case .musicConcert: return "music.note"
        }
    }
}
```

#### VisualStyle (10 options)
```swift
enum VisualStyle: String, CaseIterable, Codable, Identifiable {
    case modernMinimal = "modern_minimal"
    case boldVibrant = "bold_vibrant"
    case elegantLuxury = "elegant_luxury"
    case retroVintage = "retro_vintage"
    case playfulFun = "playful_fun"
    case corporateProfessional = "corporate_professional"
    case handDrawnOrganic = "hand_drawn_organic"
    case neonGlow = "neon_glow"
    case gradientModern = "gradient_modern"
    case watercolorArtistic = "watercolor_artistic"

    var id: String { rawValue }
    var displayName: String { rawValue.replacingOccurrences(of: "_", with: " ").capitalized }
}
```

#### Mood (10 options)
```swift
enum Mood: String, CaseIterable, Codable, Identifiable {
    case urgent, exciting, calm, elegant, friendly
    case professional, festive, serious, inspirational, romantic

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}
```

#### AspectRatio (6 options)
```swift
enum AspectRatio: String, CaseIterable, Codable, Identifiable {
    case square = "1:1"
    case portrait = "4:5"
    case story = "9:16"
    case landscape = "16:9"
    case letter = "letter"
    case a4 = "a4"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .square: return "Square (1:1) - Instagram"
        case .portrait: return "Portrait (4:5) - Instagram"
        case .story: return "Story (9:16) - Stories/Reels"
        case .landscape: return "Landscape (16:9) - Banner"
        case .letter: return "Letter (8.5x11) - Print"
        case .a4: return "A4 - International Print"
        }
    }

    /// Maps to Nano Banana supported ratios
    var nanoBananaRatio: String {
        switch self {
        case .square: return "1:1"
        case .portrait: return "3:4"
        case .story: return "9:16"
        case .landscape: return "16:9"
        case .letter: return "3:4"
        case .a4: return "3:4"
        }
    }
}
```

#### Other Enums
```swift
enum ColorSchemePreset: String, CaseIterable, Codable {
    case warm, cool, earthTones, neon, pastel, monochrome, blackGold, custom
}

enum BackgroundType: String, CaseIterable, Codable {
    case solid, gradient, textured, light, dark
}

enum TextProminence: String, CaseIterable, Codable {
    case dominant, balanced, subtle
}

enum ImageryType: String, CaseIterable, Codable {
    case illustrated, photoRealistic, abstractGeometric, pattern, minimalTextOnly, noText
}
```

### Data Structures

#### TextContent
```swift
struct TextContent: Codable, Equatable {
    var headline: String = ""
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
```

#### FlyerProject
```swift
struct FlyerProject: Codable, Identifiable, Equatable {
    let id: UUID
    var category: FlyerCategory
    var textContent: TextContent
    var colors: ColorSettings
    var visuals: VisualSettings
    var output: OutputSettings
    var targetAudience: String?
    var specialInstructions: String?
    var logoImageData: Data?
    let createdAt: Date
    var updatedAt: Date

    init(category: FlyerCategory) {
        self.id = UUID()
        self.category = category
        self.textContent = TextContent()
        self.colors = ColorSettings()
        self.visuals = VisualSettings()
        self.output = OutputSettings()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### CategoryConfiguration
```swift
struct CategoryConfiguration {
    static let textFields: [FlyerCategory: [TextFieldType]] = [
        .event: [.headline, .subheadline, .date, .time, .venueName, .address, .price, .ctaText, .website],
        .salePromo: [.headline, .subheadline, .date, .discountText, .address, .ctaText, .finePrint],
        .announcement: [.headline, .subheadline, .bodyText, .date, .ctaText],
        .restaurantFood: [.headline, .subheadline, .address, .phone, .website, .price],
        .realEstate: [.headline, .price, .address, .bodyText, .phone, .email, .website],
        .jobPosting: [.headline, .subheadline, .bodyText, .ctaText, .email, .website],
        .classWorkshop: [.headline, .subheadline, .date, .time, .venueName, .price, .ctaText],
        .grandOpening: [.headline, .subheadline, .date, .venueName, .address, .discountText, .ctaText],
        .partyCelebration: [.headline, .subheadline, .date, .time, .venueName, .address, .ctaText],
        .fitnessWellness: [.headline, .subheadline, .date, .time, .venueName, .price, .ctaText],
        .nonprofitCharity: [.headline, .subheadline, .date, .bodyText, .ctaText, .website],
        .musicConcert: [.headline, .subheadline, .date, .time, .venueName, .price, .ctaText]
    ]

    static let suggestedElements: [FlyerCategory: [String]] = [
        .event: ["decorative borders", "event-themed graphics"],
        .salePromo: ["sale tags", "burst shapes", "percentage badges", "shopping bags"],
        .restaurantFood: ["food imagery", "utensils", "plate arrangements"],
        .realEstate: ["property silhouette", "key motifs", "house icons"],
        .jobPosting: ["professional icons", "growth arrows", "team silhouettes"],
        .classWorkshop: ["learning icons", "notebook motifs", "lightbulb"],
        .grandOpening: ["ribbon cutting", "celebration confetti", "grand banner"],
        .partyCelebration: ["balloons", "confetti", "party decorations"],
        .fitnessWellness: ["fitness silhouettes", "wellness symbols", "nature elements"],
        .nonprofitCharity: ["helping hands", "heart motifs", "community symbols"],
        .musicConcert: ["musical notes", "instruments", "sound waves", "stage lights"]
    ]
}
```

---

## OpenRouter API Integration

### Endpoint
`https://openrouter.ai/api/v1/chat/completions`

### Model
`google/gemini-2.5-flash-image-preview` (a.k.a. "nano-banana")

### Request Format
```json
{
  "model": "google/gemini-2.5-flash-image-preview",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "image_url",
          "image_url": {"url": "data:image/png;base64,{logo_base64}"}
        },
        {
          "type": "text",
          "text": "{prompt}"
        }
      ]
    }
  ],
  "modalities": ["image", "text"],
  "image_config": {"aspect_ratio": "3:4"}
}
```

### Response Parsing
Image is in: `response.choices[0].message.images[0].image_url.url`

Format: `data:image/png;base64,{base64_data}`

### Aspect Ratio Mapping
| App Format | Nano Banana |
|------------|-------------|
| 1:1        | 1:1         |
| 4:5        | 3:4         |
| 9:16       | 9:16        |
| 16:9       | 16:9        |
| letter     | 3:4         |
| a4         | 3:4         |

### Swift Implementation
```swift
actor OpenRouterService {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    func generateImage(
        prompt: String,
        aspectRatio: AspectRatio,
        logoImageData: Data? = nil,
        apiKey: String
    ) async throws -> Data {
        var content: [[String: Any]] = []

        // Add logo if provided
        if let logoData = logoImageData {
            let base64Logo = logoData.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/png;base64,\(base64Logo)"]
            ])
        }

        content.append(["type": "text", "text": prompt])

        let requestBody: [String: Any] = [
            "model": "google/gemini-2.5-flash-image-preview",
            "messages": [["role": "user", "content": content]],
            "modalities": ["image", "text"],
            "image_config": ["aspect_ratio": aspectRatio.nanoBananaRatio]
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse response and extract base64 image
        // ...

        return imageData
    }
}
```

---

## Prompt Builder - 14 Sections

The prompt is constructed from 14 sections (ported from prompt_builder.py):

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

### Spelling Emphasis Method
```swift
func spellOut(_ text: String) -> String {
    text.map { String($0) }.joined(separator: " ")
    // "SALE" -> "S A L E"
}
```

---

## Source Files to Port

| Python File | Key Content | Lines |
|-------------|-------------|-------|
| models.py | All enums & data classes | 16-248 |
| prompt_builder.py | Descriptors & PromptBuilder | 15-622 |
| image_generator.py | OpenRouter API pattern | 59-66, 283-366 |

---

## User Flow

```
┌─────────────────┐
│   Home Screen   │ → Settings (API Key)
└────────┬────────┘
         │ "Create New Flyer"
         ▼
┌─────────────────┐
│ 1. Category     │ Select from 12 options
└────────┬────────┘
         ▼
┌─────────────────┐
│ 2. Text Content │ Dynamic fields per category
└────────┬────────┘
         ▼
┌─────────────────┐
│ 3. Visual Style │ Select from 10 styles
└────────┬────────┘
         ▼
┌─────────────────┐
│ 4. Mood         │ Select from 10 moods
└────────┬────────┘
         ▼
┌─────────────────┐
│ 5. Colors       │ Palette + background
└────────┬────────┘
         ▼
┌─────────────────┐
│ 6. Format       │ Aspect ratio + text mode
└────────┬────────┘
         ▼
┌─────────────────┐
│ 7. Extras       │ Include/avoid, audience, logo
└────────┬────────┘
         ▼
┌─────────────────┐
│   Review        │ Summary → Generate
└────────┬────────┘
         ▼
┌─────────────────┐
│   Generation    │ Loading state (10-30s)
└────────┬────────┘
         ▼
┌─────────────────┐
│   Result        │ View → Save/Refine/Reformat
└─────────────────┘
```

---

## API Key Storage

For MVP, store in UserDefaults:
```swift
@AppStorage("openrouter_api_key") var apiKey: String = ""
```

For production, migrate to Keychain.
