import SwiftUI

struct FirstWordsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore

    let onDismiss: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var wordsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var addedWords: Set<Int> = []

    private var starterWords: [StarterWord] {
        StarterWordBank.words(
            learning: languageStore.learningLanguage,
            native: languageStore.nativeLanguage
        ) ?? []
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("📚")
                    .font(.system(size: 64))
                    .scaleEffect(emojiScale)

                VStack(spacing: 8) {
                    Text("Start with these words")
                        .font(themeStore.bold(24))
                        .foregroundColor(themeStore.mainText)

                    Text("Tap any word to add it to your dictionary")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)

                VStack(spacing: 10) {
                    ForEach(Array(starterWords.enumerated()), id: \.offset) { index, starter in
                        wordRow(starter, index: index)
                    }
                }
                .opacity(wordsOpacity)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text(addedWords.isEmpty ? "Skip" : "Continue")
                        .font(themeStore.bold(17))
                        .foregroundColor(.white)
                }
                .duo3DStyle(themeStore.mainAccentColor)
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(themeStore.appBg)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            Haptics.mediumImpact()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.5)) {
                wordsOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.75)) {
                buttonOpacity = 1.0
            }
        }
    }

    private func wordRow(_ starter: StarterWord, index: Int) -> some View {
        let isAdded = addedWords.contains(index)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(starter.word)
                        .font(themeStore.bold(17))
                        .foregroundColor(themeStore.mainText)

                    if let transcription = starter.transcription {
                        Text("[\(transcription)]")
                            .font(themeStore.regular(12))
                            .foregroundColor(themeStore.secondaryText)
                    }
                }

                Text(starter.translation)
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.secondaryText)
            }

            Spacer()

            Button {
                guard !isAdded else { return }
                Haptics.lightImpact()
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    addedWords.insert(index)
                }
                let storedWord = StoredWord(
                    word: starter.word,
                    type: starter.type,
                    translation: starter.translation,
                    example: nil,
                    transcription: starter.transcription,
                    fromLanguage: languageStore.learningLanguage,
                    toLanguage: languageStore.nativeLanguage
                )
                store.add(storedWord)
            } label: {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isAdded ? themeStore.accentGreen : themeStore.mainAccentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}
