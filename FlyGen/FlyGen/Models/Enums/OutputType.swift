import Foundation

/// User-friendly output types that map to underlying FlyerCategory
/// This provides intuitive names like "Party Invitation" instead of "Party/Celebration"
enum OutputType: String, CaseIterable, Identifiable {
    // Party & Celebrations
    case partyInvitation = "party_invitation"
    case holidayParty = "holiday_party"

    // Events & Invitations
    case eventFlyer = "event_flyer"
    case weddingInvitation = "wedding_invitation"
    case corporateInvitation = "corporate_invitation"
    case concertPoster = "concert_poster"

    // Business & Professional
    case newsletter = "newsletter"
    case jobRecruitmentFlyer = "job_recruitment"
    case grandOpeningFlyer = "grand_opening"
    case propertyListing = "property_listing"

    // Sales & Promotions
    case saleFlyer = "sale_flyer"
    case fitnessPromotion = "fitness_promotion"

    // Food & Dining
    case menuFoodSpecial = "menu_food_special"

    // Classes & Education
    case classWorkshopFlyer = "class_workshop"

    // Personal & Greeting
    case greetingCard = "greeting_card"
    case farewellCard = "farewell_card"

    // Nonprofit
    case fundraiserFlyer = "fundraiser"

    // Service Business
    case serviceFlyer = "service_flyer"

    // Beauty & Salon
    case salonBeautyFlyer = "salon_beauty"

    // Church & Faith
    case churchFaithFlyer = "church_faith"

    var id: String { rawValue }

    /// The underlying FlyerCategory this output type maps to
    var category: FlyerCategory {
        switch self {
        case .partyInvitation, .holidayParty:
            return .partyCelebration
        case .eventFlyer, .weddingInvitation, .corporateInvitation:
            return .event
        case .concertPoster:
            return .musicConcert
        case .newsletter, .greetingCard, .farewellCard:
            return .announcement
        case .jobRecruitmentFlyer:
            return .jobPosting
        case .grandOpeningFlyer:
            return .grandOpening
        case .propertyListing:
            return .realEstate
        case .saleFlyer:
            return .salePromo
        case .fitnessPromotion:
            return .fitnessWellness
        case .menuFoodSpecial:
            return .restaurantFood
        case .classWorkshopFlyer:
            return .classWorkshop
        case .fundraiserFlyer:
            return .nonprofitCharity
        case .serviceFlyer:
            return .serviceBusiness
        case .salonBeautyFlyer:
            return .beautySalon
        case .churchFaithFlyer:
            return .churchReligious
        }
    }

    /// User-friendly display name shown in selection UI
    var displayName: String {
        switch self {
        case .partyInvitation: return "Party Invitation"
        case .holidayParty: return "Holiday Party"
        case .eventFlyer: return "Event Flyer"
        case .weddingInvitation: return "Wedding Invitation"
        case .corporateInvitation: return "Corporate Invitation"
        case .concertPoster: return "Concert Poster"
        case .newsletter: return "Newsletter"
        case .greetingCard: return "Greeting Card"
        case .farewellCard: return "Farewell Card"
        case .jobRecruitmentFlyer: return "Job Posting"
        case .grandOpeningFlyer: return "Grand Opening"
        case .propertyListing: return "Property Listing"
        case .saleFlyer: return "Sale / Promo"
        case .fitnessPromotion: return "Fitness Promo"
        case .menuFoodSpecial: return "Menu / Food Special"
        case .classWorkshopFlyer: return "Class / Workshop"
        case .fundraiserFlyer: return "Fundraiser"
        case .serviceFlyer: return "Service Flyer"
        case .salonBeautyFlyer: return "Salon / Beauty Flyer"
        case .churchFaithFlyer: return "Church / Faith Flyer"
        }
    }

    /// SF Symbol icon for the output type
    var icon: String {
        switch self {
        case .partyInvitation: return "balloon.2"
        case .holidayParty: return "gift"
        case .eventFlyer: return "calendar"
        case .weddingInvitation: return "heart.circle"
        case .corporateInvitation: return "building.2"
        case .concertPoster: return "music.note"
        case .newsletter: return "newspaper"
        case .greetingCard: return "envelope.open.badge.clock"
        case .farewellCard: return "hand.wave"
        case .jobRecruitmentFlyer: return "briefcase"
        case .grandOpeningFlyer: return "party.popper"
        case .propertyListing: return "house"
        case .saleFlyer: return "tag"
        case .fitnessPromotion: return "figure.run"
        case .menuFoodSpecial: return "fork.knife"
        case .classWorkshopFlyer: return "book"
        case .fundraiserFlyer: return "heart"
        case .serviceFlyer: return "wrench.and.screwdriver"
        case .salonBeautyFlyer: return "scissors"
        case .churchFaithFlyer: return "building.columns"
        }
    }

    /// Emoji for visual display in selection cards
    var emoji: String {
        switch self {
        case .partyInvitation: return "🎈"
        case .holidayParty: return "🎄"
        case .eventFlyer: return "🎪"
        case .weddingInvitation: return "💒"
        case .corporateInvitation: return "🏢"
        case .concertPoster: return "🎵"
        case .newsletter: return "📰"
        case .greetingCard: return "💌"
        case .farewellCard: return "👋"
        case .jobRecruitmentFlyer: return "💼"
        case .grandOpeningFlyer: return "🎉"
        case .propertyListing: return "🏠"
        case .saleFlyer: return "🏷️"
        case .fitnessPromotion: return "💪"
        case .menuFoodSpecial: return "🍽️"
        case .classWorkshopFlyer: return "📚"
        case .fundraiserFlyer: return "❤️"
        case .serviceFlyer: return "🔧"
        case .salonBeautyFlyer: return "💇"
        case .churchFaithFlyer: return "⛪"
        }
    }

    /// Brief description for selection UI tooltips
    var description: String {
        switch self {
        case .partyInvitation: return "Birthday, anniversary, or casual party invites"
        case .holidayParty: return "Christmas, Halloween, or seasonal celebrations"
        case .eventFlyer: return "Community events, meetups, and gatherings"
        case .weddingInvitation: return "Elegant wedding and engagement invitations"
        case .corporateInvitation: return "Business events, conferences, and networking"
        case .concertPoster: return "Music shows, DJ nights, and performances"
        case .newsletter: return "Updates, announcements, and monthly digests"
        case .greetingCard: return "Birthday wishes, thank you, and congratulations"
        case .farewellCard: return "Retirement, goodbye, and best wishes"
        case .jobRecruitmentFlyer: return "Hiring announcements and career opportunities"
        case .grandOpeningFlyer: return "Store openings and launch celebrations"
        case .propertyListing: return "Real estate listings and property showcases"
        case .saleFlyer: return "Discounts, promotions, and special offers"
        case .fitnessPromotion: return "Gym deals, wellness programs, and classes"
        case .menuFoodSpecial: return "Restaurant menus, daily specials, and food promos"
        case .classWorkshopFlyer: return "Courses, tutorials, and educational sessions"
        case .fundraiserFlyer: return "Charity events, donations, and community causes"
        case .serviceFlyer: return "Cleaning, repair, landscaping, and professional services"
        case .salonBeautyFlyer: return "Hair salon, barber, spa, and beauty service promotions"
        case .churchFaithFlyer: return "Worship services, faith events, and religious gatherings"
        }
    }

    /// The intent/purpose this output type belongs to
    var intent: Intent {
        switch self {
        case .partyInvitation, .holidayParty, .grandOpeningFlyer:
            return .celebrate
        case .eventFlyer, .weddingInvitation, .corporateInvitation, .concertPoster:
            return .invite
        case .saleFlyer, .fitnessPromotion, .menuFoodSpecial, .propertyListing, .jobRecruitmentFlyer, .serviceFlyer, .salonBeautyFlyer:
            return .promote
        case .newsletter, .greetingCard, .farewellCard:
            return .inform
        case .classWorkshopFlyer, .fundraiserFlyer, .churchFaithFlyer:
            return .community
        }
    }
}
