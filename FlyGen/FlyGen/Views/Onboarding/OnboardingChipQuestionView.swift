import SwiftUI
import UIKit

/// The interactive turn: the assistant asks, the user taps chips (multi-select), then Continue
/// collapses the picks into a sent user bubble (handled by the view model). Used for both the
/// category and language questions.
struct OnboardingChipQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var vm: ChatOnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            AssistantBubble(text: question.prompt)

            FlowLayout(spacing: FGSpacing.xs) {
                chips
            }

            Button { vm.submitCurrentQuestion() } label: {
                Text("Continue")
                    .font(FGTypography.button)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }
            .padding(.top, FGSpacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var chips: some View {
        switch question.kind {
        case .category:
            ForEach(FlyerCategory.allCases) { cat in
                FGChipButton(title: cat.onboardingLabel,
                             isSelected: vm.selectedCategories.contains(cat),
                             icon: cat.icon) {
                    Haptics.selection()
                    if vm.selectedCategories.contains(cat) { vm.selectedCategories.remove(cat) }
                    else { vm.selectedCategories.insert(cat) }
                }
            }
        case .language:
            ForEach(FlyerLanguage.allCases, id: \.self) { lang in
                FGChipButton(title: lang.shortName,
                             isSelected: vm.selectedLanguages.contains(lang)) {
                    Haptics.selection()
                    if vm.selectedLanguages.contains(lang) { vm.selectedLanguages.remove(lang) }
                    else { vm.selectedLanguages.insert(lang) }
                }
            }
        }
    }
}

// The chip wrap uses the shared `FlowLayout` (defined in Views/Result/RefinementSheet.swift),
// the same one the refinement and smart-extras chip rows use.

// MARK: - Small shared helpers

enum Haptics {
    static func selection() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension FlyerLanguage {
    /// Compact label for chips; the full `displayName` carries a parenthetical translation.
    var shortName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .urdu:    return "اردو"
        case .arabic:  return "العربية"
        case .chinese: return "中文"
        }
    }
}

extension FlyerCategory {
    /// Warm, plain-language labels for the onboarding chips - the kind of thing people actually
    /// say they make, not marketing-taxonomy jargon ("Grand Opening"). Maps 1:1 to the category,
    /// so Explore's "For You" personalization is unchanged; only the wording differs.
    var onboardingLabel: String {
        switch self {
        case .event:            return "Events & gatherings"
        case .salePromo:        return "Sales & promos"
        case .announcement:     return "Announcements & newsletters"
        case .restaurantFood:   return "Restaurant & food"
        case .realEstate:       return "Property listings"
        case .jobPosting:       return "Hiring & jobs"
        case .classWorkshop:    return "Classes & workshops"
        case .grandOpening:     return "Grand openings"
        case .partyCelebration: return "Parties & birthdays"
        case .fitnessWellness:  return "Fitness & wellness"
        case .nonprofitCharity: return "Fundraisers & causes"
        case .musicConcert:     return "Concerts & gigs"
        case .serviceBusiness:  return "My services"
        case .beautySalon:      return "Salon & beauty"
        case .churchReligious:  return "Faith & community"
        }
    }
}
