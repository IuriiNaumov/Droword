import Foundation
import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()
    private init() {}

    private var player: AVAudioPlayer?

    private let elevenLabsURL = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/MDLAMJ0jxkpYkjXbmG4t")!


    func play(word: String) async {
        print("AudioManager.play called with:", word)
        do {
            let data = try await fetchAudioData(for: word)
            print("AudioManager fetched data bytes:", data.count)
            try playAudio(data: data)
            print("AudioManager playback started")
        } catch {
            print("AudioManager error:", error)
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
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenLabs", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
        }
        if http.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("ElevenLabs HTTP error", http.statusCode, errorText)
            throw NSError(domain: "ElevenLabs", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        return data
    }

    private func playAudio(data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        do {
            player = try AVAudioPlayer(data: data)
            player?.prepareToPlay()
            let ok = player?.play() ?? false
            print("AVAudioPlayer started:", ok)
            if !ok {
                print("AVAudioPlayer failed to start playback")
            }
        } catch {
            print("AVAudioPlayer init/play error:", error)
            throw error
        }
    }
}
