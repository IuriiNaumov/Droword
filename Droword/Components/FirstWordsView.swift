import SwiftUI

struct FirstWordsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore

    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
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
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(systemName: "textformat")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
                    .scaleEffect(iconScale)

                VStack(spacing: 8) {
                    Text("Start with these words")
                        .font(themeStore.display(32))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text("Tap any word to add it to your dictionary")
                        .font(themeStore.regular(16))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 18)
                .opacity(textOpacity)

                VStack(spacing: 10) {
                    ForEach(Array(starterWords.enumerated()), id: \.offset) { index, starter in
                        wordRow(starter, index: index)
                    }
                }
                .padding(.top, 28)
                .opacity(wordsOpacity)

                Spacer(minLength: 24)

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text(addedWords.isEmpty ? "Skip" : "Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            Haptics.mediumImpact()
            withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) {
                iconScale = 1
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.22)) {
                wordsOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.32)) {
                buttonOpacity = 1
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
                        .foregroundStyle(themeStore.mainText)

                    if let transcription = starter.transcription {
                        Text("[\(transcription)]")
                            .font(themeStore.regular(12))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                }

                Text(starter.translation)
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
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
                Image(systemName: isAdded ? "checkmark.circle" : "plus.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(isAdded ? themeStore.accentGreen : themeStore.mainAccentColor)
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}

#Preview {
    FirstWordsView(onDismiss: {})
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(WordsStore())
}
