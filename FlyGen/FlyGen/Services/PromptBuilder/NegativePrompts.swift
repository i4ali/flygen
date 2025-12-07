import Foundation

/// Negative prompts to avoid common AI generation issues
struct NegativePrompts {

    /// Universal negative prompts that apply to all flyers
    static let universal: [String] = [
        "blurry or fuzzy text",
        "misspelled words",
        "illegible unreadable text",
        "cut-off cropped text",
        "overlapping colliding elements",
        "cluttered busy composition",
        "low resolution pixelated",
        "watermarks",
        "amateur unprofessional design",
        "cheap clipart",
        "cheesy dated effects",
        "excessive drop shadows",
        "word art",
        "stretched distorted images",
        "poor contrast",
        "random floating elements",
        "inconsistent style mixing",
        "too many fonts",
        "unbalanced layout"
    ]

    /// Category-specific negative prompts
    static let categorySpecific: [FlyerCategory: [String]] = [
        .event: ["boring static composition", "unclear date and time"],
        .salePromo: ["subtle hidden pricing", "calm muted urgency", "buried discount"],
        .announcement: ["confusing layout", "buried message"],
        .restaurantFood: ["unappetizing imagery", "cold sterile colors"],
        .realEstate: ["cluttered property view", "unprofessional layout"],
        .jobPosting: ["too casual", "unclear position"],
        .classWorkshop: ["intimidating imagery", "overly complex confusing"],
        .grandOpening: ["subdued underwhelming", "no celebration feeling"],
        .partyCelebration: ["boring serious tone", "corporate stiffness"],
        .fitnessWellness: ["intimidating extreme imagery", "unhealthy appearance"],
        .nonprofitCharity: ["exploitative imagery", "guilt-inducing"],
        .musicConcert: ["static boring composition", "silent feeling"]
    ]

    /// Get combined negative prompts for a category
    static func forCategory(_ category: FlyerCategory) -> [String] {
        var negatives = universal
        if let categoryNegatives = categorySpecific[category] {
            negatives.append(contentsOf: categoryNegatives)
        }
        return negatives
    }
}
