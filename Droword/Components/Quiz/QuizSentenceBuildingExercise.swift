import SwiftUI

struct QuizSentenceBuildingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let shakeOffset: CGFloat

    @Binding var sentenceWords: [String]
    @Binding var selectedSentenceWords: [String]
    let correctSentenceWords: [String]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Build the sentence")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.7))

                Text(item.translation.displayCapitalized)
                    .font(themeStore.bold(22))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)

            builtArea
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            wordBank
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var builtArea: some View {
        let areaFill: Color = {
            if !hasAnswered { return themeStore.isGlass ? Color.clear : themeStore.cardBg }
            return isCorrect ? themeStore.accentGreen.opacity(0.12) : themeStore.accentRed.opacity(0.12)
        }()

        return VStack(spacing: 8) {
            FlowLayout(spacing: 8) {
                if selectedSentenceWords.isEmpty {
                    Text("Tap words to build the sentence")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText.opacity(0.4))
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(selectedSentenceWords.enumerated()), id: \.offset) { index, word in
                        Button {
                            guard !hasAnswered else { return }
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSentenceWords.remove(at: index)
                                sentenceWords.append(word)
                            }
                        } label: {
                            Text(word)
                                .font(themeStore.medium(15))
                                .foregroundStyle(themeStore.mainText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(themeStore.mainAccentColor.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(hasAnswered)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(areaFill)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !hasAnswered, cornerRadius: 14))

            if hasAnswered && !isCorrect {
                QuizFeedbackBadge(
                    icon: "xmark.circle.fill",
                    text: DuoChaosCopy.wrongReveal(correctSentenceWords.joined(separator: " ")),
                    color: themeStore.accentRed
                )
            }

            if hasAnswered && isCorrect {
                QuizFeedbackBadge(
                    icon: "checkmark.circle.fill",
                    text: DuoChaosCopy.correct(),
                    color: themeStore.accentGreen
                )
            }
        }
        .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)
    }

    private var wordBank: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(sentenceWords.enumerated()), id: \.offset) { index, word in
                Button {
                    guard !hasAnswered else { return }
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sentenceWords.remove(at: index)
                        selectedSentenceWords.append(word)
                    }
                } label: {
                    Text(word)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                        )
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(hasAnswered)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct QuizSentenceBuildingExercisePreview: View {
    @State private var sentenceWords = ["Hola", "amigo"]
    @State private var selectedSentenceWords: [String] = []

    var body: some View {
        QuizSentenceBuildingExercise(
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
            shakeOffset: 0,
            sentenceWords: $sentenceWords,
            selectedSentenceWords: $selectedSentenceWords,
            correctSentenceWords: ["Hola", "amigo"]
        )
        .padding()
        .environmentObject(ThemeStore())
    }
}

#Preview {
    QuizSentenceBuildingExercisePreview()
}
