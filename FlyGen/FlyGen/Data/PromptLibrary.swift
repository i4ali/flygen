import Foundation

/// A read-only starter prompt shown in the Prompts tab.
/// Curated from test-prompts.txt (QA scaffolding stripped). The `subtitle` is what the
/// card shows as its preview line; `promptText` is what gets dropped into the chat composer.
struct PromptTemplate: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let promptText: String
    let category: FlyerCategory
}

enum PromptLibrary {
    static let prompts: [PromptTemplate] = [
        PromptTemplate(
            id: "starter_newsletter_health",
            title: "School Newsletter Column",
            subtitle: "A health column for a school newsletter",
            promptText: """
            Need a flyer for the Health Corner column in our Northwest Saturday School newsletter. \
            Headline: Health Corner. It's the newsletter's health column for our school families. \
            Article: "Why Screen Time Matters" by Dr. Pareesa Nathani, Pediatrician. Keep it warm and \
            gentle, it's for parents. Add a "Learn More" and our site www.nwsaturdayschool.org
            """,
            category: .announcement
        ),
        PromptTemplate(
            id: "starter_majlis_program",
            title: "Majlis / Mourning Program",
            subtitle: "A solemn multi-night religious program",
            promptText: """
            Ashra-e-Sani majlis program at Markazi Imambargah Al-Murtaza, nightly from June 28th to \
            July 5th 2026. Program starts 8:40 PM each night right after Maghribain prayers. Guest \
            speaker Dr. Hasan Shaeba Rizvi from Canada. Hosted by Anjuman Alamdar e Hussain at 14903 \
            Belaire Blvd, Houston TX. al-murtaza.org
            """,
            category: .churchReligious
        ),
        PromptTemplate(
            id: "starter_friday_prayer",
            title: "Friday Prayer (Jumma)",
            subtitle: "A reverent congregational prayer announcement",
            promptText: """
            Namaz-e-Jumma (Friday Prayer) at Markazi Imambargah Al-Murtaza, Friday June 26th 2026 at \
            1:24 PM. Led by the Khateeb of Haram-e-Imam Raza, Maulana Mujahid Hussain Naqvi. Hosted by \
            Anjuman Alamdar e Hussain at 14903 Belaire Blvd, Houston TX. al-murtaza.org
            """,
            category: .churchReligious
        ),
        PromptTemplate(
            id: "starter_grand_opening",
            title: "Grand Opening",
            subtitle: "Announce a new business opening",
            promptText: "Grand opening of Nova Nail Bar on Saturday, first 10 people get 50% off",
            category: .grandOpening
        ),
        PromptTemplate(
            id: "starter_weekend_sale",
            title: "Weekend Sale",
            subtitle: "A time-boxed retail promotion",
            promptText: "Summer clearance at Bloom Boutique - 40% off all dresses this weekend only, Sat & Sun 10-6",
            category: .salePromo
        ),
        PromptTemplate(
            id: "starter_live_music",
            title: "Live Music Night",
            subtitle: "A concert or band night",
            promptText: "Indie folk showcase at The Greenhouse, Friday Nov 14, doors 7pm, three bands, $20 advance, tickets at greenhouse.com",
            category: .musicConcert
        ),
        PromptTemplate(
            id: "starter_charity_5k",
            title: "Charity 5K",
            subtitle: "A fundraising run or walk",
            promptText: "Charity 5K for the local food bank, Saturday June 28 at 8am, Riverside Park, register at run.example.org",
            category: .nonprofitCharity
        ),
        PromptTemplate(
            id: "starter_open_house",
            title: "Open House",
            subtitle: "A real-estate showing",
            promptText: "Open house this Sunday 1-4pm at 14 Maple Court, modern 3-bed with a renovated kitchen, hosted by Sarah Lin Realty",
            category: .realEstate
        ),
        PromptTemplate(
            id: "starter_now_hiring",
            title: "Now Hiring",
            subtitle: "A help-wanted flyer",
            promptText: "Now hiring baristas at Daybreak Coffee - part-time, flexible hours, apply in store at 88 Front St",
            category: .jobPosting
        ),
        PromptTemplate(
            id: "starter_pottery_workshop",
            title: "Pottery Workshop",
            subtitle: "A multi-session class",
            promptText: "Beginner pottery workshop Thursday evenings in July, 6-8pm at the Clay Studio, $120 for four sessions",
            category: .classWorkshop
        ),
        PromptTemplate(
            id: "starter_kids_birthday",
            title: "Kids Birthday Party",
            subtitle: "A children's party invite",
            promptText: "Birthday party for my daughter turning 7, Saturday 2pm at our house, superhero theme, RSVP by text",
            category: .partyCelebration
        ),
        PromptTemplate(
            id: "starter_taco_tuesday",
            title: "Taco Tuesday",
            subtitle: "A recurring restaurant special",
            promptText: "Taco Tuesday at El Jardin - $2 street tacos every Tuesday from 5pm, live mariachi at 7",
            category: .restaurantFood
        ),
        PromptTemplate(
            id: "starter_yard_sale",
            title: "Neighborhood Yard Sale",
            subtitle: "A community sale",
            promptText: "Flyer for a neighborhood yard sale, Saturday 8am-2pm on Elm Street, furniture, toys, and tools",
            category: .event
        ),
        PromptTemplate(
            id: "starter_rooftop_yoga",
            title: "Rooftop Yoga",
            subtitle: "A recurring fitness class",
            promptText: "Sunrise rooftop yoga Saturdays at 7am on the Lofthouse terrace, $18 drop-in, mats provided",
            category: .fitnessWellness
        )
    ]
}
