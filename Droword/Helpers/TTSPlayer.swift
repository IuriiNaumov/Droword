import SwiftUI

enum TTSPlayer {
    private static var activeTask: Task<Void, Never>?
    private static var holdGeneration = 0

    static func play(
        word: String,
        isPremium: Bool,
        onNeedsPremium: @escaping () -> Void,
        onPlayingChanged: @escaping (Bool) -> Void
    ) {
        guard isPremium || DailyLimitsManager.canPlayTTS else {
            onNeedsPremium()
            return
        }
        if !isPremium { DailyLimitsManager.recordTTS() }

        activeTask?.cancel()
        holdGeneration += 1
        let generation = holdGeneration

        activeTask = Task {
            Haptics.selection()
            await MainActor.run { onPlayingChanged(true) }
            defer {
                Task { @MainActor in
                    guard generation == holdGeneration else { return }
                    withAnimation { onPlayingChanged(false) }
                }
            }
            do {
                try await AudioManager.shared.playAndWait(text: word)
            } catch {
                #if DEBUG
                print("⚠️ Audio playback failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Start TTS while the user holds; call `endHold()` on release.
    static func beginHold(
        word: String,
        isPremium: Bool,
        onNeedsPremium: @escaping () -> Void,
        onPlayingChanged: @escaping (Bool) -> Void
    ) {
        guard isPremium || DailyLimitsManager.canPlayTTS else {
            onNeedsPremium()
            return
        }
        if !isPremium { DailyLimitsManager.recordTTS() }

        activeTask?.cancel()
        holdGeneration += 1
        let generation = holdGeneration
        Haptics.softTap()

        activeTask = Task {
            await MainActor.run { onPlayingChanged(true) }
            do {
                try await AudioManager.shared.playAndWait(text: word)
            } catch {
                #if DEBUG
                print("⚠️ Hold TTS failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
            await MainActor.run {
                guard generation == holdGeneration else { return }
                withAnimation { onPlayingChanged(false) }
            }
        }
    }

    static func endHold(onPlayingChanged: @escaping (Bool) -> Void) {
        holdGeneration += 1
        activeTask?.cancel()
        activeTask = nil
        Task { @MainActor in
            AudioManager.shared.stopPlayback()
            withAnimation { onPlayingChanged(false) }
        }
    }
}
