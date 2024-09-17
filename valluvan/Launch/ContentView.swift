//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import Intents
import IntentsUI
import NaturalLanguage

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let audioPath: String
}

struct SelectedLinePair: Identifiable {
    let id = UUID()
    let adhigaram: String
    let lines: [String]
    let explanation: NSAttributedString
    let kuralId: Int
}

struct Favorite: Codable, Identifiable {
    let id: Int
    let adhigaram: String
    let adhigaramId: String
    let lines: [String]
}

struct ContentView: View {
    @State private var selectedPal: String
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = LanguageSettingsView.languages[0].key
    @State private var isExpanded: Bool = false
    @State private var iyal: String = ""  
    
    @State private var searchText = ""
    @State private var searchResults: [DatabaseSearchResult] = []
    @State private var isShowingSearchResults = false
    @State private var selectedSearchResult: DatabaseSearchResult? 
    @State private var hasSearched = false
    
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]
    @State private var showFavorites = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showGoToKural = false
    @State private var goToKuralId = ""
    @EnvironmentObject var appState: AppState
    @State private var selectedNotificationKuralId: Int?
    @State private var showExplanationView = false
    @Environment(\.notificationKuralId) var notificationKuralId: Binding<Int?>

    @State private var isSearching = false
    @State private var translatedIyals: [String: String] = [:]
    @State private var siriShortcutProvider: INVoiceShortcutCenter?
    @State private var shouldNavigateToContentView = false

    @State private var isSearchResultsReady = false
    @State private var originalSearchText = ""

    init() {
        // Initialize selectedPal with the first pal title
        let initialPal = LanguageUtil.getCurrentTitle(0, for: "Tamil")
        _selectedPal = State(initialValue: initialPal)
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    SearchBarView(
                        searchText: $searchText,
                        isSearching: $isSearching,
                        searchResults: $searchResults,
                        isShowingSearchResults: $isShowingSearchResults,
                        performSearch: performSearch
                    )
                    
                    Divider()
                    
                    MainContentView(
                        iyals: iyals,
                        selectedLanguage: selectedLanguage,
                        translatedIyals: translatedIyals,
                        appState: _appState
                    )
                    
                    Divider()
                    
                    BottomBarView(selectedPal: $selectedPal, selectedLanguage: selectedLanguage)
                }
            }
            .navigationBarTitle("Valluvan", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems, trailing: trailingBarItems)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onAppear(perform: onAppearActions)
        .onChange(of: selectedPal) { oldValue, newValue in
            Task {
                await loadIyals()
            }
            translateIyals()
        }
        .onChange(of: selectedLanguage) { oldValue, newValue in
            updateSelectedPal()
            translateIyals()
        }
        .onChange(of: shouldNavigateToContentView) { oldValue, newValue in
            if newValue {
                shouldNavigateToContentView = false
            }
        }
        .sheet(isPresented: $isShowingSearchResults, content: searchResultsSheet)
        .sheet(item: $selectedSearchResult, content: explanationSheet)
        .sheet(isPresented: $showFavorites, content: favoritesSheet)
        .sheet(isPresented: $showGoToKural, content: goToKuralSheet)
        .sheet(isPresented: $showLanguageSettings, content: languageSettingsSheet)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { notification in
            Task {
                await handleAppBecomeActive()
            }
        }
        .sheet(isPresented: $showExplanationView, content: explanationViewSheet)
        .task {
            await loadIyalsTask()
        }
    }

    private func getCurrentTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: selectedLanguage)
    }
    
    private var leadingBarItems: some View {
        HStack {
            Button(action: { showGoToKural = true }) {
                Image(systemName: "arrow.right.circle")
            }
            Button(action: toggleLanguage) {
                Image(systemName: selectedLanguage == "Tamil" ? "a.circle.fill":"pencil.circle.fill" )
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var trailingBarItems: some View {
        HStack {
            Button(action: { showFavorites = true }) {
                Image(systemName: "star.fill")
            }
            Button(action: { showLanguageSettings = true }) {
                Image(systemName: "globe")
            }
        }
    }
    
    private func getCurrentEnglishTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: "English")
    }
    
    private func updateSelectedPal() {
        if let index = LanguageUtil.tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
        } else {
            selectedPal = getCurrentTitle(0)
        }
    }
    
    func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            isShowingSearchResults = false
            isSearchResultsReady = false
            return
        }
        
        isSearching = true
        isSearchResultsReady = false
        
        originalSearchText = searchText  // Store the original search text
        // Remove all special characters from searchText
        searchText = searchText.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ").inverted).joined()
        // Split the search text into words
        let words = searchText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Identify nouns and pick random nouns (up to 3) if there are multiple words
        let searchQuery: String
        if words.count > 1 {
            let nouns = words.filter { word in
                let tagger = NLTagger(tagSchemes: [.nameType])
                tagger.string = word
                let (tag, _) = tagger.tag(at: word.startIndex, unit: .word, scheme: .nameType)
                return tag != .personalName || tag == .placeName || tag == .organizationName
            }
            
            if !nouns.isEmpty {
                let randomNouns = nouns.shuffled().prefix(min(3, nouns.count))
                searchQuery = randomNouns[0]
            } else {
                // If no nouns found, use the original logic
                let randomWords = words.shuffled().prefix(min(3, words.count))
                searchQuery = randomWords[0]
            }
        } else {
            searchQuery = searchText
        }
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let results: [DatabaseSearchResult]
            if self.selectedLanguage == "Tamil" { 
                results = self.searchTamilContent(query: searchQuery)
            } else { 
                results = self.searchContent(query: searchQuery)
            } 
            print("results: \(searchQuery)")
            if results.count == 0 {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "No Results", message: "No kural, found for '\(self.originalSearchText)'", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(alert, animated: true, completion: nil)
                    }
                }
            }
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
                self.hasSearched = true
                self.isShowingSearchResults = !results.isEmpty
                
                // Add a small delay before setting isSearchResultsReady to true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isSearchResultsReady = true
                }
            }
        }
    }

    func searchContent(query: String) -> [DatabaseSearchResult] {
        let databaseResults = DatabaseManager.shared.searchContent(query: query, language: selectedLanguage)
        return databaseResults.map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
    }

    func searchTamilContent(query: String) -> [DatabaseSearchResult] {
        let databaseResults = DatabaseManager.shared.searchTamilContent(query: query)
        return databaseResults.map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
    }

    private func loadFavorites() -> [Favorite] {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
            return favorites
        }
        return []
    }

    private func goToKural() {
        if let kuralId = Int(goToKuralId), (1...1330).contains(kuralId) {
            let result = DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage)
            if let result = result {
                selectedSearchResult = DatabaseSearchResult(
                    heading: result.heading,
                    subheading: result.subheading,
                    content: result.content,
                    explanation: result.explanation,
                    kuralId: result.kuralId
                )
            }
        }
        showGoToKural = false
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

    private func toggleLanguage() {
        switch selectedLanguage {
        case "Tamil":
            selectedLanguage = "English"
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "English")
        case "English":
            selectedLanguage = "Tamil"
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "Tamil")
        default:
            selectedLanguage = "Tamil"
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "English")
        } 
        updateSelectedPal()
    }

    private func translateIyals() {
        guard selectedLanguage != "Tamil" else {
            translatedIyals = [:]
            return
        }
        
        Task {
            for iyal in iyals {
                do {
                    let translated = try await TranslationUtil.getTranslation(for: iyal, to: selectedLanguage)
                    DispatchQueue.main.async {
                        self.translatedIyals[iyal] = translated
                    }
                } catch {
                    print("Error translating iyal: \(error)")
                    DispatchQueue.main.async {
                        self.translatedIyals[iyal] = iyal // Fallback to original text if translation fails
                    }
                }
            }
        }
    }

    private func setupSiriShortcut() {
        let intent = INIntent()
        intent.suggestedInvocationPhrase = "Go to Kural"

        _ = INShortcut(intent: intent)
        siriShortcutProvider = INVoiceShortcutCenter.shared

    }

    func handleSiriGoToKural(kuralId: Int) {
        goToKuralId = String(kuralId)
        goToKural()
    }

    @ViewBuilder
    private func searchResultsSheet() -> some View {
        SearchResultsView(
            results: searchResults,
            originalSearchText: originalSearchText,
            onSelectResult: { result in
                selectedSearchResult = result
                isShowingSearchResults = false
            }
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func explanationSheet(_ result: DatabaseSearchResult) -> some View {
        ExplanationView(
            adhigaram: result.subheading,
            adhigaramId: String((result.kuralId + 9) / 10),
            lines: [result.content],
            explanation: NSAttributedString(string: result.explanation),
            selectedLanguage: selectedLanguage,
            kuralId: result.kuralId,
            iyal: "",
            shouldNavigateToContentView: $shouldNavigateToContentView
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func favoritesSheet() -> some View {
        FavoritesView(favorites: loadFavorites(), selectedLanguage: selectedLanguage)
            .environmentObject(appState)
    }

    @ViewBuilder
    private func goToKuralSheet() -> some View {
        GoToKuralView(isPresented: $showGoToKural, kuralId: $goToKuralId, onSubmit: goToKural)
            .environmentObject(appState)
    }

    @ViewBuilder
    private func languageSettingsSheet() -> some View {
        LanguageSettingsView(
            selectedLanguage: $selectedLanguage,
            selectedPal: $selectedPal,
            languages: LanguageSettingsView.languages.map { $0.key },
            getCurrentTitle: getCurrentTitle
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func explanationViewSheet() -> some View {
        if let result = selectedSearchResult {
            ExplanationView(
                adhigaram: result.subheading,
                adhigaramId: String((result.kuralId + 9) / 10),
                lines: [result.content],
                explanation: NSAttributedString(string: result.explanation),
                selectedLanguage: selectedLanguage,
                kuralId: result.kuralId,
                iyal: "",
                shouldNavigateToContentView: $shouldNavigateToContentView
            )
            .environmentObject(appState)
        }
    }

    private func onAppearActions() {
        Task {
            await loadIyals()
            translateIyals()
        }
        setupSiriShortcut()
    }

    private func handleAppBecomeActive() async {
        if let kuralId = notificationKuralId.wrappedValue {
            if let result = await DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage) {
                await MainActor.run {
                    selectedSearchResult = result
                    showExplanationView = true
                }
            }
            await MainActor.run {
                notificationKuralId.wrappedValue = nil
            }
        }
    }

    @Sendable
    private func loadIyalsTask() async {
        await loadIyals()
    }

    private func loadIyals() async { 
        iyals = await DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
    }
}
 

#Preview {
    ContentView()
}
