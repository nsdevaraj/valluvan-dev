import SwiftUI

struct HeaderView: View {
    let adhigaramId: String
    let adhigaram: String
    let kuralId: Int
    let iyal: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(adhigaramId)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(adhigaram)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Kural \(kuralId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(iyal)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct LinesView: View {
    let lines: [String]

    var body: some View {
        ForEach(lines, id: \.self) { line in
            Text(line)
                .font(.headline)
        }
    }
}

struct ExplanationTextView: View {
    let selectedLanguage: String
    let explanation: NSAttributedString

    var body: some View {
        VStack(alignment: .leading) {
            if selectedLanguage != "Tamil" {
                Text("Explanation:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
            }
            
            Text(AttributedString(explanation))
                .font(.body)
        }
    }
}

struct ToolbarView: View {
    @Binding var isFavorite: Bool
    @Binding var isSpeaking: Bool
    @Binding var showShareSheet: Bool
    let selectedLanguage: String
    let toggleFavorite: () -> Void
    let copyContent: () -> Void
    let toggleSpeech: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            Button(action: copyContent) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            if selectedLanguage == "English" {
                Button(action: toggleSpeech) {
                    Image(systemName: isSpeaking ? "pause.circle" : "play.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            Button(action: dismiss) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
        }
    }
}