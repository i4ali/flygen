import Foundation

enum FlyerLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case urdu = "ur"
    case arabic = "ar"
    case chinese = "zh"
    case hindi = "hi"
    case french = "fr"
    case bengali = "bn"
    case portuguese = "pt"
    case russian = "ru"
    case indonesian = "id"
    case german = "de"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español (Spanish)"
        case .urdu: return "اردو (Urdu)"
        case .arabic: return "العربية (Arabic)"
        case .chinese: return "中文 (Chinese)"
        case .hindi: return "हिन्दी (Hindi)"
        case .french: return "Français (French)"
        case .bengali: return "বাংলা (Bengali)"
        case .portuguese: return "Português (Portuguese)"
        case .russian: return "Русский (Russian)"
        case .indonesian: return "Bahasa Indonesia (Indonesian)"
        case .german: return "Deutsch (German)"
        case .japanese: return "日本語 (Japanese)"
        }
    }

    var promptInstruction: String {
        switch self {
        case .english:
            return "Generate all text content in English."
        case .spanish:
            return "Generate all text content in Spanish (Español). Translate headlines, descriptions, and calls-to-action to Spanish. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Spanish while preserving the intended meaning and tone."
        case .urdu:
            return "Generate all text content in Urdu (اردو). Use Nastaliq script. Render Urdu text right-to-left. Translate headlines, descriptions, and calls-to-action to Urdu. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Urdu while preserving the intended meaning and tone."
        case .arabic:
            return "Generate all text content in Arabic (العربية). Render Arabic text right-to-left. Translate headlines, descriptions, and calls-to-action to Arabic. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Arabic while preserving the intended meaning and tone."
        case .chinese:
            return "Generate all text content in Simplified Chinese (简体中文). Translate headlines, descriptions, and calls-to-action to Chinese. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Chinese while preserving the intended meaning and tone."
        case .hindi:
            return "Generate all text content in Hindi (हिन्दी). Use Devanagari script. Translate headlines, descriptions, and calls-to-action to Hindi. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Hindi while preserving the intended meaning and tone."
        case .french:
            return "Generate all text content in French (Français). Translate headlines, descriptions, and calls-to-action to French. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to French while preserving the intended meaning and tone."
        case .bengali:
            return "Generate all text content in Bengali (বাংলা). Use Bengali script. Translate headlines, descriptions, and calls-to-action to Bengali. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Bengali while preserving the intended meaning and tone."
        case .portuguese:
            return "Generate all text content in Portuguese (Português). Translate headlines, descriptions, and calls-to-action to Portuguese. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Portuguese while preserving the intended meaning and tone."
        case .russian:
            return "Generate all text content in Russian (Русский). Use Cyrillic script. Translate headlines, descriptions, and calls-to-action to Russian. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Russian while preserving the intended meaning and tone."
        case .indonesian:
            return "Generate all text content in Indonesian (Bahasa Indonesia). Translate headlines, descriptions, and calls-to-action to Indonesian. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Indonesian while preserving the intended meaning and tone."
        case .german:
            return "Generate all text content in German (Deutsch). Translate headlines, descriptions, and calls-to-action to German. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to German while preserving the intended meaning and tone."
        case .japanese:
            return "Generate all text content in Japanese (日本語). Translate headlines, descriptions, and calls-to-action to Japanese. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Japanese while preserving the intended meaning and tone."
        }
    }
}
