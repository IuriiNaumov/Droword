import SwiftUI

struct SentenceChip: Identifiable, Equatable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }

    static func chips(from words: [String]) -> [SentenceChip] {
        words.map { SentenceChip(text: $0) }
    }
}

struct QuizSentenceBuildingExercise: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let item: QuizSessionManager.QuizItem
    let hasAnswered: Bool
    let isCorrect: Bool
    let shakeOffset: CGFloat

    @Binding var sentenceWords: [SentenceChip]
    @Binding var selectedSentenceWords: [SentenceChip]
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

                Text(String(localized: "Tap only the words you need · includes «\(item.word)»"))
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
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
            return isCorrect ? themeStore.successStrong.opacity(0.12) : themeStore.errorStrong.opacity(0.12)
        }()

        return VStack(spacing: 8) {
            FlowLayout(spacing: 8) {
                if selectedSentenceWords.isEmpty {
                    Text("Tap words to build the sentence")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText.opacity(0.4))
                        .padding(.vertical, 8)
                } else {
                    ForEach(selectedSentenceWords) { chip in
                        Button {
                            guard !hasAnswered else { return }
                            guard let index = selectedSentenceWords.firstIndex(of: chip) else { return }
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSentenceWords.remove(at: index)
                                sentenceWords.append(chip)
                            }
                        } label: {
                            Text(chip.text)
                                .font(themeStore.medium(15))
                                .foregroundStyle(
                                    themeStore.isDuolingo && !themeStore.isGlass
                                        ? Color.white
                                        : themeStore.mainText
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    if themeStore.isDuolingo && !themeStore.isGlass {
                                        let face = themeStore.mainAccentColor
                                        ZStack {
                                            RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                                .fill(darkerShade(of: face, by: 0.16))
                                                .offset(y: 2)
                                            RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                                .fill(face)
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                            .fill(
                                                themeStore.isGlass
                                                    ? themeStore.mainAccentColor.opacity(0.22)
                                                    : themeStore.mainAccentColor.opacity(0.12)
                                            )
                                    }
                                }
                                .padding(.bottom, themeStore.isDuolingo && !themeStore.isGlass ? 2 : 0)
                                .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.chipRadius))
                        }
                        .buttonStyle(Duo3DButtonStyle())
                        .disabled(hasAnswered)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                    .fill(areaFill)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))

            if hasAnswered && !isCorrect {
                VStack(spacing: 8) {
                    QuizFeedbackBadge(
                        icon: "xmark.circle",
                        text: DuoChaosCopy.wrongReveal(""),
                        color: themeStore.errorStrong
                    )
                    Text(correctSentenceWords.joined(separator: " "))
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            if hasAnswered && isCorrect {
                QuizCorrectFeedbackBadge(icon: "checkmark.circle")
            }
        }
        .offset(x: hasAnswered && !isCorrect ? shakeOffset : 0)
    }

    private var wordBank: some View {
        FlowLayout(spacing: 8) {
            ForEach(sentenceWords) { chip in
                Button {
                    guard !hasAnswered else { return }
                    guard let index = sentenceWords.firstIndex(of: chip) else { return }
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sentenceWords.remove(at: index)
                        selectedSentenceWords.append(chip)
                    }
                } label: {
                    Text(chip.text)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if themeStore.isDuolingo && !themeStore.isGlass {
                                ZStack {
                                    RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                        .fill(Color(hex: "#AFAFAF").opacity(0.45))
                                        .offset(y: 2)
                                    RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                        .fill(themeStore.controlFace)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                            }
                        }
                        .overlay {
                            if themeStore.isDuolingo && !themeStore.isGlass {
                                RoundedRectangle(cornerRadius: themeStore.chipRadius, style: .continuous)
                                    .strokeBorder(themeStore.dividerColor, lineWidth: 2)
                            }
                        }
                        .padding(.bottom, themeStore.isDuolingo && !themeStore.isGlass ? 2 : 0)
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.chipRadius))
                }
                .buttonStyle(Duo3DButtonStyle())
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
    @State private var sentenceWords = SentenceChip.chips(from: ["L'eau", "est", "bonne.", "très", "froid"])
    @State private var selectedSentenceWords: [SentenceChip] = []

    var body: some View {
        QuizSentenceBuildingExercise(
            item: QuizSessionManager.QuizItem(
                id: UUID(),
                word: "eau",
                translation: "вода",
                transcription: nil,
                tag: "basics",
                example: "L'eau est bonne."
            ),
            hasAnswered: false,
            isCorrect: false,
            shakeOffset: 0,
            sentenceWords: $sentenceWords,
            selectedSentenceWords: $selectedSentenceWords,
            correctSentenceWords: ["L'eau", "est", "bonne."]
        )
        .padding()
        .environmentObject(ThemeStore())
    }
}

#Preview {
    QuizSentenceBuildingExercisePreview()
}
