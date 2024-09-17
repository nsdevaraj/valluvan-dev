import SwiftUI

struct PalButton: View {
    let title: String
    let query: String
    let systemImage: String
    let selectedLanguage: String
    @Binding var selectedPal: String
    
    var body: some View {
        Button(action: {
            selectedPal = selectedLanguage == "Tamil" ? title : query
        }) {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedPal == (selectedLanguage == "Tamil" ? title : query) ? .blue : .gray)
        }
    }
}