import Foundation

enum FlyerLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case urdu = "ur"
    case arabic = "ar"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español (Spanish)"
        case .urdu: return "اردو (Urdu)"
        case .arabic: return "العربية (Arabic)"
        case .chinese: return "中文 (Chinese)"
        }
    }

    var promptInstruction: String {
        switch self {
        case .english:
            return "Generate all text content in English."
        case .spanish:
            return "Generate all text content in Spanish (Español). Translate headlines, descriptions, and calls-to-action to Spanish. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided. If the user provides text in another language, translate it to Spanish while preserving the intended meaning and tone."
        case .urdu:
            return "Generate all text content in Urdu (اردو). Use Nastaliq script. Render Urdu text right-to-left. Translate headlines, descriptions, and calls-to-action to Urdu. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Urdu while preserving the intended meaning and tone."
        case .arabic:
            return "Generate all text content in Arabic (العربية). Render Arabic text right-to-left. Translate headlines, descriptions, and calls-to-action to Arabic. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Arabic while preserving the intended meaning and tone."
        case .chinese:
            return "Generate all text content in Simplified Chinese (简体中文). Translate headlines, descriptions, and calls-to-action to Chinese. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided. If the user provides text in another language, translate it to Chinese while preserving the intended meaning and tone."
        }
    }
}
