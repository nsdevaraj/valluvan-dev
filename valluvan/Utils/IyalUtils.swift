import SwiftUI

enum IyalUtils {
    static func getSystemImageForIyal(_ iyal: String) -> String {
        switch iyal {
        case "Preface", "பாயிரவியல்":
            return "book.fill"
        case "Domestic Virtue", "இல்லறவியல்":
            return "house.fill"
        case "Ascetic Virtue", "துறவறவியல்":
            return "leaf.fill"
        case "Royalty", "அரசியல்":
            return "crown.fill"
        case "Ministry", "அமைச்சியல்":
            return "briefcase.fill"
        case "Politics", "அரணியல்":
            return "building.columns.fill"
        case "Friendship", "நட்பியல்":
            return "person.2.fill"
        case "Miscellaneous":
            return "square.grid.2x2.fill"
        case "கூழியல்", "pulp":
            return "cup.and.saucer.fill"
        case "படையில்", "army":
            return "shield.fill"
        case "குடியியல்", "civility":
            return "person.3.fill"
        case "Pre-marital love", "களவியல்":
            return "heart.fill"
        case "Post-marital love", "கற்பியல்":
            return "heart.circle.fill"
        default:
            return "circle.fill"
        }
    }
}