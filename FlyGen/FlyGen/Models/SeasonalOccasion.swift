import Foundation

/// Represents a seasonal occasion for engagement notifications
struct SeasonalOccasion: Identifiable {
    let id: String
    let name: String
    let notificationTitle: String
    let notificationBody: String
    let suggestedCategory: FlyerCategory
    let month: Int
    let day: Int

    /// All seasonal occasions throughout the year
    static let all: [SeasonalOccasion] = [
        SeasonalOccasion(
            id: "new_year",
            name: "New Year",
            notificationTitle: "New Year is almost here!",
            notificationBody: "Create stunning New Year party invitations and celebration flyers",
            suggestedCategory: .partyCelebration,
            month: 12,
            day: 28
        ),
        SeasonalOccasion(
            id: "valentines_day",
            name: "Valentine's Day",
            notificationTitle: "Valentine's Day is coming!",
            notificationBody: "Create romantic dinner flyers or love-themed invitations",
            suggestedCategory: .partyCelebration,
            month: 2,
            day: 10
        ),
        SeasonalOccasion(
            id: "ramadan",
            name: "Ramadan",
            notificationTitle: "Ramadan Mubarak!",
            notificationBody: "Create beautiful iftar invitations and Ramadan event flyers",
            suggestedCategory: .event,
            month: 3,
            day: 1
        ),
        SeasonalOccasion(
            id: "easter",
            name: "Easter",
            notificationTitle: "Easter is approaching!",
            notificationBody: "Design Easter egg hunts, brunch invites, and spring celebration flyers",
            suggestedCategory: .event,
            month: 4,
            day: 1
        ),
        SeasonalOccasion(
            id: "mothers_day",
            name: "Mother's Day",
            notificationTitle: "Mother's Day is coming!",
            notificationBody: "Create heartfelt Mother's Day event flyers and special offers",
            suggestedCategory: .partyCelebration,
            month: 5,
            day: 7
        ),
        SeasonalOccasion(
            id: "graduation",
            name: "Graduation Season",
            notificationTitle: "Graduation season is here!",
            notificationBody: "Design graduation party invites and celebration announcements",
            suggestedCategory: .partyCelebration,
            month: 6,
            day: 1
        ),
        SeasonalOccasion(
            id: "fathers_day",
            name: "Father's Day",
            notificationTitle: "Father's Day is coming!",
            notificationBody: "Create Father's Day event flyers and special promotions",
            suggestedCategory: .partyCelebration,
            month: 6,
            day: 12
        ),
        SeasonalOccasion(
            id: "july_4th",
            name: "4th of July",
            notificationTitle: "Independence Day is coming!",
            notificationBody: "Design patriotic party invites and July 4th celebration flyers",
            suggestedCategory: .partyCelebration,
            month: 7,
            day: 1
        ),
        SeasonalOccasion(
            id: "back_to_school",
            name: "Back to School",
            notificationTitle: "Back to School season!",
            notificationBody: "Create flyers for tutoring, school events, or supplies sales",
            suggestedCategory: .announcement,
            month: 8,
            day: 10
        ),
        SeasonalOccasion(
            id: "labor_day",
            name: "Labor Day Sales",
            notificationTitle: "Labor Day weekend approaching!",
            notificationBody: "Create eye-catching sale flyers for Labor Day deals",
            suggestedCategory: .salePromo,
            month: 8,
            day: 28
        ),
        SeasonalOccasion(
            id: "halloween",
            name: "Halloween",
            notificationTitle: "Spooky season is here!",
            notificationBody: "Design Halloween party invites or costume contest flyers",
            suggestedCategory: .partyCelebration,
            month: 10,
            day: 24
        ),
        SeasonalOccasion(
            id: "thanksgiving",
            name: "Thanksgiving",
            notificationTitle: "Thanksgiving is coming!",
            notificationBody: "Create Thanksgiving dinner invites and gratitude event flyers",
            suggestedCategory: .event,
            month: 11,
            day: 20
        ),
        SeasonalOccasion(
            id: "black_friday",
            name: "Black Friday",
            notificationTitle: "Black Friday prep time!",
            notificationBody: "Create eye-catching sale flyers for your biggest deals",
            suggestedCategory: .salePromo,
            month: 11,
            day: 25
        ),
        SeasonalOccasion(
            id: "christmas",
            name: "Christmas & Holidays",
            notificationTitle: "Holiday season is here!",
            notificationBody: "Design Christmas party invites and holiday celebration flyers",
            suggestedCategory: .partyCelebration,
            month: 12,
            day: 18
        )
    ]

    /// Get the next notification date for this occasion
    func nextNotificationDate(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)

        // Try this year first
        var components = DateComponents()
        components.year = currentYear
        components.month = month
        components.day = day
        components.hour = 10 // 10 AM
        components.minute = 0

        if let thisYearDate = calendar.date(from: components), thisYearDate > date {
            return thisYearDate
        }

        // Otherwise, next year
        components.year = currentYear + 1
        return calendar.date(from: components)
    }

    /// Get the next upcoming occasions from now
    static func upcomingOccasions(count: Int = 4, from date: Date = Date()) -> [SeasonalOccasion] {
        let sorted = all.compactMap { occasion -> (SeasonalOccasion, Date)? in
            guard let nextDate = occasion.nextNotificationDate(from: date) else { return nil }
            return (occasion, nextDate)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(count)
        .map { $0.0 }

        return Array(sorted)
    }
}
