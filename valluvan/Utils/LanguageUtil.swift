import Foundation

struct LanguageUtil {
    static let tamilTitle = ["அறத்துப்பால்", "பொருட்பால்", "இன்பத்துப்பால்"]
    static let englishTitle = ["Virtue", "Wealth", "Nature of Love"] 
    static let teluguTitle = ["ధర్మం", "సంపద", "ప్రేమ స్వభావం"]
    static let hindiTitle = ["धर्म", "धन", "प्रेम"]
    static let kannadaTitle = ["ಧರ್ಮ", "సంపద", "ಪ್ರೇಮ"]
    static let frenchTitle = ["Perfection", "Richesse", "Nature de l'Amour"]
    static let arabicTitle = ["فضيلة", "الثروة", "طبيعة الحب"]
    static let chineseTitle = ["美德", "财富", "爱的本质"]
    static let germanTitle = ["Tugend", "Wealth", "Natur des Verliebens"]
    static let koreanTitle = ["미덕", "재물", "사랑의 본성"]
    static let malayTitle = ["Kesempurnaan", "Kekayaan", "Sifat Cinta"]
    static let malayalamTitle = ["മന്നാല്‍", "പരിപാലനം", "അന്തരാളികം പ്രിയം"]
    static let polishTitle = ["Dobroć", "Bogactwo", "Natura miłości"]
    static let russianTitle = ["Добродетель", "Богатство", "Суть любви"]
    static let singalamTitle = ["දානය", "අරමුණ", "සතුට"]
    static let swedishTitle = ["Dygd", "Välst", "Kärlekens natur"]
    
    static func getCurrentTitle(_ index: Int, for language: String) -> String {
        switch language {
        case "Tamil":
            return tamilTitle[index]
        case "English":
            return englishTitle[index]
        case "telugu":
            return teluguTitle[index]
        case "hindi":
            return hindiTitle[index]
        case "kannad":
            return kannadaTitle[index]
        case "french":
            return frenchTitle[index]
        case "arabic":
            return arabicTitle[index]
        case "chinese":
            return chineseTitle[index]
        case "german":
            return germanTitle[index]
        case "korean":
            return koreanTitle[index]
        case "malay":
            return malayTitle[index]
        case "malayalam":
            return malayalamTitle[index]
        case "polish":
            return polishTitle[index]
        case "russian":
            return russianTitle[index]
        case "singalam":
            return singalamTitle[index]
        case "swedish":
            return swedishTitle[index]
        default:
            return englishTitle[index] // Fallback to English if language is not found
        }
    }
}