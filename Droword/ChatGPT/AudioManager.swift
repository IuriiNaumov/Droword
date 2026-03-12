import Foundation
import AVFoundation

@MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    private override init() { super.init() }

    private var player: AVAudioPlayer?
    private let voiceKey = "ttsVoice"
    private let rateKey = "ttsRate"
    var currentVoice: String {
        UserDefaults.standard.string(forKey: voiceKey) ?? "coral"
    }

    var currentRate: Float {
        let val = UserDefaults.standard.double(forKey: rateKey)
        return val == 0 ? 1.0 : Float(val)
    }

    private let openAITTSEndpoint = URL(string: "https://api.openai.com/v1/audio/speech")!


    private var playbackContinuation: CheckedContinuation<Void, Never>?

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
  
    func play(text: String, voiceKey: String) async {
        print("AudioManager.preview called with:", text, "voice:", voiceKey)
        do {
            let data = try await fetchAudioData(for: text, voice: voiceKey)
            print("AudioManager preview fetched data bytes:", data.count)
            try playAudio(data: data)
            print("AudioManager preview playback started")
        } catch {
            print("AudioManager preview error:", error)
        }
    }

    func playAndWait(text: String, rate: Float? = nil) async throws {
        let data = try await fetchAudioData(for: text)
        try await playAudioSync(data: data, rate: rate)
    }

    /// Fetches TTS audio data without playing it
    func fetchTTS(for text: String) async throws -> Data {
        return try await fetchAudioData(for: text)
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        if let cont = playbackContinuation {
            playbackContinuation = nil
            cont.resume()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if let cont = self.playbackContinuation {
                self.playbackContinuation = nil
                cont.resume()
            }
        }
    }
    
    private func fetchAudioData(for text: String, voice: String) async throws -> Data {
        var request = URLRequest(url: openAITTSEndpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "input": text,
            "voice": voice,
            "format": "mp3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
        }
        if http.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenAI HTTP error", http.statusCode, errorText)
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }

        return data
    }

    private func fetchAudioData(for text: String) async throws -> Data {
        var request = URLRequest(url: openAITTSEndpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "input": text,
            "voice": currentVoice,
            "format": "mp3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
        }
        if http.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenAI HTTP error", http.statusCode, errorText)
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
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
            player?.enableRate = true
            player?.rate = currentRate
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

    private func playAudioSync(data: Data, rate: Float? = nil) async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = rate ?? currentRate
        
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.playbackContinuation = cont
            let ok = player?.play() ?? false
            if !ok {
                self.playbackContinuation = nil
                cont.resume()
            }
        }
    }
}

