import Foundation
import AVFoundation
import Combine
import CryptoKit

private final class TTSCache {
    static let shared = TTSCache()

    private let maxCacheSize: Int = 50 * 1024 * 1024

    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("TTSAudioCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private func fileURL(text: String, voice: String, language: String) -> URL {
        let raw = "\(text)_\(voice)_\(language)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        let key = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent(key + ".mp3")
    }

    func contains(text: String, voice: String, language: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(text: text, voice: voice, language: language).path)
    }

    func cachedData(for text: String, voice: String, language: String) -> Data? {
        try? Data(contentsOf: fileURL(text: text, voice: voice, language: language))
    }

    func store(data: Data, for text: String, voice: String, language: String) {
        try? data.write(to: fileURL(text: text, voice: voice, language: language))
        trimIfNeeded()
    }

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

        entries.sort { $0.date < $1.date }

        for entry in entries {
            guard totalSize > maxCacheSize else { break }
            try? fm.removeItem(at: entry.url)
            totalSize -= entry.size
        }
    }
}

private struct PendingClip: Codable, Equatable {
    var text: String
    var language: String
}

@MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    private override init() {
        pendingClips = Self.loadClips(AppStorageKeys.ttsPrefetchPending)
        laterClips = Self.loadClips(AppStorageKeys.ttsPrefetchLater)
        super.init()
        pullLater()
        persistQueues()
        observeNetwork()
    }

    private var player: AVAudioPlayer?
    private let voiceKey = "ttsVoice"
    private let rateKey = "ttsRate"
    private var pendingClips: [PendingClip]
    private var laterClips: [PendingClip]
    private var failureCounts: [String: Int] = [:]
    private var inflight: [String: Task<Data, Error>] = [:]
    private var draining = false
    private let maxPending = 40
    private let maxLater = 80
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
        try Task.checkCancellation()
        let data = try await fetchAudioData(for: text)
        try Task.checkCancellation()
        try await playAudioSync(data: data, rate: rate)
    }

    func fetchTTS(for text: String) async throws -> Data {
        return try await fetchAudioData(for: text)
    }

    func hasCachedAudio(for text: String) -> Bool {
        let trimmed = Self.normalized(text)
        guard !trimmed.isEmpty else { return false }
        return TTSCache.shared.contains(
            text: trimmed,
            voice: currentVoice,
            language: Self.savedLanguage()
        )
    }

    func prefetch(text: String) {
        let trimmed = Self.normalized(text)
        guard !trimmed.isEmpty else { return }
        let clip = PendingClip(text: trimmed, language: Self.savedLanguage())
        if cached(clip) {
            pendingClips.removeAll { $0 == clip }
            laterClips.removeAll { $0 == clip }
            failureCounts[Self.clipKey(clip)] = nil
            persistQueues()
            return
        }
        failureCounts[Self.clipKey(clip)] = nil
        laterClips.removeAll { $0 == clip }
        if pendingClips.contains(clip) {
            persistQueues()
            drainPrefetch()
            return
        }
        if pendingClips.count >= maxPending {
            park(clip)
            return
        }
        pendingClips.append(clip)
        persistQueues()
        drainPrefetch()
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

    private func fetchAudioData(for text: String, voice: String, language clipLanguage: String? = nil) async throws -> Data {
        let trimmed = Self.normalized(text)
        guard !trimmed.isEmpty else { throw URLError(.badURL) }
        let language = clipLanguage ?? Self.savedLanguage()
        if let cached = TTSCache.shared.cachedData(for: trimmed, voice: voice, language: language) {
            return cached
        }

        let key = "\(trimmed)\u{1f}\(voice)\u{1f}\(language)"
        let task: Task<Data, Error>
        if let existing = inflight[key] {
            task = existing
        } else {
            task = Task {
                defer { self.inflight[key] = nil }
                return try await self.download(text: trimmed, voice: voice, language: language)
            }
            inflight[key] = task
        }
        return try await task.value
    }

    private func fetchAudioData(for text: String) async throws -> Data {
        try await fetchAudioData(for: text, voice: currentVoice)
    }

    private func download(text: String, voice: String, language: String) async throws -> Data {
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
        if !language.isEmpty {
            body["language"] = language
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await APIClient.perform(request)
        _ = try APIClient.validateResponse(data, response)
        guard data.count > 128 else {
            throw APIError.serverError(statusCode: 502, message: "Empty audio")
        }

        TTSCache.shared.store(data: data, for: text, voice: voice, language: language)
        return data
    }

    private func observeNetwork() {
        Task { @MainActor in
            var wasConnected = NetworkMonitor.shared.isConnected
            if wasConnected, !self.pendingClips.isEmpty {
                self.drainPrefetch()
            }
            for await connected in NetworkMonitor.shared.$isConnected.values {
                if connected && !wasConnected {
                    self.failureCounts.removeAll()
                    self.pullLater()
                    self.persistQueues()
                    self.drainPrefetch()
                }
                wasConnected = connected
            }
        }
    }

    private func drainPrefetch() {
        guard !draining else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        guard !pendingClips.isEmpty else { return }
        draining = true
        Task { @MainActor in
            await self.pumpPrefetch()
            self.draining = false
            if NetworkMonitor.shared.isConnected, !self.pendingClips.isEmpty {
                self.drainPrefetch()
            }
        }
    }

    private func pumpPrefetch() async {
        while NetworkMonitor.shared.isConnected, let clip = pendingClips.first {
            if cached(clip) {
                pendingClips.removeFirst()
                failureCounts[Self.clipKey(clip)] = nil
                pullLater()
                persistQueues()
                continue
            }
            do {
                _ = try await fetchAudioData(for: clip.text, voice: currentVoice, language: clip.language)
                failureCounts[Self.clipKey(clip)] = nil
                pendingClips.removeAll { $0 == clip }
                pullLater()
                persistQueues()
            } catch let error as APIError {
                if case .serverError(let code, _) = error, code == 400 {
                    pendingClips.removeAll { $0 == clip }
                    persistQueues()
                    continue
                }
                if case .serverError(let code, _) = error, code == 429 {
                    try? await Task.sleep(for: .seconds(20))
                    continue
                }
                if shouldRetry(clip) {
                    try? await Task.sleep(for: .seconds(6))
                    continue
                }
                park(clip)
                continue
            } catch is CancellationError {
                return
            } catch {
                if shouldRetry(clip) {
                    try? await Task.sleep(for: .seconds(6))
                    continue
                }
                park(clip)
                continue
            }
            if !pendingClips.isEmpty {
                try? await Task.sleep(for: .seconds(6))
            }
        }
    }

    private func cached(_ clip: PendingClip) -> Bool {
        TTSCache.shared.contains(text: clip.text, voice: currentVoice, language: clip.language)
    }

    private func shouldRetry(_ clip: PendingClip) -> Bool {
        let key = Self.clipKey(clip)
        let count = (failureCounts[key] ?? 0) + 1
        failureCounts[key] = count
        return count < 4
    }

    private func park(_ clip: PendingClip) {
        pendingClips.removeAll { $0 == clip }
        if !laterClips.contains(clip), laterClips.count < maxLater {
            laterClips.append(clip)
        }
        persistQueues()
    }

    private func pullLater() {
        while pendingClips.count < maxPending, !laterClips.isEmpty {
            let clip = laterClips.removeFirst()
            if pendingClips.contains(clip) { continue }
            if cached(clip) { continue }
            pendingClips.append(clip)
        }
    }

    private func persistQueues() {
        if let data = try? JSONEncoder().encode(pendingClips) {
            UserDefaults.standard.set(data, forKey: AppStorageKeys.ttsPrefetchPending)
        }
        if let data = try? JSONEncoder().encode(laterClips) {
            UserDefaults.standard.set(data, forKey: AppStorageKeys.ttsPrefetchLater)
        }
    }

    private static func loadClips(_ key: String) -> [PendingClip] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let clips = try? JSONDecoder().decode([PendingClip].self, from: data) else { return [] }
        return clips
    }

    private static func clipKey(_ clip: PendingClip) -> String {
        "\(clip.text)\u{1f}\(clip.language)"
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func savedLanguage() -> String {
        (UserDefaults.standard.string(forKey: "learningLanguage") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
        try Task.checkCancellation()
        try await Task.detached { [self] in
            try activateSession(mixWithOthers: false)
        }.value

        try Task.checkCancellation()

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
        player?.enableRate = true
        player?.rate = rate ?? effectiveRate
        let duration = max(player?.duration ?? 1.5, 0.4)

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
                return
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.6))
                if let pending = self.playbackContinuation {
                    self.playbackContinuation = nil
                    self.player?.stop()
                    self.player = nil
                    pending.resume()
                }
            }
        }

        try Task.checkCancellation()
    }
}
