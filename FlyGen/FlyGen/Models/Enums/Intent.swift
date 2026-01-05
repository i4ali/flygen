import Foundation

/// User intent/purpose for creating a flyer
/// Groups OutputTypes into logical categories based on what the user wants to achieve
enum Intent: String, CaseIterable, Identifiable {
    case celebrate = "celebrate"
    case invite = "invite"
    case promote = "promote"
    case inform = "inform"
    case community = "community"

    var id: String { rawValue }

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .celebrate: return "Celebrate"
        case .invite: return "Invite"
        case .promote: return "Promote"
        case .inform: return "Inform"
        case .community: return "Connect"
        }
    }

    /// Subtitle describing the intent
    var subtitle: String {
        switch self {
        case .celebrate: return "Parties & special occasions"
        case .invite: return "Events & gatherings"
        case .promote: return "Sales & business"
        case .inform: return "Updates & greetings"
        case .community: return "Classes & causes"
        }
    }

    /// Emoji for visual display
    var emoji: String {
        switch self {
        case .celebrate: return "🎉"
        case .invite: return "📬"
        case .promote: return "📢"
        case .inform: return "📰"
        case .community: return "🤝"
        }
    }

    /// SF Symbol icon
    var icon: String {
        switch self {
        case .celebrate: return "party.popper"
        case .invite: return "envelope.open"
        case .promote: return "megaphone"
        case .inform: return "newspaper"
        case .community: return "person.3"
        }
    }

    /// All output types that belong to this intent
    var outputTypes: [OutputType] {
        switch self {
        case .celebrate:
            return [.partyInvitation, .holidayParty, .grandOpeningFlyer]
        case .invite:
            return [.eventFlyer, .weddingInvitation, .corporateInvitation, .concertPoster]
        case .promote:
            return [.saleFlyer, .fitnessPromotion, .menuFoodSpecial, .propertyListing, .jobRecruitmentFlyer]
        case .inform:
            return [.newsletter, .greetingCard, .farewellCard]
        case .community:
            return [.classWorkshopFlyer, .fundraiserFlyer]
        }
    }
}
