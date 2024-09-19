import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioPlayers: [String: AVPlayer] = [:] 

    private init() {}
    private var currentSong:String?
    func playAudio(for songName: String) {
        stopCurrentlyPlayingAudio()
        guard let url = URL(string: "https://raw.githubusercontent.com/nsdevaraj/valluvan/main/valluvan/Podcasts/\(songName).mp3") else { return }

        if let player = audioPlayers[songName] {
            currentSong = songName
            player.play()
        } else {
            let player = AVPlayer(url: url)
            audioPlayers[songName] = player
            currentSong = songName
            player.play()
        } 
    }

    func pauseAudio(for songName: String) {
        if let player = audioPlayers[songName] {
            player.pause()
        } 
    }

    func toggleAudio(for songName: String) {
        if let player = audioPlayers[songName] {
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                currentSong = songName
                player.play()
            }
        } else {
            currentSong = songName
            playAudio(for: songName)
        }
    }
    
    private func stopCurrentlyPlayingAudio() {
        pauseAudio(for: currentSong ?? "")
    }
}
