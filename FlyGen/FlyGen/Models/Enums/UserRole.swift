import Foundation

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case soloCreator = "solo_creator"
    case smallBusiness = "small_business"
    case marketingPro = "marketing_pro"
    case communityOrganizer = "community_organizer"
    case eventPlanner = "event_planner"
    case exploring = "exploring"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soloCreator: return "Solo Creator"
        case .smallBusiness: return "Small Business Owner"
        case .marketingPro: return "Marketing Professional"
        case .communityOrganizer: return "Community Organizer"
        case .eventPlanner: return "Event Planner"
        case .exploring: return "Just Exploring"
        }
    }

    var icon: String {
        switch self {
        case .soloCreator: return "person.crop.circle"
        case .smallBusiness: return "storefront"
        case .marketingPro: return "chart.line.uptrend.xyaxis"
        case .communityOrganizer: return "person.3"
        case .eventPlanner: return "calendar.badge.clock"
        case .exploring: return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .soloCreator: return "Personal projects & side hustles"
        case .smallBusiness: return "Promote your business"
        case .marketingPro: return "Campaigns & content creation"
        case .communityOrganizer: return "Non-profits & local groups"
        case .eventPlanner: return "Events & celebrations"
        case .exploring: return "See what FlyGen can do"
        }
    }

    /// Categories to pre-select based on role
    var recommendedCategories: [FlyerCategory] {
        switch self {
        case .soloCreator:
            return [.announcement, .event]
        case .smallBusiness:
            return [.salePromo, .grandOpening, .announcement]
        case .marketingPro:
            return [.salePromo, .event, .announcement]
        case .communityOrganizer:
            return [.nonprofitCharity, .event, .announcement]
        case .eventPlanner:
            return [.event, .partyCelebration, .musicConcert]
        case .exploring:
            return []
        }
    }
}
