import SwiftUI
import AVKit
import MediaPlayer
import AVFoundation
import Foundation

// Add this extension at the top of the file, outside of the AdhigaramView struct
extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}

struct AdhigaramView: View {
    let iyal: String
    let selectedLanguage: String
    let translatedIyal: String
    @State private var adhigarams: [String] = []
    @State private var originalAdhigarams: [String] = []
    @State private var kuralIds: [Int] = []
    @State private var adhigaramSongs: [String] = []
    @State private var expandedAdhigaram: String?
    @State private var allLines: [String: [[String]]] = [:]
    @State private var audioPlayers: [String: AVPlayer] = [:]
    @State private var playerItems: [String: AVPlayerItem] = [:]
    @State private var isPlaying: [String: Bool] = [:]
    @State private var selectedLinePair: SelectedLinePair?
    @EnvironmentObject var appState: AppState
    @State private var currentTime: [String: TimeInterval] = [:]
    @State private var duration: [String: TimeInterval] = [:]
    @State private var timer: Timer?
    @State private var playerObservers: [NSKeyValueObservation] = []
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @State private var shouldNavigateToContentView = false
    @Environment(\.presentationMode) var presentationMode
     

    var body: some View {
        List {
            ForEach(adhigarams.indices, id: \.self) { index in
                let adhigaram = adhigarams[index]
                let kuralId = kuralIds[index]
                let adhigaramId = String((kuralId + 9)/10)
                let adhigaramSong = adhigaramSongs[index]
                let originalAdhigaram = originalAdhigarams[index]
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 15) {
                        Text(adhigaramId)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(adhigaram)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: expandedAdhigaram == adhigaram ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if expandedAdhigaram == adhigaram {
                            expandedAdhigaram = nil
                        } else {
                            expandedAdhigaram = adhigaram
                            loadAllLines(for: originalAdhigaram)
                        }
                    }       
                    if expandedAdhigaram == adhigaram {
                        HStack(spacing: 5) {
                            Image(systemName: "music.note")
                                .foregroundColor(.blue)
                            Text(adhigaramSong)
                                .font(.subheadline)
                            Spacer()
                            Button(action: {
                                togglePlayPause(for: adhigaramSong, adhigaram: adhigaram, adhigaramId: adhigaramId)
                            }) {
                                Image(systemName: isPlaying[adhigaramSong] ?? false ? "pause.circle" : "play.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.leading, 0)
                        
                        if isPlaying[adhigaramSong] ?? false {
                            VStack(spacing: 5) {
                                Slider(value: Binding(
                                    get: { self.currentTime[adhigaramSong] ?? 0 },
                                    set: { newValue in
                                        self.currentTime[adhigaramSong] = newValue
                                        if let player = self.audioPlayers[adhigaramSong] {
                                            player.seek(to: CMTime(seconds: newValue, preferredTimescale: 1))
                                        }
                                    }
                                ), in: 0...(duration[adhigaramSong] ?? 0))
                                .accentColor(.blue)
                                
                                HStack {
                                    Text(timeString(from: currentTime[adhigaramSong] ?? 0))
                                    Spacer()
                                    Text(timeString(from: duration[adhigaramSong] ?? 0))
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.leading, 0)
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(allLines[originalAdhigaram] ?? [], id: \.self) { linePair in
                                LinePairView(
                                    linePair: linePair,
                                    onTap: { lines, kuralId in
                                        loadExplanation(for: adhigaram, lines: lines, kuralId: kuralId)
                                    }
                                )
                                .environmentObject(appState)
                            }
                        }
                        .padding(.leading, 0)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle(translatedIyal, displayMode: .inline)
        .onAppear {
            loadAdhigarams()            
        }
        .onDisappear {
            stopAllAudio()
        }
        .sheet(item: $selectedLinePair) { linePair in
            ExplanationView(
                adhigaram: linePair.adhigaram,
                adhigaramId: String((linePair.kuralId + 9) / 10),
                lines: linePair.lines,
                explanation: linePair.explanation,
                selectedLanguage: selectedLanguage,
                kuralId: linePair.kuralId,
                iyal: iyal,
                shouldNavigateToContentView: $shouldNavigateToContentView
            )
            .environmentObject(appState)
        }
        .onChange(of: shouldNavigateToContentView) { _, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
                shouldNavigateToContentView = false
            }
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
    
    private func loadAdhigarams() {
        let (adhigarams, kuralIds, adhigaramSongs, originalAdhigarams) = DatabaseManager.shared.getAdhigarams(for: iyal, language: selectedLanguage)
        
        Task {
            do {
                self.adhigarams = try await adhigarams.asyncMap { adhigaram in
                    try await TranslationUtil.getAdhigaramTranslation(for: adhigaram, to: selectedLanguage)
                }
                self.originalAdhigarams = originalAdhigarams
            } catch {
                print("Error translating adhigarams: \(error)")
                self.adhigarams = adhigarams // Fallback to untranslated adhigarams
            }
        }
        
        self.kuralIds = kuralIds
        self.adhigaramSongs = adhigaramSongs
    }
    
    private func loadAllLines(for adhigaram: String) {
        let supportedLanguages = ["English", "Tamil", "hindi", "telugu"]
        
        if supportedLanguages.contains(selectedLanguage) {
            let lines = DatabaseManager.shared.getFirstLine(for: adhigaram, language: selectedLanguage)
            let linePairs = stride(from: 0, to: lines.count, by: 2).map {
                Array(lines[$0..<min($0+2, lines.count)])
            }
            allLines[adhigaram] = linePairs
        } else {
            let lines = DatabaseManager.shared.getSingleLine(for: adhigaram, language: selectedLanguage)
            // Wrap each line in an array to make it a 2D array
            allLines[adhigaram] = lines.map { [$0] }
        } 
    }
    
    private func togglePlayPause(for adhigaramSong: String, adhigaram: String, adhigaramId: String) {
        stopAllAudioExcept(adhigaramSong)
        
        if let player = audioPlayers[adhigaramSong] {
            if player.timeControlStatus == .playing {
                player.pause()
                isPlaying[adhigaramSong] = false
                timer?.invalidate()
            } else {
                player.play()
                isPlaying[adhigaramSong] = true
                startTimer(for: adhigaramSong)
            }
        } else {
            if let url = URL(string: "https://raw.githubusercontent.com/nsdevaraj/valluvan/main/valluvan/Sounds/\(adhigaramSong.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? adhigaramSong).mp3") {
                let playerItem = AVPlayerItem(url: url)
                let player = AVPlayer(playerItem: playerItem)
                player.actionAtItemEnd = .none // Prevent playback from stopping at the end
                audioPlayers[adhigaramSong] = player
                playerItems[adhigaramSong] = playerItem
                
                // Observe the status of the player item
                let statusObserver = playerItem.observe(\.status) { item, change in
                    self.handlePlayerItemStatusChange(item: item, adhigaramSong: adhigaramSong)
                }
                
                // Observe the duration of the player item
                let durationObserver = playerItem.observe(\.duration) { item, change in
                    self.handlePlayerItemDurationChange(item: item, adhigaramSong: adhigaramSong)
                }
                
                playerObservers.append(contentsOf: [statusObserver, durationObserver])
                
                // Configure audio session for background playback
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to set audio session category.")
                }
                
                player.play()
                isPlaying[adhigaramSong] = true
                currentTime[adhigaramSong] = 0
                startTimer(for: adhigaramSong)
                
                // Set up remote control events and Now Playing info
                setupRemoteTransportControls()
                setupNowPlayingInfo(adhigaram: adhigaram, adhigaramId: adhigaramId)
                
                // Start background task
                startBackgroundTask()
            } else {
                print("Audio file not found: \(adhigaramSong).mp3")
            }
        }
    }

    private func handlePlayerItemStatusChange(item: AVPlayerItem, adhigaramSong: String) {
        switch item.status {
        case .readyToPlay:
            print("Player item is ready to play")
        case .failed:
            print("Player item failed. Error: \(String(describing: item.error))")
        case .unknown:
            print("Player item is not yet ready")
        @unknown default:
            print("Unknown player item status")
        }
    }

    private func handlePlayerItemDurationChange(item: AVPlayerItem, adhigaramSong: String) {
        let duration = item.duration
        self.duration[adhigaramSong] = CMTimeGetSeconds(duration)
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { event in
            self.resumePlayback()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { event in
            self.pausePlayback()
            return .success
        }
         
    }

    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func resumePlayback() {
        for (adhigaram, player) in audioPlayers {
            player.play()
            isPlaying[adhigaram] = true
        }
    }

    private func pausePlayback() {
        for (adhigaram, player) in audioPlayers {
            player.pause()
            isPlaying[adhigaram] = false
        }
    }
    
    private func startTimer(for adhigaramSong: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let player = audioPlayers[adhigaramSong] {
                currentTime[adhigaramSong] = CMTimeGetSeconds(player.currentTime())
            }
        }
    }
    
    private func stopAllAudioExcept(_ exceptSong: String) {
        for (song, player) in audioPlayers {
            if song != exceptSong {
                player.pause()
                isPlaying[song] = false
                timer?.invalidate()
            }
        }
    }
    
    private func stopAllAudio() {
        for player in audioPlayers.values {
            player.pause()
        }
        audioPlayers.removeAll()
        playerItems.removeAll()
        isPlaying.removeAll()
        currentTime.removeAll()
        duration.removeAll()
        timer?.invalidate()
        
        // Remove all observers
        playerObservers.forEach { $0.invalidate() }
        playerObservers.removeAll()
        
        endBackgroundTask()
    }
    
    private func loadExplanation(for adhigaram: String, lines: [String], kuralId: Int) {
        let explanation = DatabaseManager.shared.getExplanation(for: kuralId, language: selectedLanguage)
        selectedLinePair = SelectedLinePair(adhigaram: adhigaram, lines: lines, explanation: explanation, kuralId: kuralId)
    }
     
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func setupNowPlayingInfo(adhigaram: String, adhigaramId: String) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = adhigaram
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Thirukkural"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Adhigaram \(adhigaramId)"

        // Set artwork image
        if let image = UIImage(named: "thirukkural_icon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

}
