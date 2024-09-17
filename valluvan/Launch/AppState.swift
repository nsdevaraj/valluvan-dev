import SwiftUI

class AppState: ObservableObject {
    @AppStorage("fontSize") var fontSize: FontSize = .medium
    @AppStorage("isDailyKuralEnabled") var isDailyKuralEnabled: Bool = true
}

enum FontSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { self.rawValue }

    var textSizeCategory: ContentSizeCategory {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}