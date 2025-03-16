import AVFoundation

class AudioPlayer {
    static let shared = AudioPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
} 