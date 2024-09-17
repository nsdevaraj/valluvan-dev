import SwiftUI
import AVFoundation

class ExplanationViewModel: ObservableObject {
    @Published var isFavorite = false
    @Published var isSpeaking = false
    @Published var showShareSheet = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let kuralId: Int
    private let adhigaram: String
    private let adhigaramId: String
    private let lines: [String]
    private let explanation: String

    init(kuralId: Int, adhigaram: String, adhigaramId: String, lines: [String], explanation: String) {
        self.kuralId = kuralId
        self.adhigaram = adhigaram
        self.adhigaramId = adhigaramId
        self.lines = lines
        self.explanation = explanation
        checkIfFavorite()
    }

    func checkIfFavorite() {
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
                isFavorite = favorites.contains { $0.id == kuralId }
            }
        }
    }

    func toggleFavorite() {
        if isFavorite {
            removeFavorite()
        } else {
            addFavorite()
        }
        isFavorite.toggle()
    }

    private func addFavorite() {
        let favorite = Favorite(id: kuralId, adhigaram: adhigaram, adhigaramId: adhigaramId, lines: lines)
        var favorites: [Favorite] = []
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if let decoded = try? JSONDecoder().decode([Favorite].self, from: data) {
                favorites = decoded
            }
        }
        favorites.append(favorite)
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    private func removeFavorite() {
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if var favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
                favorites.removeAll { $0.id == kuralId }
                if let encoded = try? JSONEncoder().encode(favorites) {
                    UserDefaults.standard.set(encoded, forKey: "favorites")
                }
            }
        }
    }

    func toggleSpeech() {
        if isSpeaking {
            stopSpeech()
        } else {
            startSpeech()
        }
    }

    private func startSpeech() {
        let content = """
        \(adhigaram)
        \(lines.joined(separator: "\n"))
        \(explanation)
        """
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }

    func stopSpeech() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func copyContent() {
        let content = getShareContent()
        #if os(iOS)
        UIPasteboard.general.string = content
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #endif
    }

    func getShareContent() -> String {
        """
        Kural \(kuralId)
        \(adhigaramId) \(adhigaram)
        \(lines.joined(separator: "\n"))
        Explanation:
        \(explanation)
        """
    }
}