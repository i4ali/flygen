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

        FlyerTemplate(
            id: "event_multidate",
            name: "Multi-Date Event Schedule",
            category: .event,
            textContent: TextContent(
                headline: "[Event Series Name]",
                subheadline: "Multiple Sessions • Various Activities",
                venueName: "[Venue Name]",
                address: "[Address]",
                ctaText: "Register Now",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .playfulFun, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Perfect for workshop series, camps, festivals, and events spanning multiple dates"
        ),

        FlyerTemplate(
            id: "event_wedding_invitation",
            name: "Wedding Invitation",
            category: .event,
            textContent: TextContent(
                headline: "[Name] & [Name]",
                subheadline: "Request the pleasure of your company",
                venueName: "[Venue Name]",
                address: "[Address]",
                ctaText: "RSVP by [Date]",
                website: "[wedding-website.com]"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .romantic),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Elegant design for wedding invitations and engagement announcements"
        ),

        FlyerTemplate(
            id: "event_corporate_invitation",
            name: "Corporate Invitation",
            category: .event,
            textContent: TextContent(
                headline: "[Event Name]",
                subheadline: "[Company Name] invites you",
                venueName: "[Venue]",
                address: "[Address]",
                ctaText: "Register Now",
                website: "[registration-link.com]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .dark),
            visuals: VisualSettings(style: .corporateProfessional, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional invitation for corporate events, galas, and business gatherings"
        ),

        // MARK: - Announcement Templates
        FlyerTemplate(
            id: "announcement_newsletter",
            name: "Educational Newsletter",
            category: .announcement,
            textContent: TextContent(
                headline: "[Newsletter Title]",
                subheadline: "By [Author Name], [Title/Credentials]",
                bodyText: "[Section 1 Title]\n[Content with bullet points...]\n\n[Section 2 Title]\n[More content...]\n\n[Section 3 Title]\n[Additional content...]",
                ctaText: "Learn More"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .watercolorArtistic, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Perfect for health tips, educational content, newsletters, and informational flyers"
        ),

        FlyerTemplate(
            id: "announcement_business_newsletter",
            name: "Business Newsletter",
            category: .announcement,
            textContent: TextContent(
                headline: "[Company] Monthly Update",
                subheadline: "[Month Year] Edition",
                bodyText: "In This Issue:\n• [Headline 1]\n• [Headline 2]\n• [Headline 3]\n\n[Main article content goes here...]",
                ctaText: "Read More"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .corporateProfessional, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional design for company updates, monthly newsletters, and business communications"
        ),

        FlyerTemplate(
            id: "announcement_greeting_card",
            name: "Greeting Card",
            category: .announcement,
            textContent: TextContent(
                headline: "[Your Greeting Message]",
                subheadline: "With Love & Best Wishes",
                bodyText: "[Your personal message here...]\n\nThinking of you and wishing you all the best.",
                ctaText: "[Your Name]"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .watercolorArtistic, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Warm design for birthday wishes, thank you cards, and congratulations"
        ),

        FlyerTemplate(
            id: "announcement_farewell_card",
            name: "Farewell Card",
            category: .announcement,
            textContent: TextContent(
                headline: "Happy Retirement!",
                subheadline: "Congratulations [Name]",
                bodyText: "[Years] years of dedication and excellence.\n\nThank you for your service, leadership, and friendship.\n\nWishing you the best in your next chapter!",
                ctaText: "Best Wishes"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .handDrawnOrganic, mood: .inspirational),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Heartfelt design for retirement, farewell, and goodbye messages"
        ),

        // MARK: - Sale Templates
        FlyerTemplate(
            id: "sale_flash",
            name: "Flash Sale",
            category: .salePromo,
            textContent: TextContent(
                headline: "[XX]% OFF",
                subheadline: "Limited Time Only!",
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

        // MARK: - Restaurant Templates
        FlyerTemplate(
            id: "restaurant_special",
            name: "Daily Special",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "Today's Special: [Dish Name]",
                subheadline: "[Brief Description]",
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

        FlyerTemplate(
            id: "restaurant_menu_highlights",
            name: "Menu Highlights",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "Our Menu",
                subheadline: "[Restaurant Name]",
                bodyText: "[Dish 1] - $[XX]\n[Dish 2] - $[XX]\n[Dish 3] - $[XX]",
                venueName: "[Restaurant Name]",
                address: "[Address]",
                phone: "[Phone Number]",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .earthTones, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .elegant, imageryType: .photoRealistic),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Elegant menu design showcasing your restaurant's offerings"
        ),

        // MARK: - Party Templates
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

        FlyerTemplate(
            id: "party_invitation_general",
            name: "Party Invitation",
            category: .partyCelebration,
            textContent: TextContent(
                headline: "You're Invited!",
                subheadline: "[Event Type] Party",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Host Name]'s Place",
                address: "[Address]",
                ctaText: "RSVP",
                phone: "[Contact]"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .playfulFun, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Versatile invitation design for any party or celebration"
        ),

        FlyerTemplate(
            id: "party_holiday_celebration",
            name: "Holiday Party",
            category: .partyCelebration,
            textContent: TextContent(
                headline: "[Holiday] Celebration!",
                subheadline: "Join us for a festive gathering",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Location]",
                address: "[Address]",
                ctaText: "RSVP",
                phone: "[Contact]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(style: .playfulFun, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Festive design for Christmas, New Year, Halloween, and seasonal celebrations"
        ),

        // MARK: - Fitness Template
        FlyerTemplate(
            id: "fitness_gym",
            name: "Gym Promotion",
            category: .fitnessWellness,
            textContent: TextContent(
                headline: "Join [Gym Name]",
                subheadline: "Transform Your Body, Transform Your Life",
                venueName: "[Gym Name]",
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
        ),

        // MARK: - Real Estate Templates
        FlyerTemplate(
            id: "realestate_financial_services",
            name: "Financial Services Promotion",
            category: .realEstate,
            textContent: TextContent(
                headline: "[Service Name] Now Available",
                bodyText: "Calculate how much you could get:\n• $50,000\n• $75,000\n• $100,000\n• $200,000",
                website: "[yourcompany.com]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Clean design for mortgage, loans, and financial services promotions"
        ),

        FlyerTemplate(
            id: "realestate_property_listing",
            name: "Property Listing",
            category: .realEstate,
            textContent: TextContent(
                headline: "[Property Type] For Sale",
                bodyText: "[Number] Bed • [Number] Bath • [Sq Ft] sqft\n[Key features and highlights]",
                address: "[Property Address]",
                price: "$[Price]",
                phone: "[Agent Phone]",
                email: "[agent@email.com]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .professional, imageryType: .photoRealistic),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional listing design for homes and properties"
        ),

        // MARK: - Job Posting Templates
        FlyerTemplate(
            id: "job_hiring",
            name: "We're Hiring",
            category: .jobPosting,
            textContent: TextContent(
                headline: "We're Hiring!",
                subheadline: "[Job Title]",
                bodyText: "What we're looking for:\n• [Requirement 1]\n• [Requirement 2]\n• [Requirement 3]\n\nWhat we offer:\n• [Benefit 1]\n• [Benefit 2]\n• [Benefit 3]",
                ctaText: "Apply Now",
                email: "[careers@company.com]",
                website: "[company.com/careers]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .corporateProfessional, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional design for job postings and recruitment"
        ),

        FlyerTemplate(
            id: "job_career_fair",
            name: "Career Fair",
            category: .jobPosting,
            textContent: TextContent(
                headline: "Career Fair",
                subheadline: "Your Future Starts Here",
                bodyText: "Meet top employers\n• [Industry 1]\n• [Industry 2]\n• [Industry 3]\n\nBring your resume!",
                ctaText: "Register Free",
                website: "[registration-link.com]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Engaging design for career fairs and recruiting events"
        ),

        // MARK: - Class / Workshop Templates
        FlyerTemplate(
            id: "class_workshop",
            name: "Workshop Session",
            category: .classWorkshop,
            textContent: TextContent(
                headline: "[Workshop Title]",
                subheadline: "Learn • Practice • Master",
                venueName: "[Location / Online]",
                price: "$[Price]",
                ctaText: "Reserve Your Spot"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .inspirational),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Clean design for workshops, courses, and training sessions"
        ),

        FlyerTemplate(
            id: "class_tutoring",
            name: "Tutoring Services",
            category: .classWorkshop,
            textContent: TextContent(
                headline: "[Subject] Tutoring",
                subheadline: "Personalized Learning for Success",
                venueName: "[Tutor/Company Name]",
                price: "Starting at $[XX]/hour",
                ctaText: "Book a Session"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .handDrawnOrganic, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Friendly design for tutoring and educational services"
        ),

        // MARK: - Grand Opening Templates
        FlyerTemplate(
            id: "grandopening_store",
            name: "Store Grand Opening",
            category: .grandOpening,
            textContent: TextContent(
                headline: "Grand Opening!",
                subheadline: "[Business Name]",
                date: "[Date]",
                venueName: "[Business Name]",
                address: "[Address]",
                discountText: "[XX]% Off Opening Day",
                ctaText: "See You There!"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .boldVibrant, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Celebratory design for store and business grand openings"
        ),

        FlyerTemplate(
            id: "grandopening_restaurant",
            name: "Restaurant Grand Opening",
            category: .grandOpening,
            textContent: TextContent(
                headline: "Now Open!",
                subheadline: "[Restaurant Name]",
                bodyText: "Experience [cuisine type] like never before\n\n• Signature dishes\n• Craft cocktails\n• Warm atmosphere",
                date: "Opening [Date]",
                time: "Hours: [Opening Hours]",
                address: "[Address]",
                ctaText: "Make a Reservation",
                phone: "[Phone]",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .earthTones, backgroundType: .dark),
            visuals: VisualSettings(style: .elegantLuxury, mood: .elegant, imageryType: .photoRealistic),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Elegant design for restaurant and food establishment openings"
        ),

        // MARK: - Nonprofit / Community Templates
        FlyerTemplate(
            id: "nonprofit_fundraiser",
            name: "Fundraiser Event",
            category: .nonprofitCharity,
            textContent: TextContent(
                headline: "[Cause/Event Name]",
                subheadline: "Together We Can Make a Difference",
                bodyText: "Your support helps us:\n• [Impact 1]\n• [Impact 2]\n• [Impact 3]\n\nEvery donation counts!",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Organization Name]",
                address: "[Venue/Address]",
                ctaText: "Donate Now",
                website: "[donation-link.com]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .handDrawnOrganic, mood: .inspirational),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Heartfelt design for fundraisers and charitable causes"
        ),

        FlyerTemplate(
            id: "nonprofit_community_service",
            name: "Community Service",
            category: .nonprofitCharity,
            textContent: TextContent(
                headline: "[Service/Event Name]",
                subheadline: "Serving Our Community",
                bodyText: "Join us as we:\n• [Activity 1]\n• [Activity 2]\n• [Activity 3]\n\nAll are welcome!",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Organization Name]",
                address: "[Location]",
                ctaText: "Volunteer With Us",
                phone: "[Phone]",
                email: "[email@organization.org]"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .watercolorArtistic, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Warm design for community service and volunteer events"
        ),

        FlyerTemplate(
            id: "nonprofit_faith_gathering",
            name: "Faith & Community Gathering",
            category: .nonprofitCharity,
            textContent: TextContent(
                headline: "[Event/Service Name]",
                subheadline: "[Theme or Message]",
                bodyText: "Join us for:\n• [Activity 1]\n• [Activity 2]\n• [Activity 3]\n\nAll faiths and backgrounds welcome.",
                date: "[Day/Date]",
                time: "[Time]",
                venueName: "[Organization/Place of Worship]",
                address: "[Address]",
                ctaText: "Join Us",
                phone: "[Phone]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .calm),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Serene design for religious services and faith-based gatherings"
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
