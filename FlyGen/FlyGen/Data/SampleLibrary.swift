import Foundation

/// Library of sample flyers displayed in the Explore tab
/// Data sourced from test_flyer.py test cases used to generate the sample images
struct SampleLibrary {
    static let samples: [SampleFlyer] = [
        // MARK: - Test 8: Restaurant Grand Opening
        SampleFlyer(
            id: "sample_grand_opening",
            imageName: "sample_grand_opening",
            name: "Grand Opening Restaurant",
            category: .grandOpening,
            textContent: TextContent(
                headline: "GRAND OPENING",
                subheadline: "Experience Modern Italian Cuisine",
                date: "Friday, January 10th, 2025 | 5:00 PM - 11:00 PM",
                venueName: "Bella Vista Ristorante",
                address: "445 Main Street, Downtown Seattle",
                discountText: "COMPLIMENTARY CHAMPAGNE",
                ctaText: "Reserve Your Table"
            ),
            colors: ColorSettings(preset: .blackGold, backgroundType: .dark),
            visuals: VisualSettings(
                style: .elegantLuxury,
                mood: .elegant,
                textProminence: .balanced,
                includeElements: ["ribbon cutting", "champagne glasses", "elegant table setting"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Fine dining enthusiasts, couples looking for date night spots",
            specialInstructions: "Emphasize luxury and sophistication with warm, inviting lighting"
        ),

        // MARK: - Test 11: Tech Conference
        SampleFlyer(
            id: "sample_tech_conference",
            imageName: "sample_tech_conference",
            name: "Tech Conference",
            category: .event,
            textContent: TextContent(
                headline: "TECHSUMMIT 2025",
                subheadline: "The Premier Technology Conference for Developers & Entrepreneurs",
                venueName: "Austin Convention Center",
                address: "500 E Cesar Chavez Street, Austin, TX 78701",
                ctaText: "Register Now at TechSummit2025.com",
                website: "www.techsummit2025.com"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .gradient),
            visuals: VisualSettings(
                style: .modernMinimal,
                mood: .professional,
                textProminence: .dominant,
                includeElements: ["circuit patterns", "digital grid lines", "abstract tech shapes"],
                avoidElements: ["outdated technology imagery"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Software developers, tech entrepreneurs, startup founders"
        ),

        // MARK: - Test 14: Educational Newsletter
        SampleFlyer(
            id: "sample_educational_newsletter",
            imageName: "sample_educational_newsletter",
            name: "Educational Newsletter",
            category: .announcement,
            textContent: TextContent(
                headline: "Health Corner",
                subheadline: "Northwest Saturday School Newsletter",
                bodyText: """
                    Why Screen Time Matters
                    By Dr. Pareesa Nathani, Pediatrician

                    Screens can be helpful for learning, but too much can affect:
                    • Sleep
                    • Mood and tantrums
                    • Behavior and attention
                    • Language skills and connection
                    • Social skills and real-life play

                    The goal isn't no screen time — it's healthy screen habits.

                    Recommended Daily Screen Time:
                    Ages 0-2: Avoid screens except for video calls with family
                    Ages 2-5: About 1 hour per day of high-quality content
                    Ages 6+: Set clear, consistent limits as a family

                    Islamic Perspective:
                    Islam teaches us to protect the heart and mind from harmful influences.

                    Visit: www.nwsaturdayschool.org
                    """,
                ctaText: "Learn More"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .gradient),
            visuals: VisualSettings(
                style: .watercolorArtistic,
                mood: .friendly,
                textProminence: .dominant,
                includeElements: ["soft watercolor backgrounds", "children's book style illustrations", "gentle nature elements"],
                avoidElements: ["screens showing content", "scary or alarming imagery"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Parents of young children, school community members",
            specialInstructions: "Design should feel nurturing and educational, not alarming"
        ),

        // MARK: - Test 4: Mega Weekend Sale
        SampleFlyer(
            id: "sample_mega_sale",
            imageName: "sample_mega_sale",
            name: "Mega Sale",
            category: .salePromo,
            textContent: TextContent(
                headline: "MEGA WEEKEND SALE",
                subheadline: "The Biggest Sale of the Year",
                date: "December 14-15, 2024 | 10:00 AM - 8:00 PM",
                address: "Fashion District Mall, 8899 Retail Row, Suite 200, Dallas, TX 75201",
                discountText: "UP TO 70% OFF",
                ctaText: "Shop Now - Limited Time!",
                website: "www.fashiondistrict.com/mega-sale",
                finePrint: "While supplies last. Some exclusions apply."
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(
                style: .neonGlow,
                mood: .urgent,
                textProminence: .dominant,
                includeElements: ["sale tags", "burst shapes", "shopping bags", "percentage badges"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Bargain hunters, fashion shoppers"
        ),

        // MARK: - Brake Service Special (defined from sample image)
        SampleFlyer(
            id: "sample_brake_service",
            imageName: "sample_brake_service",
            name: "Brake Service Special",
            category: .salePromo,
            textContent: TextContent(
                headline: "BRAKE SERVICE SPECIAL",
                subheadline: "Trust Your Brakes to the Experts",
                address: "Joe's Auto Repair - 4520 Jones Road, Houston, TX",
                discountText: "20% OFF BRAKE PADS & ROTORS",
                ctaText: "Schedule Your Appointment Today!",
                website: "www.joesautorepair.com",
                finePrint: "Most vehicles. Inspection included. Offer valid through January 2025."
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(
                style: .retroVintage,
                mood: .friendly,
                textProminence: .balanced,
                includeElements: ["automotive tools", "brake disc imagery", "checkered racing patterns"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Car owners needing maintenance"
        ),

        // MARK: - No Registration Fees (defined from sample image)
        SampleFlyer(
            id: "sample_no_registration",
            imageName: "sample_no_registration",
            name: "No Registration Fees",
            category: .salePromo,
            textContent: TextContent(
                headline: "No Registration Fees",
                subheadline: "plus discount on first month",
                address: "17710 S Cypress Villas Dr, Spring, TX 77379",
                ctaText: "Call Now",
                website: "brightmontschool.com"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(
                style: .playfulFun,
                mood: .friendly,
                textProminence: .balanced,
                includeElements: ["school supplies", "learning icons", "playful shapes"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Parents of school-age children"
        ),

        // MARK: - Test 20: Spanish Restaurant
        SampleFlyer(
            id: "sample_spanish_restaurant",
            imageName: "sample_spanish_restaurant",
            name: "Spanish Restaurant",
            category: .restaurantFood,
            language: .spanish,
            textContent: TextContent(
                headline: "Taquería El Sol",
                subheadline: "Auténtica Comida Mexicana",
                address: "2547 Main Street, Houston TX 77002",
                price: "Tacos desde $2.50",
                ctaText: "¡Visítanos Hoy!",
                phone: "(713) 555-1234"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .light),
            visuals: VisualSettings(
                style: .boldVibrant,
                mood: .friendly,
                textProminence: .balanced,
                includeElements: ["authentic Mexican food imagery", "traditional patterns", "fresh ingredients"],
                avoidElements: ["stereotypical or offensive cultural imagery"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Mexican food lovers, local Hispanic community",
            specialInstructions: "Use warm, authentic Mexican color palette"
        ),

        // MARK: - Test 21: Arabic Eid Event
        SampleFlyer(
            id: "sample_arabic_eid_event",
            imageName: "sample_arabic_eid_event",
            name: "Eid Event",
            category: .event,
            language: .arabic,
            textContent: TextContent(
                headline: "عيد مبارك",
                subheadline: "احتفال عيد الفطر المبارك",
                venueName: "المركز الإسلامي",
                address: "1234 Islamic Center Drive, Houston TX",
                ctaText: "الدعوة عامة للجميع"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .gradient),
            visuals: VisualSettings(
                style: .elegantLuxury,
                mood: .festive,
                textProminence: .dominant,
                includeElements: ["crescent moon", "stars", "Islamic geometric patterns", "lanterns"],
                avoidElements: ["human figures", "religious figures"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Muslim community members, families celebrating Eid",
            specialInstructions: "Use elegant Islamic art patterns"
        ),

        // MARK: - Test 18: Chinese Fitness Class
        SampleFlyer(
            id: "sample_chinese_fitness",
            imageName: "sample_chinese_fitness",
            name: "Fitness Class",
            category: .fitnessWellness,
            language: .chinese,
            textContent: TextContent(
                headline: "30天健身挑战",
                subheadline: "新年新气象 · 改变从今天开始",
                date: "2025年1月6日起",
                time: "每日课程: 早6点, 中午12点, 晚6点",
                venueName: "巅峰健身中心",
                price: "30天仅需¥499",
                discountText: "前50名报名享6折优惠",
                ctaText: "立即加入挑战!"
            ),
            colors: ColorSettings(preset: .neon, backgroundType: .dark),
            visuals: VisualSettings(
                style: .boldVibrant,
                mood: .exciting,
                textProminence: .dominant,
                includeElements: ["fitness equipment silhouettes", "energy burst graphics", "dynamic motion lines"],
                avoidElements: ["before/after body imagery"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Chinese-speaking fitness enthusiasts"
        ),

        // MARK: - Test 27: Beatles Tribute Concert (with user photo)
        SampleFlyer(
            id: "sample_concert_user_photo",
            imageName: "sample_concert_user_photo",
            name: "Beatles Tribute Concert",
            category: .musicConcert,
            textContent: TextContent(
                headline: "THE BEATLES TRIBUTE NIGHT",
                subheadline: "A Magical Mystery Tour Through the Hits",
                date: "Saturday, February 15, 2025 | 8:00 PM",
                venueName: "Abbey Road Live",
                address: "1969 Penny Lane, Liverpool, TX 77001",
                price: "$45 General | $75 VIP",
                ctaText: "Get Your Tickets Now!",
                website: "www.abbeyroadlive.com"
            ),
            colors: ColorSettings(preset: .warm, backgroundType: .dark),
            visuals: VisualSettings(
                style: .retroVintage,
                mood: .exciting,
                textProminence: .balanced,
                includeElements: ["vintage microphones", "vinyl records", "60s-style patterns", "stage lights"],
                avoidElements: ["modern technology", "contemporary elements"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Beatles fans, classic rock enthusiasts, 50+ demographic",
            specialInstructions: "Capture authentic retro 60s aesthetic with psychedelic-inspired elements"
        ),

        // MARK: - Test 34: Community Newsletter
        SampleFlyer(
            id: "sample_community_newsletter",
            imageName: "sample_community_newsletter",
            name: "Community Newsletter",
            category: .announcement,
            textContent: TextContent(
                headline: "Riverside Community News",
                subheadline: "Your Neighborhood Update - Spring 2025",
                bodyText: """
                    From the HOA Board

                    Spring is here and our community is thriving! Here's what you need to know:

                    COMMUNITY UPDATES
                    • Pool opens May 1st - new hours: 8 AM - 9 PM
                    • Landscaping improvements completed on Oak Drive
                    • New playground equipment installed at Central Park

                    IMPORTANT REMINDERS
                    • Annual dues are due by March 15th
                    • Garage sale weekend: April 5-6
                    • Lawn maintenance standards in effect

                    UPCOMING EVENTS
                    March 22 - Spring Block Party (4-8 PM)
                    April 12 - Easter Egg Hunt at Central Park
                    April 26 - Community Clean-Up Day

                    CONTACT US
                    Email: board@riversidehoa.org
                    Portal: www.riversidecommunity.org
                    """,
                ctaText: "Join our Facebook Group!"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(
                style: .modernMinimal,
                mood: .professional,
                textProminence: .dominant,
                includeElements: ["neighborhood icons", "community symbols", "seasonal spring elements"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "HOA members, neighborhood residents"
        ),

        // MARK: - Test 35: Tech Startup Newsletter
        SampleFlyer(
            id: "sample_tech_newsletter",
            imageName: "sample_tech_newsletter",
            name: "Tech Product Update",
            category: .announcement,
            textContent: TextContent(
                headline: "Product Update",
                subheadline: "CloudSync Monthly - January 2025",
                bodyText: """
                    What's New in CloudSync

                    NEW FEATURES
                    • Real-time collaboration - Edit documents with your team simultaneously
                    • AI-powered search - Find files instantly with natural language
                    • Mobile app v3.0 - Completely redesigned for speed

                    PERFORMANCE IMPROVEMENTS
                    We've reduced sync times by 60% and improved offline mode reliability.

                    BY THE NUMBERS
                    • 2M+ files synced daily
                    • 99.99% uptime in 2024
                    • 50+ new integrations added

                    COMING SOON
                    • Advanced analytics dashboard
                    • Custom workflow automation
                    • Enterprise SSO improvements

                    PRO TIP
                    Try the new keyboard shortcut Cmd+K to access quick actions from anywhere!

                    Learn more: blog.cloudsync.io
                    """,
                ctaText: "Upgrade to Pro - 20% Off"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .dark),
            visuals: VisualSettings(
                style: .gradientModern,
                mood: .exciting,
                textProminence: .dominant,
                includeElements: ["cloud icons", "sync arrows", "app interface elements"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "SaaS customers, tech-savvy professionals"
        ),

        // MARK: - Test 36: Internet Safety Newsletter
        SampleFlyer(
            id: "sample_internet_safety",
            imageName: "sample_internet_safety",
            name: "Internet Safety Newsletter",
            category: .announcement,
            textContent: TextContent(
                headline: "Digital Safety Corner",
                subheadline: "Northwest Saturday School Newsletter",
                bodyText: """
                    Keeping Our Children Safe Online
                    By Officer Jameel Hassan, School Resource Officer

                    The internet is a powerful tool for learning, but it comes with real risks. Here's what every parent should know:

                    WARNING SIGNS YOUR CHILD MAY BE AT RISK
                    • Hiding screens when you walk by
                    • Becoming withdrawn or secretive
                    • New "friends" you've never heard of
                    • Unexpected gifts or money
                    • Using devices late at night

                    CYBERBULLYING: WHAT TO WATCH FOR
                    • Sudden reluctance to use devices
                    • Emotional after being online
                    • Deleting social media accounts
                    • Declining grades or school avoidance

                    5 RULES EVERY FAMILY NEEDS
                    1. Devices stay in common areas - no phones in bedrooms
                    2. Know your child's passwords and accounts
                    3. Set daily time limits (use Screen Time or Family Link)
                    4. Talk openly about what they see online
                    5. Report suspicious contact immediately

                    ISLAMIC PERSPECTIVE
                    The Prophet (PBUH) said: "Each of you is a shepherd and each is responsible for his flock."

                    Our children are our trust (amanah). Protecting their eyes, hearts, and minds from harmful content is part of our duty as parents.

                    Resources: www.nwsaturdayschool.org/safety
                    """,
                ctaText: "Download Our Family Safety Guide"
            ),
            colors: ColorSettings(preset: .cool, backgroundType: .light),
            visuals: VisualSettings(
                style: .modernMinimal,
                mood: .professional,
                textProminence: .dominant,
                includeElements: ["shield icons", "lock symbols", "digital safety icons"],
                avoidElements: ["scary or threatening imagery", "predatory imagery"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Parents concerned about online safety",
            specialInstructions: "Convey protection and guidance, not fear"
        ),

        // MARK: - Test 43: Holiday Restaurant Special
        SampleFlyer(
            id: "sample_holiday_restaurant",
            imageName: "sample_holiday_restaurant",
            name: "Holiday Restaurant Special",
            category: .restaurantFood,
            textContent: TextContent(
                headline: "Christmas Day",
                subheadline: "WE'RE OPEN | 12 PM - 5 PM",
                venueName: "Oh My Chai",
                address: "46090 Michigan Ave, Canton MI",
                price: "Bihari Kabob Rolls",
                ctaText: "LIMITED & EXCLUSIVE"
            ),
            colors: ColorSettings(preset: .blackGold, backgroundType: .dark),
            visuals: VisualSettings(
                style: .elegantLuxury,
                mood: .festive,
                textProminence: .balanced,
                includeElements: ["festive holiday decorations", "elegant food presentation"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Local diners looking for holiday dining",
            specialInstructions: "Food should be the star of the design"
        ),

        // MARK: - Test 19: Urdu Niaz Invitation
        SampleFlyer(
            id: "sample_urdu_niaz",
            imageName: "sample_urdu_niaz",
            name: "Urdu Niaz Invitation",
            category: .event,
            language: .urdu,
            textContent: TextContent(
                headline: "نیاز امام جعفر صادق (علیہ السلام)",
                subheadline: "براہ کرم ہمارے ساتھ شامل ہوں",
                date: "یکم جنوری 2026 | شام 6 بجے سے رات 10 بجے تک",
                address: "4521 Meadow Brook Drive, Houston TX 77084",
                ctaText: "فاطمہ اور علی کی طرف سے دعوت"
            ),
            colors: ColorSettings(preset: .pastel, backgroundType: .gradient),
            visuals: VisualSettings(
                style: .elegantLuxury,
                mood: .elegant,
                textProminence: .dominant,
                includeElements: ["Islamic geometric patterns", "elegant borders", "floral motifs"],
                avoidElements: ["human figures", "photos of people"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Shia Muslim community, Urdu-speaking families",
            specialInstructions: "Elegant and respectful religious invitation design"
        ),

        // MARK: - Barber Shop - Classic Cuts
        SampleFlyer(
            id: "sample_barber_shop",
            imageName: "sample_barber_shop",
            name: "Classic Cuts & Clean Shaves",
            category: .beautySalon,
            textContent: TextContent(
                headline: "CLASSIC CUTS & CLEAN SHAVES",
                subheadline: "Traditional Barbering",
                bodyText: "Services:\n• Classic Haircut\n• Hot Towel Shave\n• Beard Trim & Shape\n• Kids Cuts",
                address: "9675 Jones Road, Houston, TX",
                discountText: "UP TO 20% OFF",
                ctaText: "WALK-INS WELCOME",
                phone: "713-456-9876"
            ),
            colors: ColorSettings(preset: .blackGold, backgroundType: .dark),
            visuals: VisualSettings(
                style: .retroVintage,
                mood: .professional,
                textProminence: .balanced,
                includeElements: ["barber pole", "vintage barber chair", "scissors", "shaving brush"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Men looking for traditional barbershop services"
        ),

        // MARK: - Service Business - Barber Shop (duplicate for serviceBusiness category)
        SampleFlyer(
            id: "sample_barber_shop_service",
            imageName: "sample_barber_shop",
            name: "Classic Cuts & Clean Shaves",
            category: .serviceBusiness,
            textContent: TextContent(
                headline: "CLASSIC CUTS & CLEAN SHAVES",
                subheadline: "Traditional Barbering",
                bodyText: "Services:\n• Classic Haircut\n• Hot Towel Shave\n• Beard Trim & Shape\n• Kids Cuts",
                address: "9675 Jones Road, Houston, TX",
                discountText: "UP TO 20% OFF",
                ctaText: "WALK-INS WELCOME",
                phone: "713-456-9876"
            ),
            colors: ColorSettings(preset: .blackGold, backgroundType: .dark),
            visuals: VisualSettings(
                style: .retroVintage,
                mood: .professional,
                textProminence: .balanced,
                includeElements: ["barber pole", "vintage barber chair", "scissors", "shaving brush"]
            ),
            output: OutputSettings(aspectRatio: .portrait),
            targetAudience: "Men looking for traditional barbershop services"
        )
    ]

    /// Get a sample by its ID
    static func sample(withId id: String) -> SampleFlyer? {
        samples.first { $0.id == id }
    }
}
