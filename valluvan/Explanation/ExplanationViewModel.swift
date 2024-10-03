import SwiftUI
import AVFoundation

class ExplanationViewModel: ObservableObject {
    @Published var isFavorite = false
    @Published var isSpeaking = false
    @Published var showShareSheet = false
    private var audioManager = AudioManager.shared
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let kuralId: Int
    private let adhigaram: String
    private let adhigaramId: String
    private let lines: [String]
    private let explanation: String
    private let iyal: String
    @Published var relatedKurals: [DatabaseSearchResult] = []

    init(kuralId: Int, adhigaram: String, adhigaramId: String, lines: [String], explanation: String, iyal: String) {
        self.kuralId = kuralId
        self.adhigaram = adhigaram
        self.adhigaramId = adhigaramId
        self.lines = lines
        self.explanation = explanation
        self.iyal = iyal
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
        let favorite = Favorite(id: kuralId, adhigaram: adhigaram, adhigaramId: adhigaramId, lines: lines, iyal: iyal)
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

    func tamilSpeech(kuralId: Int) { 
       if  audioManager.isPlaying {
            audioManager.pauseAudio(for: "Kural/" + String(kuralId))
            isSpeaking = false
        } else { 
             audioManager.toggleAudio(for: "Kural/" +  String(kuralId))
             isSpeaking = true
        }
    }

    func toggleSpeech(selectedLanguage: String) {
        if isSpeaking {
            stopSpeech()
        } else {
            startSpeech(selectedLanguage: selectedLanguage)
        }
    }

    private func startSpeech(selectedLanguage: String) {
        let language = selectedLanguage
        let content = """
        \(adhigaram)
        \(lines.joined(separator: "\n"))
        """ 
        
        let langCode = LanguageUtil.getLanguageCode(language: language)
        let utterance = AVSpeechUtterance(string:content)
        
        utterance.voice = AVSpeechSynthesisVoice(language: langCode) 
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

    func fetchRelatedKurals() {
        Task {
            let related = DatabaseManager.shared.findRelatedKurals(for: kuralId)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.relatedKurals = related
            }
        }
    }
}
