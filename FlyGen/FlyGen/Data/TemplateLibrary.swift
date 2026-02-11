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

        FlyerTemplate(
            id: "sale_bogo",
            name: "BOGO / Bundle Deal",
            category: .salePromo,
            textContent: TextContent(
                headline: "Buy One Get One FREE",
                subheadline: "This Weekend Only",
                date: "[Date]",
                address: "[Store Address]",
                discountText: "BOGO on All Items",
                ctaText: "Shop Now",
                finePrint: "While supplies last"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .playfulFun, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Fun and attention-grabbing design for BOGO and bundle deals"
        ),

        FlyerTemplate(
            id: "sale_product_launch",
            name: "New Product Launch",
            category: .salePromo,
            textContent: TextContent(
                headline: "Introducing [Product]",
                subheadline: "Now Available",
                date: "[Launch Date]",
                address: "[Store Address]",
                ctaText: "Be First to Try It",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .gradientModern, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Modern design for product launches and new arrivals"
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

        FlyerTemplate(
            id: "restaurant_happy_hour",
            name: "Happy Hour Special",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "Happy Hour",
                subheadline: "Half-Price Drinks & Apps",
                bodyText: "Featured Specials:\n• House Margaritas $5\n• Draft Beer $3\n• Wings & Nachos 50% Off",
                venueName: "[Restaurant Name]",
                address: "[Address]",
                ctaText: "See You at 5!",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(style: .neonGlow, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Vibrant design for happy hour deals and drink specials"
        ),

        FlyerTemplate(
            id: "restaurant_food_truck",
            name: "Food Truck / Pop-Up",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "[Truck Name] Is Coming!",
                subheadline: "Street Food You'll Love",
                bodyText: "On the Menu:\n• [Dish 1]\n• [Dish 2]\n• [Dish 3]",
                address: "[Location]",
                ctaText: "Find Us This Weekend",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .playfulFun, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Fun design for food trucks, pop-ups, and street food events"
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

        FlyerTemplate(
            id: "fitness_yoga",
            name: "Yoga & Meditation Class",
            category: .fitnessWellness,
            textContent: TextContent(
                headline: "Find Your Inner Peace",
                subheadline: "Beginner-Friendly Yoga",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Studio Name]",
                price: "First Class Free",
                ctaText: "Reserve Your Mat"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .watercolorArtistic, mood: .calm),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Serene design for yoga, meditation, and mindfulness classes"
        ),

        FlyerTemplate(
            id: "fitness_personal_training",
            name: "Personal Training Special",
            category: .fitnessWellness,
            textContent: TextContent(
                headline: "Transform Your Body",
                subheadline: "1-on-1 Personal Training",
                discountText: "Free Consultation",
                ctaText: "Start Your Journey",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .boldVibrant, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "High-energy design for personal training and fitness coaching"
        ),

        FlyerTemplate(
            id: "fitness_wellness_retreat",
            name: "Wellness Retreat",
            category: .fitnessWellness,
            textContent: TextContent(
                headline: "Weekend Wellness Retreat",
                subheadline: "Recharge Mind, Body & Soul",
                date: "[Date]",
                venueName: "[Retreat Name]",
                address: "[Location]",
                price: "$199/person",
                ctaText: "Limited Spots Available"
            ),
            colors: ColorSettings(preset: .earthTones, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .calm),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Peaceful design for wellness retreats and spa getaways"
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

        FlyerTemplate(
            id: "music_dj_night",
            name: "DJ Night / Club Event",
            category: .musicConcert,
            textContent: TextContent(
                headline: "Friday Night Live",
                subheadline: "DJ [Name] Spinning All Night",
                date: "[Date]",
                time: "10 PM - 2 AM",
                venueName: "[Club Name]",
                price: "$15 Cover",
                ctaText: "Get On The List"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(style: .neonGlow, mood: .exciting),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Electric design for DJ nights, club events, and dance parties"
        ),

        FlyerTemplate(
            id: "music_open_mic",
            name: "Open Mic Night",
            category: .musicConcert,
            textContent: TextContent(
                headline: "Open Mic Night",
                subheadline: "Share Your Talent",
                date: "[Date]",
                time: "8 PM",
                venueName: "[Venue Name]",
                address: "[Address]",
                ctaText: "Sign Up to Perform"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(style: .retroVintage, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Warm retro design for open mic nights and acoustic sessions"
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

        // MARK: - Church & Faith Templates
        FlyerTemplate(
            id: "church_sunday_service",
            name: "Sunday Service",
            category: .churchReligious,
            textContent: TextContent(
                headline: "Join Us This Sunday",
                subheadline: "All Are Welcome",
                date: "[Date]",
                time: "10:00 AM",
                venueName: "[Church Name]",
                address: "[Address]",
                ctaText: "Come As You Are"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .inspirational),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Warm and inviting design for weekly worship service invitations"
        ),

        FlyerTemplate(
            id: "church_bible_study",
            name: "Bible Study / Youth Group",
            category: .churchReligious,
            textContent: TextContent(
                headline: "Bible Study Wednesday",
                subheadline: "Growing Together in Faith",
                date: "[Date]",
                time: "7:00 PM",
                venueName: "[Church Name]",
                ctaText: "All Ages Welcome",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Clean design for Bible study groups and fellowship gatherings"
        ),

        FlyerTemplate(
            id: "church_holiday_service",
            name: "Holiday Service",
            category: .churchReligious,
            textContent: TextContent(
                headline: "Christmas Eve Service",
                subheadline: "Celebrate the Season of Joy",
                date: "[Date]",
                time: "[Time]",
                venueName: "[Church Name]",
                address: "[Address]",
                ctaText: "Bring Your Family"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(style: .watercolorArtistic, mood: .festive),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Festive design for Christmas, Easter, and special holiday services"
        ),

        // MARK: - Beauty & Salon Templates
        FlyerTemplate(
            id: "beauty_price_list",
            name: "Salon Price List",
            category: .beautySalon,
            textContent: TextContent(
                headline: "Pamper Yourself",
                bodyText: "Our Services:\n• Haircut & Style - $45+\n• Color & Highlights - $85+\n• Manicure & Pedicure - $55\n• Facial Treatment - $65\n• Lash Extensions - $120",
                address: "[Salon Address]",
                ctaText: "Book Your Appointment",
                phone: "[Phone Number]",
                socialHandle: "@[yoursalon]"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .light),
            visuals: VisualSettings(style: .elegantLuxury, mood: .elegant),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Elegant price list design for salons and spas"
        ),

        FlyerTemplate(
            id: "beauty_new_client",
            name: "New Client Special",
            category: .beautySalon,
            textContent: TextContent(
                headline: "Welcome to [Salon Name]",
                discountText: "50% Off First Visit",
                ctaText: "Claim Your Offer",
                phone: "[Phone Number]",
                website: "[website.com]",
                socialHandle: "@[yoursalon]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .gradientModern, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Attractive welcome offer for first-time salon customers"
        ),

        FlyerTemplate(
            id: "beauty_barber",
            name: "Barber Shop",
            category: .beautySalon,
            textContent: TextContent(
                headline: "Classic Cuts & Clean Shaves",
                subheadline: "Traditional Barbering",
                bodyText: "Services:\n• Classic Haircut\n• Hot Towel Shave\n• Beard Trim & Shape\n• Kids Cuts",
                address: "[Shop Address]",
                ctaText: "Walk-ins Welcome",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .monochrome, backgroundType: .dark),
            visuals: VisualSettings(style: .retroVintage, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Classic design for barber shops and men's grooming"
        ),

        // MARK: - Service Business Templates
        FlyerTemplate(
            id: "service_cleaning",
            name: "Cleaning Service",
            category: .serviceBusiness,
            textContent: TextContent(
                headline: "Sparkling Clean Homes",
                subheadline: "Professional Cleaning Services",
                bodyText: "Our Services:\n• Deep House Cleaning\n• Office Cleaning\n• Move-In/Move-Out\n• Weekly & Bi-Weekly Plans",
                discountText: "20% Off First Clean",
                ctaText: "Book Today",
                phone: "[Phone Number]",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .modernMinimal, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional flyer for home and office cleaning services"
        ),

        FlyerTemplate(
            id: "service_handyman",
            name: "Handyman & Repair",
            category: .serviceBusiness,
            textContent: TextContent(
                headline: "Your Local Handyman",
                subheadline: "No Job Too Small",
                bodyText: "Services Include:\n• Plumbing Repairs\n• Electrical Fixes\n• Drywall & Painting\n• Furniture Assembly",
                address: "[Service Area]",
                ctaText: "Call for Free Estimate",
                phone: "[Phone Number]"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(style: .boldVibrant, mood: .friendly),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Eye-catching flyer for handyman and general repair services"
        ),

        FlyerTemplate(
            id: "service_landscaping",
            name: "Lawn Care & Landscaping",
            category: .serviceBusiness,
            textContent: TextContent(
                headline: "Beautiful Lawns Start Here",
                subheadline: "Full-Service Landscaping",
                bodyText: "What We Offer:\n• Lawn Mowing & Edging\n• Tree & Shrub Trimming\n• Garden Design\n• Seasonal Cleanup",
                price: "Starting at $49",
                ctaText: "Get a Free Quote",
                phone: "[Phone Number]",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .earthTones, backgroundType: .light),
            visuals: VisualSettings(style: .handDrawnOrganic, mood: .calm),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Natural design for lawn care and landscaping businesses"
        ),

        FlyerTemplate(
            id: "service_general",
            name: "General Services",
            category: .serviceBusiness,
            textContent: TextContent(
                headline: "Professional [Service] You Can Trust",
                subheadline: "Licensed & Insured",
                bodyText: "Why Choose Us:\n• Experienced Professionals\n• Satisfaction Guaranteed\n• Competitive Pricing\n• Free Consultations",
                ctaText: "Schedule Now",
                phone: "[Phone Number]",
                email: "[email@example.com]",
                website: "[website.com]"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(style: .corporateProfessional, mood: .professional),
            output: OutputSettings(aspectRatio: .portrait),
            previewDescription: "Professional flyer for tutoring, pet sitting, and general services"
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
