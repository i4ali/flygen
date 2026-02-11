import Foundation

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
    case serviceBusiness = "service_business"
    case beautySalon = "beauty_salon"
    case churchReligious = "church_religious"

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
        case .serviceBusiness: return "Service Business"
        case .beautySalon: return "Beauty & Salon"
        case .churchReligious: return "Church & Faith"
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
        case .serviceBusiness: return "wrench.and.screwdriver"
        case .beautySalon: return "scissors"
        case .churchReligious: return "building.columns"
        }
    }

    var emoji: String {
        switch self {
        case .event: return "🎪"
        case .salePromo: return "🏷️"
        case .announcement: return "📢"
        case .restaurantFood: return "🍽️"
        case .realEstate: return "🏠"
        case .jobPosting: return "💼"
        case .classWorkshop: return "📚"
        case .grandOpening: return "🎉"
        case .partyCelebration: return "🎈"
        case .fitnessWellness: return "💪"
        case .nonprofitCharity: return "❤️"
        case .musicConcert: return "🎵"
        case .serviceBusiness: return "🔧"
        case .beautySalon: return "💇"
        case .churchReligious: return "⛪"
        }
    }
}
