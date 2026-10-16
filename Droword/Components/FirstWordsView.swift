import SwiftUI

struct FirstWordsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.72
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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SoftCoverHero(
                            systemName: "textformat",
                            color: themeStore.accentBlue,
                            iconScale: iconScale
                        )
                        .padding(.top, 24)

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
                        .padding(.bottom, 12)
                        .opacity(wordsOpacity)
                    }
                    .frame(maxWidth: 460)
                    .padding(.horizontal, DesignSpacing.screenInset)
                    .frame(maxWidth: .infinity)
                }

                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text(addedWords.isEmpty ? "Skip" : "Continue")
                        .duo3DStyle(themeStore.accentBlue)
                }
                .buttonStyle(Duo3DButtonStyle())
                .frame(maxWidth: 460)
                .padding(.horizontal, DesignSpacing.screenInset)
                .padding(.bottom, 12)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            Haptics.encourage()
            guard !reduceMotion else {
                iconScale = 1
                textOpacity = 1
                wordsOpacity = 1
                buttonOpacity = 1
                return
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
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

        return VStack(spacing: 8) {
            Text(starter.word)
                .font(themeStore.bold(17))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.center)

            if let transcription = starter.transcription {
                Text("[\(transcription)]")
                    .font(themeStore.regular(12))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Text(starter.translation)
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)

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
                Image(systemName: isAdded ? "checkmark.circle" : "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(isAdded ? themeStore.accentGreen : themeStore.accentBlue)
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cleanCard(themeStore: themeStore, cornerRadius: themeStore.cardRadius)
    }
}

#Preview {
    FirstWordsView(onDismiss: {})
        .environmentObject(ThemeStore())
        .environmentObject(LanguageStore())
        .environmentObject(WordsStore())
}
