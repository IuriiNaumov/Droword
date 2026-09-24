import SwiftUI

enum TTSPlayer {
    private static var activeTask: Task<Void, Never>?
    private static var holdGeneration = 0

    static func play(
        word: String,
        isPremium: Bool,
        onNeedsPremium: @escaping () -> Void,
        onNeedsNetwork: (() -> Void)? = nil,
        onPlayingChanged: @escaping (Bool) -> Void
    ) {
        guard NetworkMonitor.shared.isConnected else {
            onNeedsNetwork?()
            return
        }
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
                    onPlayingChanged(false)
                }
            }
            do {
                try await withTaskCancellationHandler {
                    try await AudioManager.shared.playAndWait(text: word)
                } onCancel: {
                    Task { @MainActor in
                        AudioManager.shared.stopPlayback()
                    }
                }
            } catch {
                #if DEBUG
                print("⚠️ Audio playback failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
        }
    }

    static func beginHold(
        word: String,
        isPremium: Bool,
        onNeedsPremium: @escaping () -> Void,
        onNeedsNetwork: (() -> Void)? = nil,
        onPlayingChanged: @escaping (Bool) -> Void
    ) {
        guard NetworkMonitor.shared.isConnected else {
            onNeedsNetwork?()
            return
        }
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
            defer {
                Task { @MainActor in
                    guard generation == holdGeneration else { return }
                    onPlayingChanged(false)
                }
            }
            do {
                try await withTaskCancellationHandler {
                    try await AudioManager.shared.playAndWait(text: word)
                } onCancel: {
                    Task { @MainActor in
                        AudioManager.shared.stopPlayback()
                    }
                }
            } catch {
                #if DEBUG
                print("⚠️ Hold TTS failed for '\(word)': \(error.localizedDescription)")
                #endif
            }
        }
    }

    static func endHold(onPlayingChanged: @escaping (Bool) -> Void) {
        holdGeneration += 1
        activeTask?.cancel()
        activeTask = nil
        Task { @MainActor in
            AudioManager.shared.stopPlayback()
            onPlayingChanged(false)
        }
    }
}
