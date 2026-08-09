import Foundation
import AVFoundation
import CryptoKit

private final class TTSCache {
    static let shared = TTSCache()

    /// Maximum cache size in bytes (50 MB)
    private let maxCacheSize: Int = 50 * 1024 * 1024

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
        trimIfNeeded()
    }

    /// Removes oldest files when total cache exceeds the limit.
    private func trimIfNeeded() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }

        var totalSize = 0
        var entries: [(url: URL, date: Date, size: Int)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let date = values.contentModificationDate,
                  let size = values.fileSize else { continue }
            totalSize += size
            entries.append((url: file, date: date, size: size))
        }

        guard totalSize > maxCacheSize else { return }

        // Sort oldest first
        entries.sort { $0.date < $1.date }

        for entry in entries {
            guard totalSize > maxCacheSize else { break }
            try? fm.removeItem(at: entry.url)
            totalSize -= entry.size
        }
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
            try await playAudio(data: data)
        } catch {
            #if DEBUG
            print("⚠️ Audio playback failed for '\(word)': \(error.localizedDescription)")
            #endif
        }
    }

    func play(text: String, voiceKey: String) async {
        do {
            let data = try await fetchAudioData(for: text, voice: voiceKey)
            try await playAudio(data: data)
        } catch {
            #if DEBUG
            print("⚠️ Audio playback failed for '\(text)': \(error.localizedDescription)")
            #endif
        }
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
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(APIClient.appKey, forHTTPHeaderField: "X-App-Key")

        var body: [String: Any] = [
            "text": text,
            "voice": voice,
            "format": "mp3"
        ]
        // Tell the backend which language this is so TTS uses a native accent
        // (otherwise Japanese/etc. can be read with an English accent).
        if let language = UserDefaults.standard.string(forKey: "learningLanguage"), !language.isEmpty {
            body["language"] = language
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await APIClient.perform(request)
        let _ = try APIClient.validateResponse(data, response)

        TTSCache.shared.store(data: data, for: text, voice: voice)

        return data
    }

    private func fetchAudioData(for text: String) async throws -> Data {
        return try await fetchAudioData(for: text, voice: currentVoice)
    }

    /// Configures and activates the shared audio session off the main thread.
    /// `AVAudioSession.setActive(_:)` can block, so running it here (nonisolated,
    /// on the concurrent executor) avoids the main-thread UI unresponsiveness warning.
    private nonisolated func activateSession(mixWithOthers: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = mixWithOthers ? [.mixWithOthers] : []
        try session.setCategory(.playback, mode: .default, options: options)
        try session.setActive(true)
    }

    private func playAudio(data: Data) async throws {
        try await Task.detached { [self] in
            try activateSession(mixWithOthers: true)
        }.value

        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = effectiveRate
        player?.play()
    }

    private func playAudioSync(data: Data, rate: Float? = nil) async throws {
        try await Task.detached { [self] in
            try activateSession(mixWithOthers: false)
        }.value

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = rate ?? effectiveRate
        
        // Cancel any orphaned continuation from a previous rapid tap
        if let existing = playbackContinuation {
            playbackContinuation = nil
            existing.resume()
        }

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
