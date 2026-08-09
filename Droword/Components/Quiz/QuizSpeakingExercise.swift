import SwiftUI

/// Упражнение на произношение: пользователь произносит слово вслух, речь
/// распознаётся через `SpeechRecognizer`, а родитель сверяет результат со словом.
struct QuizSpeakingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    /// Pronunciation similarity 0…1 once evaluated, `nil` before answering.
    var accuracy: Double? = nil
    let shakeOffset: CGFloat
    let localeIdentifier: String

    var onResult: (String) -> Void
    var onSkip: () -> Void

    @StateObject private var recognizer = SpeechRecognizer()
    @State private var permissionDenied = false
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Text("Say this word")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))

                Text(item.word)
                    .font(themeStore.bold(30))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.center)

                if let tr = item.transcription, !tr.isEmpty {
                    Text("[\(tr)]")
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Button {
                    playWord()
                } label: {
                    HStack(spacing: 6) {
                        SoundWavesView(isPlaying: isPlaying)
                        Text("Listen")
                    }
                    .font(themeStore.medium(14))
                    .foregroundStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)
            .padding(.bottom, 28)

            micButton

            if hasAnswered, let acc = accuracy {
                pronunciationFeedback(acc)
                    .padding(.top, 16)
                    .transition(.opacity)
            }

            if permissionDenied || recognizer.isUnavailable {
                Text("Microphone or speech recognition is unavailable. You can skip this one.")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
            }

            Spacer()

            if !hasAnswered {
                Button {
                    recognizer.stop()
                    onSkip()
                } label: {
                    Text("Can't speak now")
                        .font(themeStore.medium(14))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: recognizer.isRecording) { wasRecording, isRecording in
            // Recording just finished — submit the transcript for evaluation.
            if wasRecording && !isRecording && !hasAnswered {
                let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { onResult(text) }
            }
        }
        .onDisappear { recognizer.stop() }
    }

    /// Graded pronunciation feedback (score + encouraging label), shown instead
    /// of the raw transcript so the focus stays on how close the pronunciation was.
    private func pronunciationFeedback(_ acc: Double) -> some View {
        let pct = Int((acc * 100).rounded())
        let label: LocalizedStringKey
        let color: Color
        if acc >= 0.9 {
            label = "Perfect!"; color = themeStore.accentGreen
        } else if acc >= 0.8 {
            label = "Great pronunciation!"; color = themeStore.accentGreen
        } else if acc >= 0.55 {
            label = "Close — keep practicing"; color = themeStore.accentGold
        } else {
            label = "Try again"; color = themeStore.accentRed
        }
        return HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(themeStore.medium(15))
            Text("\(pct)%")
                .font(themeStore.bold(15))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private var micButton: some View {
        Button {
            handleMicTap()
        } label: {
            ZStack {
                Circle()
                    .fill(recognizer.isRecording ? themeStore.accentRed : themeStore.mainAccentColor)
                    .frame(width: 96, height: 96)

                if recognizer.isRecording {
                    Circle()
                        .stroke(themeStore.accentRed.opacity(0.35), lineWidth: 6)
                        .frame(width: 116, height: 116)
                        .scaleEffect(recognizer.isRecording ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: recognizer.isRecording)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(hasAnswered || recognizer.isRecording)
        .accessibilityLabel(Text(recognizer.isRecording ? "Listening" : "Start speaking"))
    }

    private func playWord() {
        guard !isPlaying else { return }
        isPlaying = true
        Task {
            try? await AudioManager.shared.playAndWait(text: item.word)
            await MainActor.run { isPlaying = false }
        }
    }

    private func handleMicTap() {
        guard !recognizer.isRecording else { return }
        Haptics.lightImpact()
        Task {
            let granted = await recognizer.requestAuthorization()
            if granted {
                recognizer.start(localeIdentifier: localeIdentifier)
            } else {
                permissionDenied = true
            }
        }
    }
}
