import Foundation
import AVFoundation
import Combine
import MediaPlayer

struct ListeningSettings {
    var pauseDuration: Double = 3.0
    var includeExamples: Bool = true
    var nativeFirst: Bool = false
    var shuffle: Bool = true
    var repeatCount: Int = 1
    var sleepTimerMinutes: Int = 0

    private static let pauseKey = "listening.pauseDuration"
    private static let examplesKey = "listening.includeExamples"
    private static let nativeFirstKey = "listening.nativeFirst"
    private static let shuffleKey = "listening.shuffle"
    private static let repeatKey = "listening.repeatCount"
    private static let sleepKey = "listening.sleepTimerMinutes"

    func save() {
        let d = UserDefaults.standard
        d.set(pauseDuration, forKey: Self.pauseKey)
        d.set(includeExamples, forKey: Self.examplesKey)
        d.set(nativeFirst, forKey: Self.nativeFirstKey)
        d.set(shuffle, forKey: Self.shuffleKey)
        d.set(repeatCount, forKey: Self.repeatKey)
        d.set(sleepTimerMinutes, forKey: Self.sleepKey)
    }

    static func load() -> ListeningSettings {
        let d = UserDefaults.standard
        var s = ListeningSettings()
        if d.object(forKey: pauseKey) != nil { s.pauseDuration = d.double(forKey: pauseKey) }
        s.includeExamples = d.object(forKey: examplesKey) != nil ? d.bool(forKey: examplesKey) : true
        s.nativeFirst = d.bool(forKey: nativeFirstKey)
        s.shuffle = d.object(forKey: shuffleKey) != nil ? d.bool(forKey: shuffleKey) : true
        if d.object(forKey: repeatKey) != nil { s.repeatCount = max(1, d.integer(forKey: repeatKey)) }
        s.sleepTimerMinutes = d.integer(forKey: sleepKey)
        return s
    }
}

enum ListeningPhase: Equatable {
    case word
    case pause
    case translation
    case example
    case gap
}

@MainActor
final class ListeningSessionManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentWordIndex = 0
    @Published var currentPhase: ListeningPhase = .word
    @Published var currentWord: StoredWord?
    @Published var settings = ListeningSettings.load()
    @Published var totalWords = 0
    @Published var sleepTimerRemaining: Int = 0
    @Published var isSessionComplete = false

    private var queue: [StoredWord] = []
    private var sessionTask: Task<Void, Never>?
    private var sleepTimerTask: Task<Void, Never>?
    private var pauseContinuation: CheckedContinuation<Void, Never>?

    func startSession(words: [StoredWord], filterTag: String?) {
        stop()

        isSessionComplete = false

        var filtered = words
        if let tag = filterTag, !tag.isEmpty {
            filtered = words.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(tag) == .orderedSame
            }
        }

        guard !filtered.isEmpty else { return }

        var expanded: [StoredWord] = []
        for _ in 0..<settings.repeatCount {
            expanded.append(contentsOf: filtered)
        }
        if settings.shuffle { expanded.shuffle() }

        queue = expanded
        totalWords = expanded.count
        currentWordIndex = 0
        isPlaying = true
        isPaused = false

        setupNowPlayingInfo()
        setupRemoteCommands()

        if settings.sleepTimerMinutes > 0 {
            startSleepTimer(minutes: settings.sleepTimerMinutes)
        }

        sessionTask = Task { await runSession() }
    }

    func stop() {
        sessionTask?.cancel()
        sessionTask = nil
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        AudioManager.shared.stopPlayback()
        isPlaying = false
        isPaused = false
        currentWord = nil
        sleepTimerRemaining = 0
        resumeIfPaused()
        clearNowPlaying()
    }

    func togglePause() {
        if isPaused {
            isPaused = false
            resumeIfPaused()
        } else {
            isPaused = true
            AudioManager.shared.stopPlayback()
        }
    }

    func skipForward() {
        let nextIndex = currentWordIndex + 1
        if nextIndex >= queue.count {
            stop()
            isSessionComplete = true
            return
        }
        restartSession(at: nextIndex)
    }

    func skipBackward() {
        let prevIndex = max(0, currentWordIndex - 1)
        restartSession(at: prevIndex)
    }

    func updateSettings(_ newSettings: ListeningSettings) {
        settings = newSettings
        settings.save()
    }

    private func restartSession(at index: Int) {
        sessionTask?.cancel()
        sessionTask = nil
        AudioManager.shared.stopPlayback()
        resumeIfPaused()
        isPaused = false

        currentWordIndex = index
        sessionTask = Task { await runSession() }
    }

    private func runSession() async {
        while currentWordIndex < queue.count {
            if Task.isCancelled { break }

            let word = queue[currentWordIndex]
            currentWord = word
            updateNowPlaying(word: word)

            do {
                let foreignText = word.word
                let nativeText = word.translation ?? ""

                let firstText: String
                let secondText: String

                if settings.nativeFirst {
                    firstText = nativeText
                    secondText = foreignText
                } else {
                    firstText = foreignText
                    secondText = nativeText
                }

                currentPhase = .word
                try Task.checkCancellation()
                try await waitIfPaused()
                try await AudioManager.shared.playAndWait(text: firstText)

                currentPhase = .pause
                try Task.checkCancellation()
                try await waitIfPaused()
                try await sleepFor(settings.pauseDuration)

                currentPhase = .translation
                try Task.checkCancellation()
                try await waitIfPaused()
                if !secondText.isEmpty {
                    try await AudioManager.shared.playAndWait(text: secondText)
                }

                if settings.includeExamples, let example = word.example, !example.isEmpty {
                    currentPhase = .example
                    try Task.checkCancellation()
                    try await waitIfPaused()
                    try await sleepFor(0.8)
                    try await AudioManager.shared.playAndWait(text: example)
                }

                currentPhase = .gap
                try Task.checkCancellation()
                try await sleepFor(1.5)

            } catch is CancellationError {
                break
            } catch {
                print("ListeningSession error:", error)
            }

            currentWordIndex += 1
        }

        if !Task.isCancelled {
            AudioManager.shared.stopPlayback()
            isPlaying = false
            currentWord = nil
            isSessionComplete = true
            clearNowPlaying()
        }
    }

    private func waitIfPaused() async throws {
        while isPaused {
            try Task.checkCancellation()
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.pauseContinuation = cont
            }
        }
    }

    private func resumeIfPaused() {
        if let cont = pauseContinuation {
            pauseContinuation = nil
            cont.resume()
        }
    }

    private func sleepFor(_ seconds: Double) async throws {
        let totalNanoseconds = UInt64(seconds * 1_000_000_000)
        let chunkSize: UInt64 = 100_000_000
        var remaining = totalNanoseconds

        while remaining > 0 {
            try Task.checkCancellation()
            if isPaused {
                try await waitIfPaused()
            }
            let sleep = min(remaining, chunkSize)
            try await Task.sleep(nanoseconds: sleep)
            remaining -= sleep
        }
    }

    private func startSleepTimer(minutes: Int) {
        sleepTimerRemaining = minutes * 60
        sleepTimerTask = Task {
            while sleepTimerRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                sleepTimerRemaining -= 1
            }
            stop()
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePause()
            }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePause()
            }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePause()
            }
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.skipForward()
            }
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.skipBackward()
            }
            return .success
        }
    }

    private func setupNowPlayingInfo() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func updateNowPlaying(word: StoredWord) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = word.word
        info[MPMediaItemPropertyArtist] = word.translation ?? "Droword"
        info[MPMediaItemPropertyAlbumTitle] = "Droword Listening"
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPaused ? 0.0 : 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
    }
}
