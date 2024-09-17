import SwiftUI

struct MainContentView: View {
    let iyals: [String]
    let selectedLanguage: String
    let translatedIyals: [String: String]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if iyals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Please select a chapter from the bottom bar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(iyals, id: \.self) { iyal in
                        NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage, translatedIyal: translatedIyals[iyal] ?? iyal).environmentObject(appState)) {
                            IyalCard(iyal: iyal, translatedIyal: translatedIyals[iyal] ?? iyal, selectedLanguage: selectedLanguage)
                        }
                    }
                }
            }
            .padding()
        }
    }
}