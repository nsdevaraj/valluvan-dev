import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioPlayers: [String: AVPlayer] = [:]

    private init() {}

    func playAudio(for songName: String) {
        let songMap: [String: String] = [
            "Virtue": "Virtue.mp3",
            "Wealth": "Wealth.mp3",
            "Love": "Love.mp3"
        ]

        guard let fileName = songMap[songName],
              let url = URL(string: "https://raw.githubusercontent.com/nsdevaraj/valluvan/main/valluvan/Podcasts/\(fileName)") else { return }

        if let player = audioPlayers[songName] {
            player.play()
        } else {
            let player = AVPlayer(url: url)
            audioPlayers[songName] = player
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
                player.play()
            }
        } else {
            playAudio(for: songName)
        }
    }
}
