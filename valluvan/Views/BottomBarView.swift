import SwiftUI

struct BottomBarView: View {
    @Binding var selectedPal: String
    let selectedLanguage: String

    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                PalButton(
                    title: getCurrentTitle(index),
                    query: getCurrentEnglishTitle(index),
                    systemImage: getSystemImage(for: index),
                    selectedLanguage: selectedLanguage,
                    selectedPal: $selectedPal
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func getCurrentTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: selectedLanguage)
    }

    private func getCurrentEnglishTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: "English")
    }

    private func getSystemImage(for index: Int) -> String {
        switch index {
        case 0:
            return "peacesign"
        case 1:
            return "dollarsign.circle"
        case 2:
            return "heart.circle"
        default:
            return "\(index + 1).circle"
        }
    }
}