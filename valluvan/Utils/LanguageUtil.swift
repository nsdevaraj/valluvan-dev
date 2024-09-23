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

    static func convertTamilToEnglish(tamilText: String) -> String {
        let tamilArr: [Character] = ["அ", "ஆ", "இ", "ஈ", "உ", "ஊ", "எ", "ஏ", "ஐ", "ஒ", "ஓ", "ஔ", "க", "ங", "ச", "ஜ", "ஞ", "ட", "த", "ந", "ண", "ன", "ப", "ம", "ய", "ர", "ற", "ல", "ள", "ழ", "வ", "ஷ", "ஸ", "ஹ", "ஃ", "ா", "ி", "ீ", "ு", "ூ", "ெ", "ே", "ை", "ொ", "ோ", "ௌ", "்"]
        let consArr: [Character] = ["க", "ங", "ச", "ஜ", "ஞ", "ட", "த", "ந", "ண", "ன", "ப", "ம", "ய", "ர", "ற", "ல", "ள", "ழ", "வ", "ஷ", "ஸ", "ஹ"]
        let map: [Character: String] = [
            "அ": "a", "ஆ": "aa", "இ": "i", "ஈ": "ii", "உ": "u", "ஊ": "uu", "எ": "e", "ஏ": "ee", "ஐ": "ai", "ஒ": "o", "ஓ": "oo", "ஔ": "au", "க": "k", "ங": "ng", "ச": "c", "ஜ": "j", "ஞ": "nj", "ட": "tx", "த": "t", "ந": "nd", "ண": "nx", "ன": "n", "ப": "p", "ம": "m", "ய": "y", "ர": "r", "ற": "rx", "ல": "l", "ள": "lx", "ழ": "zh", "வ": "w", "ஷ": "sx", "ஸ": "s", "ஹ": "h", "ஃ": "f", "ா": "aa", "ி": "i", "ீ": "ii", "ு": "u", "ூ": "uu", "ெ": "e", "ே": "ee", "ை": "ai", "ொ": "o", "ோ": "oo", "ௌ": "au"
        ]
        var english = ""
        let phn = tamilText.unicodeScalars.map { Character($0) }        
        for i in 0..<phn.count {
            let char = phn[i]
            let nextChar = (i + 1 < phn.count) ? phn[i + 1] : " "
            
            if char == " " || char == "\t" || char == "\n" {
                english += " "
            } else {
                let isConsonant = consArr.contains(char)
                let isNextConsonant = consArr.contains(nextChar) || nextChar == " " || nextChar == "\t" || nextChar == "\n"
                
                if tamilArr.contains(char) {
                    if isConsonant && isNextConsonant {
                        english += (map[char] ?? "") + "a"
                    } else if char != "்" {
                        english += map[char] ?? ""
                    }
                } else {
                    english += String(char)
                }
            }
        }
        print("english: \(english)")
        return english
    }

    static func getLanguageCode(language: String) -> String {
        switch language {
        case "Tamil":
            return "ta-IN"
        case "English":
            return "en-IN"
        case "telugu":
            return "te-IN"
        case "hindi":
            return "hi-IN"
        case "kannada":
            return "kn-IN"
        case "french":
            return "fr-FR"
        case "arabic":
            return "ar-SA"
        case "chinese":
            return "zh-CN"
        case "german":
            return "de-DE"
        case "korean":
            return "ko-KR"
        case "malay":
            return "ms-IN"
        case "malayalam":
            return "ml-IN"  
        case "polish":
            return "pl-PL"
        case "russian":
            return "ru-RU"
        case "singalam":
            return "si-IN"
        case "swedish":
            return "sv-SE"
        default:        
            return "en-IN"
        }
    }

}