import SwiftUI

struct QuizListeningExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var network = NetworkMonitor.shared

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let options: [String]
    let selectedOption: String?
    let shakeOffset: CGFloat

    var onSelect: (String) -> Void

    @State private var isPlaying = false

    private var correctAnswer: String { item.word }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Button {
                    play()
                } label: {
                    SoundWavesView(isPlaying: isPlaying)
                        .scaleEffect(2.2)
                        .frame(width: 96, height: 96)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .opacity(canSpeakWord ? 1 : 0.35)
                .disabled(!canSpeakWord || isPlaying)
                .accessibilityLabel(Text("Play the word"))
                .accessibilityHint(
                    Text(canSpeakWord
                         ? "Plays the word out loud"
                         : "Needs an internet connection")
                )

                Text(canSpeakWord ? "Tap to hear it again" : "Needs an internet connection")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionButton(option: option)
                }
            }
            .padding(.horizontal, 24)
            .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)

            if hasAnswered {
                Group {
                    if isCorrect {
                        QuizCorrectFeedbackBadge()
                    } else {
                        QuizFeedbackBadge(
                            icon: "xmark.circle.fill",
                            text: DuoChaosCopy.wrongReveal(correctAnswer),
                            color: themeStore.errorStrong
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hasAnswered)
    }

    private var canSpeakWord: Bool {
        TTSPlayer.canPlay(word: item.word, online: network.isConnected)
    }

    private func play() {
        guard canSpeakWord, !isPlaying else { return }
        isPlaying = true
        Task {
            try? await AudioManager.shared.playAndWait(text: item.word)
            await MainActor.run { isPlaying = false }
        }
    }

    private func optionButton(option: String) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option
        let isIrrelevant = hasAnswered && !isThisCorrect && !isSelected
        let duo = themeStore.isDuolingo && !themeStore.isGlass
        let pixel = themeStore.isPixel
        let radius = themeStore.controlRadius

        let bgColor: Color = {
            if !hasAnswered {
                return themeStore.isGlass ? Color.clear : (duo ? themeStore.controlFace : themeStore.cardBg)
            }
            if isThisCorrect {
                return themeStore.isGlass ? themeStore.successStrong.opacity(0.28) : themeStore.successSoft
            }
            if isSelected && !isThisCorrect {
                return themeStore.isGlass ? themeStore.errorStrong.opacity(0.28) : themeStore.errorSoft
            }
            return themeStore.isGlass ? Color.clear : (duo ? themeStore.controlFace : themeStore.cardBg)
        }()

        let textColor: Color = {
            if hasAnswered && isIrrelevant { return themeStore.mainText.opacity(0.4) }
            return themeStore.mainText
        }()

        let borderColor: Color? = {
            guard duo || pixel else { return nil }
            if hasAnswered, isThisCorrect { return themeStore.successStrong }
            if hasAnswered, isSelected && !isThisCorrect { return themeStore.errorStrong }
            return pixel ? themeStore.pixelInk : themeStore.dividerColor
        }()

        return Button {
            onSelect(option)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(option.displayCapitalized)
                    .font(themeStore.medium(16))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeStore.successStrong)
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeStore.errorStrong)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    if pixel {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(themeStore.pixelShadow)
                            .offset(x: 4, y: 4)
                    } else if duo {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Color(hex: "#AFAFAF").opacity(0.45))
                            .offset(y: 3)
                    }
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(bgColor)
                }
            )
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 2)
                }
            }
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: radius))
            .padding(.bottom, pixel ? 4 : (duo ? 3 : 0))
            .padding(.trailing, pixel ? 4 : 0)
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(hasAnswered)
        .opacity(isIrrelevant ? 0.4 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: hasAnswered)
        .accessibilityLabel(Text(option))
    }
}

#Preview {
    QuizListeningExercise(
        item: QuizSessionManager.QuizItem(
        id: UUID(),
        word: "hola",
        translation: "hello",
        transcription: "ˈola",
        tag: "basics",
        example: "¡Hola!"
    ),
        hasAnswered: false,
        isCorrect: false,
        options: ["hello", "bye", "please", "thanks"],
        selectedOption: nil,
        shakeOffset: 0,
        onSelect: { _ in }
    )
    .padding()
    .environmentObject(ThemeStore())
}
