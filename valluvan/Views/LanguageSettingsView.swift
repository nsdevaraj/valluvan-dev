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
    
    @StateObject private var audioManager = AudioManager.shared
    @State private var audioProgress: Double = 0.0
    @State private var isEditing = false

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
                        ForEach(["Virtue", "Wealth", "Love"], id: \.self) { songName in
                            HStack {
                                Image(systemName: "mic")
                                    .foregroundColor(.blue)
                                Text(songName)
                                    .foregroundColor(audioManager.currentSong == songName ? .green : .primary)
                                Spacer()
                                Button(action: {
                                    audioManager.toggleAudio(for: songName)
                                }) {
                                    Image(systemName: audioManager.currentSong == songName && audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        if audioManager.isPlaying, let currentSong = audioManager.currentSong {
                            VStack {
                                Text("Now Playing: \(currentSong)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Slider(value: $audioProgress, in: 0...1) { editing in
                                        isEditing = editing
                                        if !editing {
                                            audioManager.seek(to: audioProgress)
                                        }
                                    }
                                    Text(String(format: "%.1f%%", audioProgress * 100))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
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
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            if audioManager.isPlaying && !isEditing {
                audioProgress = audioManager.getCurrentProgress()
            }
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

}
