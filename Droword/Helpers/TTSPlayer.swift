import SwiftUI

enum TTSPlayer {
    /// Plays TTS for a word, checking premium/daily limits.
    /// - Parameters:
    ///   - word: The text to speak
    ///   - isPremium: Whether the user has premium
    ///   - onNeedsPremium: Called if the user needs premium to play
    ///   - onPlayingChanged: Called when playing state changes
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
        Task {
            Haptics.selection()
            onPlayingChanged(true)
            do {
                try await AudioManager.shared.playAndWait(text: word)
            } catch {
                #if DEBUG
                print("⚠️ Audio playback failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
            await MainActor.run {
                withAnimation { onPlayingChanged(false) }
            }
        }
    }
}
