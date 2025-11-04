import Foundation
import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()
    private init() {}

    private var player: AVAudioPlayer?

    private let elevenLabsURL = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/MDLAMJ0jxkpYkjXbmG4t")!
    private let apiKey = "sk_74ad1c950a9558250e576c5051863efb40250ec61111ae65"

    func play(word: String) async {
        do {
            let data = try await fetchAudioData(for: word)
            try playAudio(data: data)
        } catch {
        }
    }

    private func fetchAudioData(for text: String) async throws -> Data {
        var request = URLRequest(url: elevenLabsURL)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "voice_settings": [
                "stability": 0.4,
                "similarity_boost": 0.9
            ],
            "model_id": "eleven_multilingual_v2",
            "output_format": "mp3_44100_128"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ElevenLabs", code: 1, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        return data
    }

    private func playAudio(data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.play()
    }
}
