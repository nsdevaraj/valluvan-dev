import AVFoundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var audioPlayers: [String: AVPlayer] = [:] 
    @Published private(set) var currentSong: String?
    @Published private(set) var isPlaying: Bool = false

    private init() {}

    func playAudio(for songName: String) {
        stopCurrentlyPlayingAudio()
        guard let url = URL(string: "https://raw.githubusercontent.com/nsdevaraj/valluvan/main/valluvan/Podcasts/\(songName).mp3") else { return }

        if let player = audioPlayers[songName] {
            currentSong = songName
            player.seek(to: .zero)
            player.play()
        } else {
            let player = AVPlayer(url: url)
            audioPlayers[songName] = player
            currentSong = songName
            player.play()
        }
        isPlaying = true
    }

    func pauseAudio(for songName: String) {
        if let player = audioPlayers[songName] {
            player.pause()
        }
        if currentSong == songName {
            currentSong = nil
            isPlaying = false
        }
    }

    func toggleAudio(for songName: String) {
        if let player = audioPlayers[songName] {
            if player.timeControlStatus == .playing {
                pauseAudio(for: songName)
            } else {
                playAudio(for: songName)
            }
        } else {
            playAudio(for: songName)
        }
    }
    
    private func stopCurrentlyPlayingAudio() {
        if let currentSong = currentSong {
            pauseAudio(for: currentSong)
        }
    }

    func getCurrentProgress() -> Double {
        guard let currentSong = currentSong,
              let player = audioPlayers[currentSong] else { return 0 }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
        return duration > 0 ? currentTime / duration : 0
    }

    func seek(to progress: Double) {
        guard let currentSong = currentSong,
              let player = audioPlayers[currentSong],
              let duration = player.currentItem?.duration else { return }
        
        let targetTime = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
        player.seek(to: targetTime)
    }
}
