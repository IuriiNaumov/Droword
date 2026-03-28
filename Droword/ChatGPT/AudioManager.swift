import Foundation
import AVFoundation
import CryptoKit

private final class TTSCache {
    static let shared = TTSCache()

    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("TTSAudioCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private func cacheKey(text: String, voice: String) -> String {
        let raw = "\(text)_\(voice)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func cachedData(for text: String, voice: String) -> Data? {
        let key = cacheKey(text: text, voice: voice)
        let fileURL = cacheDir.appendingPathComponent(key + ".mp3")
        return try? Data(contentsOf: fileURL)
    }

    func store(data: Data, for text: String, voice: String) {
        let key = cacheKey(text: text, voice: voice)
        let fileURL = cacheDir.appendingPathComponent(key + ".mp3")
        try? data.write(to: fileURL)
    }
}

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

    var overrideRate: Float? = nil

    var effectiveRate: Float {
        overrideRate ?? currentRate
    }

    private var ttsEndpoint: URL { URL(string: "\(APIClient.baseURL)/tts")! }

    private var playbackContinuation: CheckedContinuation<Void, Never>?

    func play(word: String) async {
        do {
            let data = try await fetchAudioData(for: word)
            try playAudio(data: data)
        } catch { }
    }

    func play(text: String, voiceKey: String) async {
        do {
            let data = try await fetchAudioData(for: text, voice: voiceKey)
            try playAudio(data: data)
        } catch { }
    }

    func playAndWait(text: String, rate: Float? = nil) async throws {
        let data = try await fetchAudioData(for: text)
        try await playAudioSync(data: data, rate: rate)
    }

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
        if let cached = TTSCache.shared.cachedData(for: text, voice: voice) {
            return cached
        }

        var request = URLRequest(url: ttsEndpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(APIClient.appKey, forHTTPHeaderField: "X-App-Key")

        let body: [String: Any] = [
            "text": text,
            "voice": voice,
            "format": "mp3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
        }
        if http.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TTS", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }

        TTSCache.shared.store(data: data, for: text, voice: voice)

        return data
    }

    private func fetchAudioData(for text: String) async throws -> Data {
        return try await fetchAudioData(for: text, voice: currentVoice)
    }

    private func playAudio(data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = effectiveRate
        player?.play()
    }

    private func playAudioSync(data: Data, rate: Float? = nil) async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = rate ?? effectiveRate
        
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
