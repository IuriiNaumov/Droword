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
    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0
    @State private var addedWords: Set<Int> = []

    private var starterWords: [StarterWord] {
        StarterWordBank.words(
            learning: languageStore.learningLanguage,
            native: languageStore.nativeLanguage
        ) ?? []
    }

    var body: some View {
        ZStack {
            themeStore.appBg.opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "textformat")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
                    .scaleEffect(iconScale)

                VStack(spacing: 8) {
                    Text("Start with these words")
                        .font(themeStore.display(22))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text("Tap any word to add it to your dictionary")
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
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
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 360)
            .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.dialog)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            Haptics.mediumImpact()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                cardScale = 1
                cardOpacity = 1
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
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(isAdded ? themeStore.accentGreen : themeStore.mainAccentColor)
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.secondaryText.opacity(0.08))
        )
    }
}

#Preview {
    FirstWordsView(onDismiss: {})
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(WordsStore())
}
