import SwiftUI
import UIKit

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedPal: String
    let languages: [String] 
    let getCurrentTitle: (Int) -> String
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showFavorites = false
    @State private var podcastPlayingStates: [String: Bool] = [
        "Virtue": false,
        "Wealth": false,
        "Love": false
    ]

    static let languages: [(key: String, displayName: String)] = [
        ("Tamil", "தமிழ்"),
        ("English", "English"),
        ("telugu", "తెలుగు"),
        ("hindi", "हिन्दी"),
        ("kannad", "ಕನ್ನಡ"),
        ("french", "Français"),
        ("arabic", "العربية"),
        ("chinese", "中文"),
        ("german", "Deutsch"),
        ("korean", "한국어"),
        ("malay", "Bahasa Melayu"),
        ("malayalam", "മലയാളം"),
        ("polish", "Polski"),
        ("russian", "Русский"),
        ("singalam", "සිංහල"),
        ("swedish", "Svenska")
    ]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Font Size")) {
                    Picker("Font Size", selection: $appState.fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Notifications")) {
                    Toggle("Daily Thirukkural (9 AM)", isOn: $appState.isDailyKuralEnabled)
                }

                Section(header: Text("Podcasts")) {
                    DisclosureGroup("Podcast Mode") { 
                        HStack {
                            Image(systemName: "mic")
                                .foregroundColor(.blue)
                            Text("Virtue")
                                .foregroundColor(podcastPlayingStates["Virtue"] == true ? .green : .primary)
                            Spacer()
                            Button(action: {
                                togglePodcastPlayback(named: "Virtue")
                            }) {
                                Image(systemName: podcastPlayingStates["Virtue"] == true ? "pause.fill" : "play.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        HStack {
                            Image(systemName: "mic")
                                .foregroundColor(.blue)
                            Text("Wealth")
                                .foregroundColor(podcastPlayingStates["Wealth"] == true ? .green : .primary)
                            Spacer()
                            Button(action: {
                                togglePodcastPlayback(named: "Wealth")
                            }) {
                                Image(systemName: podcastPlayingStates["Wealth"] == true ? "pause.fill" : "play.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        HStack {
                            Image(systemName: "mic")
                                .foregroundColor(.blue)
                            Text("Love")
                                .foregroundColor(podcastPlayingStates["Love"] == true ? .green : .primary)
                            Spacer()
                            Button(action: {
                                togglePodcastPlayback(named: "Love")
                            }) {
                                Image(systemName: podcastPlayingStates["Love"] == true ? "pause.fill" : "play.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                Section(header: Text("About the Developer")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text("Devaraj NS")
                        Spacer()
                        Button(action: {
                            openURL("https://x.com/nsdevaraj")
                        }) {
                            Image(systemName: "bird")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            openURL("https://linkedin.com/in/nsdevaraj")
                        }) {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            openURL("https://github.com/nsdevaraj/valluvan")
                        }) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            sendFeedbackEmail()
                        }) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Section(header: Text("Language")) {
                    ForEach(Self.languages, id: \.key) { language in
                        Button(action: {
                            selectedLanguage = language.key
                            selectedPal = getCurrentTitle(0)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(language.displayName)
                                Spacer()
                                if language.key == selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16))
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                leading: HStack{
                    Button(action: { showFavorites = true }) {
                        HStack {
                            Image(systemName: "star.fill")
                        }
                    }
                },
                trailing: HStack {
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(isDarkMode ? .yellow : .primary)
                    }
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
            ) 
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .sheet(isPresented: $showFavorites) {
            FavoritesView(favorites: loadFavorites(), selectedLanguage: selectedLanguage)
                .environmentObject(appState)
        }
    }
    
    private func loadFavorites() -> [Favorite] {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
            return favorites
        }
        return []
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func sendFeedbackEmail() {
        let deviceInfo = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let emailSubject = "Valluvan App Feedback"
        let emailBody = "Device: \(deviceInfo)"
        
        let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "mailto:nsdevaraj@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func playSong(named songName: String) {
        AudioManager.shared.playAudio(for: songName)
    }
    
    private func togglePodcastPlayback(named songName: String) {
        AudioManager.shared.toggleAudio(for: songName)
        podcastPlayingStates[songName]?.toggle()

        
        if podcastPlayingStates[songName] == true {
            for (otherSong, isPlaying) in podcastPlayingStates {
                if otherSong != songName && isPlaying {
                    AudioManager.shared.pauseAudio(for: otherSong)
                    podcastPlayingStates[otherSong] = false
                }
            }
        }
    }
}
