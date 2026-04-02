import SwiftUI

struct QuizMatchingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool

    @Binding var matchingPairs: [(word: String, translation: String)]
    @Binding var matchedPairs: Set<String>
    @Binding var selectedMatchWord: String?
    @Binding var selectedMatchTranslation: String?
    @Binding var matchingWrongPair: (String, String)?
    @Binding var shuffledTranslations: [String]

    var onAllMatched: () -> Void
    var onWrongMatch: () -> Void

    var body: some View {
        let words = matchingPairs.map(\.word)

        VStack(spacing: 0) {
            Spacer()

            Text("Match the pairs")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.secondaryText.opacity(0.7))
                .padding(.bottom, 24)

            HStack(spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(words, id: \.self) { word in
                        matchingWordCell(text: word, isWord: true)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(shuffledTranslations, id: \.self) { translation in
                        matchingWordCell(text: translation, isWord: false)
                    }
                }
            }
            .padding(.horizontal, 24)

            if hasAnswered && isCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: "Correct!",
                    color: themeStore.accentGreen
                )
                .padding(.top, 16)
            }

            Spacer()
        }
    }

    private func matchingWordCell(text: String, isWord: Bool) -> some View {
        let isMatched = matchedPairs.contains(text)
        let isSelected = (isWord && selectedMatchWord == text) || (!isWord && selectedMatchTranslation == text)
        let isWrong = matchingWrongPair?.0 == text || matchingWrongPair?.1 == text

        var bgColor: Color {
            if isMatched { return themeStore.accentGreen.opacity(0.2) }
            if isWrong { return themeStore.accentRed.opacity(0.2) }
            if isSelected { return themeStore.mainAccentColor.opacity(0.15) }
            return themeStore.cardBg
        }

        var borderColor: Color {
            if isMatched { return themeStore.accentGreen }
            if isWrong { return themeStore.accentRed }
            if isSelected { return themeStore.mainAccentColor }
            return themeStore.dividerColor
        }

        return Button {
            handleTap(text: text, isWord: isWord)
        } label: {
            Text(text)
                .font(themeStore.medium(14))
                .foregroundColor(isMatched ? themeStore.secondaryText : themeStore.mainText)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bgColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .opacity(isMatched ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.2), value: isMatched)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func handleTap(text: String, isWord: Bool) {
        guard !hasAnswered else { return }

        if isWord {
            if selectedMatchWord == text {
                selectedMatchWord = nil
                Haptics.selection()
            } else if let translation = selectedMatchTranslation {
                checkPair(word: text, translation: translation)
            } else {
                selectedMatchWord = text
                Haptics.selection()
            }
        } else {
            if selectedMatchTranslation == text {
                selectedMatchTranslation = nil
                Haptics.selection()
            } else if let word = selectedMatchWord {
                checkPair(word: word, translation: text)
            } else {
                selectedMatchTranslation = text
                Haptics.selection()
            }
        }
    }

    private func checkPair(word: String, translation: String) {
        let isCorrectPair = matchingPairs.contains { $0.word == word && $0.translation == translation }

        if isCorrectPair {
            Haptics.success()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                matchedPairs.insert(word)
                matchedPairs.insert(translation)
                selectedMatchWord = nil
                selectedMatchTranslation = nil
            }

            if matchedPairs.count == matchingPairs.count * 2 {
                onAllMatched()
            }
        } else {
            Haptics.error()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                matchingWrongPair = (word, translation)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { matchingWrongPair = nil }
            }
            selectedMatchWord = nil
            selectedMatchTranslation = nil
            onWrongMatch()
        }
    }
}
