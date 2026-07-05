import AVFoundation

/// Plays the tiny bundled WAV effects. All sounds respect the parent toggle.
final class SoundPlayer {
    static let shared = SoundPlayer()
    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        for name in ["tap", "pop", "fanfare", "no"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav"),
               let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[name] = p
            }
        }
    }

    func play(_ name: String, enabled: Bool) {
        guard enabled, let p = players[name] else { return }
        p.currentTime = 0
        p.play()
    }
}
