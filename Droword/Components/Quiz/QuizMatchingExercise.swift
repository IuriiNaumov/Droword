import SwiftUI

struct QuizMatchingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let wrongAttempts: Int
    let maxAttempts: Int

    @Binding var matchingPairs: [QuizSessionManager.MatchingPair]
    @Binding var matchedPairIDs: Set<UUID>
    @Binding var selectedMatchWordID: UUID?
    @Binding var selectedMatchTranslationID: UUID?
    @Binding var matchingWrongIDs: (UUID, UUID)?
    @Binding var shuffledTranslationIDs: [UUID]

    var onAllMatched: () -> Void
    var onWrongMatch: () -> Void

    private var translationPairs: [QuizSessionManager.MatchingPair] {
        shuffledTranslationIDs.compactMap { id in
            matchingPairs.first(where: { $0.id == id })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Match the pairs")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))

                HStack(spacing: 4) {
                    let remaining = maxAttempts - wrongAttempts
                    ForEach(0..<maxAttempts, id: \.self) { i in
                        Image(systemName: i < remaining ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundStyle(i < remaining ? themeStore.accentRed : themeStore.secondaryText.opacity(0.3))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: wrongAttempts)
            }
            .padding(.bottom, 24)

            HStack(spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(matchingPairs) { pair in
                        matchingCell(pair: pair, isWord: true)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(translationPairs) { pair in
                        matchingCell(pair: pair, isWord: false)
                    }
                }
            }
            .padding(.horizontal, 24)

            if hasAnswered {
                if isCorrect {
                    QuizFeedbackBadge(
                        icon: "checkmark.circle.fill",
                        text: DuoChaosCopy.correct(),
                        color: themeStore.accentGreen
                    )
                    .padding(.top, 16)
                } else {
                    QuizFeedbackBadge(
                        icon: "xmark.circle.fill",
                        text: String(localized: "No lives left"),
                        color: themeStore.accentRed
                    )
                    .padding(.top, 16)
                }
            }

            Spacer()
        }
    }

    private func matchingCell(pair: QuizSessionManager.MatchingPair, isWord: Bool) -> some View {
        let isMatched = matchedPairIDs.contains(pair.id)
        let isSelected = (isWord && selectedMatchWordID == pair.id)
            || (!isWord && selectedMatchTranslationID == pair.id)
        let isWrong = isWord
            ? matchingWrongIDs?.0 == pair.id
            : matchingWrongIDs?.1 == pair.id
        let text = (isWord ? pair.word : pair.translation).displayCapitalized

        var bgColor: Color {
            if isMatched { return themeStore.accentGreen.opacity(0.2) }
            if isWrong { return themeStore.accentRed.opacity(0.2) }
            if isSelected { return themeStore.mainAccentColor.opacity(0.15) }
            return themeStore.cardBg
        }

        return Button {
            handleTap(pairID: pair.id, isWord: isWord)
        } label: {
            Text(text)
                .font(themeStore.medium(14))
                .foregroundStyle(isMatched ? themeStore.secondaryText : themeStore.mainText)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeStore.isGlass && !isMatched && !isWrong && !isSelected ? Color.clear : bgColor)
                )
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isMatched && !isWrong && !isSelected, cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .opacity(isMatched ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isMatched)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func handleTap(pairID: UUID, isWord: Bool) {
        guard !hasAnswered else { return }

        if isWord {
            if selectedMatchWordID == pairID {
                selectedMatchWordID = nil
                Haptics.selection()
            } else if let translationID = selectedMatchTranslationID {
                checkPair(wordID: pairID, translationID: translationID)
            } else {
                selectedMatchWordID = pairID
                Haptics.selection()
            }
        } else {
            if selectedMatchTranslationID == pairID {
                selectedMatchTranslationID = nil
                Haptics.selection()
            } else if let wordID = selectedMatchWordID {
                checkPair(wordID: wordID, translationID: pairID)
            } else {
                selectedMatchTranslationID = pairID
                Haptics.selection()
            }
        }
    }

    private func checkPair(wordID: UUID, translationID: UUID) {
        if wordID == translationID {
            Haptics.success()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                matchedPairIDs.insert(wordID)
                selectedMatchWordID = nil
                selectedMatchTranslationID = nil
            }

            if matchedPairIDs.count == matchingPairs.count {
                onAllMatched()
            }
        } else {
            Haptics.error()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                matchingWrongIDs = (wordID, translationID)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { matchingWrongIDs = nil }
            }
            selectedMatchWordID = nil
            selectedMatchTranslationID = nil
            onWrongMatch()
        }
    }
}

private struct QuizMatchingExercisePreview: View {
    @State private var matchingPairs = [
        QuizSessionManager.MatchingPair(word: "hola", translation: "hello"),
        QuizSessionManager.MatchingPair(word: "adiós", translation: "bye")
    ]
    @State private var matchedPairIDs: Set<UUID> = []
    @State private var selectedMatchWordID: UUID?
    @State private var selectedMatchTranslationID: UUID?
    @State private var matchingWrongIDs: (UUID, UUID)?
    @State private var shuffledTranslationIDs: [UUID] = []

    var body: some View {
        QuizMatchingExercise(
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
            wrongAttempts: 0,
            maxAttempts: 3,
            matchingPairs: $matchingPairs,
            matchedPairIDs: $matchedPairIDs,
            selectedMatchWordID: $selectedMatchWordID,
            selectedMatchTranslationID: $selectedMatchTranslationID,
            matchingWrongIDs: $matchingWrongIDs,
            shuffledTranslationIDs: $shuffledTranslationIDs,
            onAllMatched: {},
            onWrongMatch: {}
        )
        .padding()
        .environmentObject(ThemeStore())
        .onAppear {
            if shuffledTranslationIDs.isEmpty {
                shuffledTranslationIDs = matchingPairs.map(\.id)
            }
        }
    }
}

#Preview {
    QuizMatchingExercisePreview()
}
