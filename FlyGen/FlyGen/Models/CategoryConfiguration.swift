import Foundation

/// Defines which text fields are shown for each category
enum TextFieldType: String, CaseIterable, Identifiable {
    case headline
    case subheadline
    case bodyText
    case date
    case time
    case venueName
    case address
    case price
    case discountText
    case ctaText
    case phone
    case email
    case website
    case socialHandle
    case finePrint
    case scheduleEntries

    var id: String { rawValue }

    var label: String {
        switch self {
        case .headline: return "Main Headline"
        case .subheadline: return "Subheadline"
        case .bodyText: return "Body Text"
        case .date: return "Date"
        case .time: return "Time"
        case .venueName: return "Venue Name"
        case .address: return "Address"
        case .price: return "Price"
        case .discountText: return "Discount / Offer"
        case .ctaText: return "Call to Action"
        case .phone: return "Phone"
        case .email: return "Email"
        case .website: return "Website"
        case .socialHandle: return "Social Handle"
        case .finePrint: return "Fine Print"
        case .scheduleEntries: return "Schedule"
        }
    }

    var placeholder: String {
        switch self {
        case .headline: return "e.g., SUMMER SALE"
        case .subheadline: return "e.g., Don't Miss Out!"
        case .bodyText: return "Additional details..."
        case .date: return "e.g., December 15, 2024"
        case .time: return "e.g., 7:00 PM"
        case .venueName: return "e.g., Grand Ballroom"
        case .address: return "e.g., 123 Main Street"
        case .price: return "e.g., $25"
        case .discountText: return "e.g., UP TO 50% OFF"
        case .ctaText: return "e.g., Shop Now!"
        case .phone: return "e.g., (555) 123-4567"
        case .email: return "e.g., info@example.com"
        case .website: return "e.g., www.example.com"
        case .socialHandle: return "e.g., @username"
        case .finePrint: return "e.g., Terms and conditions apply"
        case .scheduleEntries: return "Add dates and activities"
        }
    }

    var isRequired: Bool {
        self == .headline
    }

    var isMultiline: Bool {
        self == .bodyText || self == .finePrint
    }

    /// Returns true if this field requires a custom component instead of a standard text field
    var isCustomComponent: Bool {
        self == .scheduleEntries
    }

    var keyboardType: KeyboardType {
        switch self {
        case .phone: return .phone
        case .email: return .email
        case .website: return .url
        default: return .default
        }
    }

    enum KeyboardType {
        case `default`, phone, email, url
    }
}

struct CategoryConfiguration {
    /// Which text fields are relevant for each category
    static let textFields: [FlyerCategory: [TextFieldType]] = [
        .event: [.headline, .subheadline, .scheduleEntries, .venueName, .address, .ctaText, .website],
        .salePromo: [.headline, .subheadline, .discountText, .date, .address, .ctaText, .finePrint, .website],
        .announcement: [.headline, .subheadline, .bodyText, .date, .ctaText],
        .restaurantFood: [.headline, .subheadline, .bodyText, .venueName, .address, .phone, .website, .price, .ctaText],
        .realEstate: [.headline, .price, .address, .bodyText, .phone, .email, .website],
        .jobPosting: [.headline, .subheadline, .bodyText, .ctaText, .email, .website],
        .classWorkshop: [.headline, .subheadline, .scheduleEntries, .venueName, .price, .ctaText],
        .grandOpening: [.headline, .subheadline, .bodyText, .date, .time, .venueName, .address, .discountText, .ctaText, .phone, .website],
        .partyCelebration: [.headline, .subheadline, .date, .time, .venueName, .address, .ctaText, .phone],
        .fitnessWellness: [.headline, .subheadline, .date, .time, .venueName, .address, .price, .discountText, .ctaText, .phone],
        .nonprofitCharity: [.headline, .subheadline, .bodyText, .date, .time, .venueName, .address, .ctaText, .phone, .email, .website],
        .musicConcert: [.headline, .subheadline, .date, .time, .venueName, .address, .price, .ctaText, .website]
    ]

    /// Suggested visual elements to include by category
    static let suggestedElements: [FlyerCategory: [String]] = [
        .event: ["decorative borders", "event-themed graphics", "elegant frames", "spotlight effects", "abstract shapes", "geometric patterns", "venue silhouette", "calendar icon"],
        .salePromo: ["sale tags", "burst shapes", "percentage badges", "shopping bags", "price tags", "ribbon banners", "star bursts", "discount badges", "sparkles", "gift boxes"],
        .announcement: ["attention-grabbing icons", "announcement banners", "megaphone", "spotlight", "decorative borders", "info icons", "bullet points", "dividers"],
        .restaurantFood: ["food imagery", "utensils", "plate arrangements", "fresh ingredients", "steam effects", "chef hat", "spices", "herbs", "wooden textures", "table setting"],
        .realEstate: ["property silhouette", "key motifs", "house icons", "floor plan outlines", "location pins", "sold badge", "premium badge", "architectural elements"],
        .jobPosting: ["professional icons", "growth arrows", "team silhouettes", "briefcase", "handshake", "career ladder", "checkmarks", "building silhouette"],
        .classWorkshop: ["learning icons", "notebook motifs", "lightbulb", "graduation cap", "pencils", "books", "brain icon", "certificate", "workshop tools"],
        .grandOpening: ["ribbon cutting", "celebration confetti", "grand banner", "champagne glasses", "balloons", "spotlight", "red carpet", "grand opening badge", "fireworks"],
        .partyCelebration: ["balloons", "confetti", "party decorations", "streamers", "party hats", "gift boxes", "cake", "sparklers", "bunting", "disco ball"],
        .fitnessWellness: ["fitness silhouettes", "wellness symbols", "nature elements", "dumbbells", "yoga poses", "heart rate", "water droplets", "leaves", "energy rays"],
        .nonprofitCharity: ["helping hands", "heart motifs", "community symbols", "globe", "ribbon", "donation box", "unity circle", "caring hands", "hope symbols"],
        .musicConcert: ["musical notes", "instruments", "sound waves", "stage lights", "vinyl records", "microphone", "equalizer bars", "guitar silhouette", "concert crowd silhouette"]
    ]

    /// Suggested visual elements to avoid by category
    static let suggestedAvoidElements: [FlyerCategory: [String]] = [
        .event: ["people", "faces", "hands", "cluttered backgrounds", "low quality images", "copyrighted logos"],
        .salePromo: ["people", "faces", "hands", "competitor logos", "cluttered layouts", "small text", "too many colors"],
        .announcement: ["people", "faces", "hands", "distracting backgrounds", "irrelevant imagery", "busy patterns"],
        .restaurantFood: ["people", "faces", "hands", "raw meat", "unappetizing colors", "dirty dishes", "insects"],
        .realEstate: ["people", "faces", "hands", "personal belongings", "clutter", "dated decor", "unflattering angles"],
        .jobPosting: ["people", "faces", "hands", "casual imagery", "unprofessional elements", "cluttered layouts"],
        .classWorkshop: ["people", "faces", "hands", "distracting elements", "childish imagery for adult classes", "outdated technology"],
        .grandOpening: ["people", "faces", "hands", "closed signs", "construction imagery", "empty spaces"],
        .partyCelebration: ["people", "faces", "hands", "sad imagery", "dark colors", "corporate elements"],
        .fitnessWellness: ["people", "faces", "hands", "before/after imagery", "unhealthy food", "injury imagery", "extreme body images"],
        .nonprofitCharity: ["people", "faces", "hands", "graphic imagery", "political symbols", "controversial content"],
        .musicConcert: ["people", "faces", "hands", "modern tech for retro themes", "silent imagery", "office settings"]
    ]

    /// Common elements to avoid (used as fallback)
    static let commonAvoidElements: [String] = [
        "people", "faces", "hands", "text", "watermarks", "logos", "blurry images", "low quality", "copyrighted content"
    ]

    /// Expert-level special instruction suggestions by category
    /// These are specific, actionable visual/compositional techniques
    static let suggestedSpecialInstructions: [FlyerCategory: [String]] = [
        .event: [
            "Venue silhouette integrated into background",
            "Spotlight effect on key event details",
            "Decorative frame matching event theme",
            "Event props silhouetted in corners",
            "Invitation-style elegant border"
        ],
        .salePromo: [
            "Starburst explosion behind discount number",
            "Products arranged in grid showcase",
            "Price slash effect on original price",
            "Shopping bags as corner accents",
            "Urgency countdown timer visual"
        ],
        .announcement: [
            "Spotlight beam on headline",
            "Breaking news banner across top",
            "Official stamp or seal effect",
            "Arrows pointing to key info",
            "Megaphone radiating message"
        ],
        .restaurantFood: [
            "Arrange food photos as border around the frame",
            "Show steam rising from hot dishes",
            "Overhead flat-lay food photography style",
            "Fresh ingredients scattered in corners",
            "Close-up texture of signature dish as background"
        ],
        .realEstate: [
            "Property photo as full-bleed background",
            "Floor plan as subtle watermark",
            "Window frame composition with view",
            "Architectural details as border pattern",
            "Key amenity icons in corners"
        ],
        .jobPosting: [
            "Company workspace as subtle background",
            "Career ladder or growth stairs visual",
            "Team collaboration silhouettes",
            "Industry tools framing text",
            "Professional environment glimpse"
        ],
        .classWorkshop: [
            "Hands-on demonstration as focal point",
            "Tools of the craft as border",
            "Step-by-step progression visual",
            "Chalkboard texture background",
            "Student work samples in corners"
        ],
        .grandOpening: [
            "Ribbon cutting ceremony as focus",
            "Storefront as full-bleed hero",
            "Champagne splash celebration",
            "Grand doorway perspective",
            "Balloons releasing upward"
        ],
        .partyCelebration: [
            "Balloon arch framing the text",
            "Confetti explosion from center",
            "Streamers flowing from corners",
            "Party lights bokeh background",
            "Age number made of balloons"
        ],
        .fitnessWellness: [
            "Motion blur suggesting movement",
            "Before/after split composition",
            "Equipment silhouettes as border",
            "Energy burst radiating outward",
            "Sweat droplets for intensity"
        ],
        .nonprofitCharity: [
            "Hands reaching together as symbol",
            "Impact numbers as large callouts",
            "Community gathering aerial view",
            "Helping hands forming heart",
            "Before/after transformation"
        ],
        .musicConcert: [
            "Sound wave as decorative border",
            "Stage lighting beams from center",
            "Instrument silhouettes in corners",
            "Crowd silhouette at bottom",
            "Vinyl record motif as accent"
        ]
    ]

    /// Get the text fields for a specific category
    static func fieldsFor(_ category: FlyerCategory) -> [TextFieldType] {
        textFields[category] ?? [.headline, .subheadline, .bodyText]
    }

    /// Get suggested elements for a category
    static func suggestionsFor(_ category: FlyerCategory) -> [String] {
        suggestedElements[category] ?? []
    }

    /// Get suggested elements to avoid for a category
    static func avoidSuggestionsFor(_ category: FlyerCategory) -> [String] {
        suggestedAvoidElements[category] ?? commonAvoidElements
    }

    /// Get special instruction suggestions for a category
    static func specialInstructionSuggestionsFor(_ category: FlyerCategory) -> [String] {
        suggestedSpecialInstructions[category] ?? []
    }
}
