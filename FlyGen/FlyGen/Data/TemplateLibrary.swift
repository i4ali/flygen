import Foundation

/// Library of pre-defined flyer templates
struct TemplateLibrary {
    static let templates: [FlyerTemplate] = [
        // MARK: - Event Templates
        FlyerTemplate(
            id: "event_community",
            name: "Community Gathering",
            category: .event,
            textContent: TextContent(
                headline: "[Your Event Name]",
                subheadline: "Join us for an unforgettable experience",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Venue Name]",
                address: "[Address]",
                ctaText: "RSVP Now"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Perfect for community events, meetups, and local gatherings"
        ),

        FlyerTemplate(
            id: "event_corporate",
            name: "Corporate Conference",
            category: .event,
            textContent: TextContent(
                headline: "[Conference Title]",
                subheadline: "Industry Leaders • Expert Speakers • Networking",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Venue]",
                address: "[City, State]",
                ctaText: "Register Today",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .dark),
            visuals: VisualSettings(style: .corporateProfessional, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional design for business conferences and seminars"
        ),

        // MARK: - Sale Templates
        FlyerTemplate(
            id: "sale_flash",
            name: "Flash Sale",
            category: .salePromo,
            textContent: TextContent(
                headline: "[XX]% OFF",
                subheadline: "Limited Time Only!",
                bodyText: "Don't miss our biggest sale of the season",
                date: "Ends [Date]",
                ctaText: "Shop Now",
                finePrint: "While supplies last. Some exclusions apply."
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(style: .boldVibrant, mood: .urgent),
            output: OutputSettings(aspectRatio: .square),
            previewDescription: "Eye-catching design for flash sales and limited offers"
        ),

        FlyerTemplate(
            id: "sale_seasonal",
            name: "Seasonal Promotion",
            category: .salePromo,
            textContent: TextContent(
                headline: "[Season] Sale",
                subheadline: "Refresh your style",
                date: "[Start Date] - [End Date]",
                discountText: "Up to [XX]% Off",
                ctaText: "Discover Deals",
                website: "[yourstore.com]"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .elegant),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Elegant design for seasonal promotions and collections"
        ),

        // MARK: - Restaurant Template
        FlyerTemplate(
            id: "restaurant_special",
            name: "Daily Special",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "Today's Special: [Dish Name]",
                subheadline: "[Brief Description]",
                bodyText: "Fresh ingredients • Made with love",
                venueName: "[Restaurant Name]",
                price: "$[XX]",
                ctaText: "Order Now",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .earthTones, backgroundType: .dark),
            visuals: VisualSettings(style: .modernMinimal, mood: .friendly, imageryType: .photoRealistic),
            output: OutputSettings(aspectRatio: .square),
            previewDescription: "Appetizing design for daily specials and menu highlights"
        ),

        // MARK: - Party Template
        FlyerTemplate(
            id: "party_birthday",
            name: "Birthday Celebration",
            category: .partyCelebration,
            textContent: TextContent(
                headline: "[Name]'s Birthday!",
                subheadline: "You're Invited to Celebrate",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Location]",
                address: "[Address]",
                ctaText: "RSVP",
                phone: "[Contact Number]"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .playfulFun, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Fun and colorful design for birthday parties"
        ),

        // MARK: - Fitness Template
        FlyerTemplate(
            id: "fitness_gym",
            name: "Gym Promotion",
            category: .fitnessWellness,
            textContent: TextContent(
                headline: "Join [Gym Name]",
                subheadline: "Transform Your Body, Transform Your Life",
                bodyText: "State-of-the-art equipment • Expert trainers • Group classes",
                address: "[Address]",
                discountText: "[XX]% Off First Month",
                ctaText: "Start Today",
                phone: "[Phone]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .dark),
            visuals: VisualSettings(style: .boldVibrant, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Energetic design for gym promotions and fitness classes"
        ),

        // MARK: - Music Template
        FlyerTemplate(
            id: "music_concert",
            name: "Concert Announcement",
            category: .musicConcert,
            textContent: TextContent(
                headline: "[Artist Name] Live",
                subheadline: "[Tour Name / Album Title]",
                date: "[Date]",
                time: "Doors: [Time]",
                venueName: "[Venue Name]",
                address: "[City]",
                price: "Tickets from $[XX]",
                ctaText: "Get Tickets",
                website: "[ticketsite.com]"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .neonGlow, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Bold design for concerts, shows, and live performances"
        )
    ]

    /// Get templates filtered by category
    static func templates(for category: FlyerCategory) -> [FlyerTemplate] {
        templates.filter { $0.category == category }
    }

    /// Get all unique categories that have templates
    static var availableCategories: [FlyerCategory] {
        Array(Set(templates.map { $0.category })).sorted { $0.displayName < $1.displayName }
    }
}
