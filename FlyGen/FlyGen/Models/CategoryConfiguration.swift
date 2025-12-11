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
        .restaurantFood: [.headline, .subheadline, .venueName, .address, .phone, .website, .price, .ctaText],
        .realEstate: [.headline, .price, .address, .bodyText, .phone, .email, .website],
        .jobPosting: [.headline, .subheadline, .bodyText, .ctaText, .email, .website],
        .classWorkshop: [.headline, .subheadline, .scheduleEntries, .venueName, .price, .ctaText],
        .grandOpening: [.headline, .subheadline, .date, .venueName, .address, .discountText, .ctaText],
        .partyCelebration: [.headline, .subheadline, .date, .time, .venueName, .address, .ctaText, .phone],
        .fitnessWellness: [.headline, .subheadline, .date, .time, .venueName, .address, .price, .discountText, .ctaText, .phone],
        .nonprofitCharity: [.headline, .subheadline, .date, .bodyText, .ctaText, .website],
        .musicConcert: [.headline, .subheadline, .date, .time, .venueName, .address, .price, .ctaText, .website]
    ]

    /// Suggested visual elements to include by category
    static let suggestedElements: [FlyerCategory: [String]] = [
        .event: ["decorative borders", "event-themed graphics"],
        .salePromo: ["sale tags", "burst shapes", "percentage badges", "shopping bags"],
        .announcement: ["attention-grabbing icons", "announcement banners"],
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

    /// Get the text fields for a specific category
    static func fieldsFor(_ category: FlyerCategory) -> [TextFieldType] {
        textFields[category] ?? [.headline, .subheadline, .bodyText]
    }

    /// Get suggested elements for a category
    static func suggestionsFor(_ category: FlyerCategory) -> [String] {
        suggestedElements[category] ?? []
    }
}
