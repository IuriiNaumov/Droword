import SwiftUI

struct QuizMultipleChoiceView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @StateObject private var session = QuizSessionManager()

    @State private var options: [String] = []
    @State private var selectedOption: String? = nil
    @State private var hasAnswered = false
    @State private var isCorrect = false

    var body: some View {
        ZStack {
            if store.words.filter({ $0.translation != nil && !$0.translation!.isEmpty }).count < 4 {
                notEnoughState
            } else if session.isComplete {
                QuizCompletionView(
                    correct: session.correctCount,
                    total: session.total
                ) {
                    startSession()
                }
            } else if let item = session.currentItem {
                questionView(item: item)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.currentIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.isComplete)
        .onAppear { startSession() }
    }

    private func questionView(item: QuizSessionManager.QuizItem) -> some View {
        VStack(spacing: 0) {
            Text("\(session.currentIndex + 1) / \(session.total)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.mainGrey)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 8) {
                Text(item.word)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.mainBlack)
                    .multilineTextAlignment(.center)

                if let tr = item.transcription, !tr.isEmpty {
                    Text(tr)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                }

                Text("Choose the correct translation")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainGrey.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionButton(option: option, correctAnswer: item.translation)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if hasAnswered {
                Button {
                    goToNext()
                } label: {
                    Text("Next")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.accentBlue)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func optionButton(option: String, correctAnswer: String) -> some View {
        let isThisCorrect = option.lowercased() == correctAnswer.lowercased()
        let isSelected = selectedOption == option

        var bgColor: Color {
            if !hasAnswered {
                return Color.cardBackground
            }
            if isThisCorrect {
                return Color.accentGreen
            }
            if isSelected && !isThisCorrect {
                return Color.accentRed
            }
            return Color.cardBackground
        }

        var textColor: Color {
            if !hasAnswered {
                return Color.mainBlack
            }
            if isThisCorrect {
                return darkerShade(of: Color.accentGreen, by: 0.4)
            }
            if isSelected && !isThisCorrect {
                return darkerShade(of: Color.accentRed, by: 0.4)
            }
            return Color.mainBlack.opacity(0.4)
        }

        return Button {
            selectOption(option)
        } label: {
            HStack {
                Text(option)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(textColor)

                Spacer()

                if hasAnswered && isThisCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(darkerShade(of: Color.accentGreen, by: 0.3))
                        .transition(.scale.combined(with: .opacity))
                }
                if hasAnswered && isSelected && !isThisCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(darkerShade(of: Color.accentRed, by: 0.3))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(bgColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
        .animation(.easeInOut(duration: 0.25), value: hasAnswered)
    }

    private func startSession() {
        session.prepareSession(from: store.words)
        if let item = session.currentItem {
            prepareOptions(for: item)
        }
    }

    private func prepareOptions(for item: QuizSessionManager.QuizItem) {
        let distractors = session.distractors(for: item, from: store.words)
        var all = distractors + [item.translation]
        all.shuffle()
        options = all
        selectedOption = nil
        hasAnswered = false
        isCorrect = false
    }

    private func selectOption(_ option: String) {
        guard !hasAnswered else { return }
        Haptics.selection()
        selectedOption = option
        hasAnswered = true
        isCorrect = option.lowercased() == session.currentItem?.translation.lowercased()

        if isCorrect {
            Haptics.success()
        } else {
            Haptics.error()
        }

        session.recordAnswer(correct: isCorrect)

        if let item = session.currentItem {
            QuizSessionManager.applyScheduling(
                for: item.id,
                correct: isCorrect,
                store: store,
                languageStore: languageStore
            )
        }
    }

    private func goToNext() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            session.advance()
        }
        if let item = session.currentItem {
            prepareOptions(for: item)
        }
    }

    private var notEnoughState: some View {
        VStack(spacing: 18) {
            Text("Not enough words yet ✨")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Add at least 4 words with translations to start the quiz. Every word counts!")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QuizCompletionView: View {
    let correct: Int
    let total: Int
    let onRestart: () -> Void

    private var percentage: Int {
        total > 0 ? Int(round(Double(correct) / Double(total) * 100)) : 0
    }

    private var scoreColor: Color {
        switch percentage {
        case 70...100: return Color.accentGreen
        case 40..<70: return Color(red: 1.0, green: 0.902, blue: 0.655)
        default: return Color.accentRed
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Session Complete!")
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.mainBlack)

            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: Double(percentage) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: percentage)

                VStack(spacing: 2) {
                    Text("\(correct)/\(total)")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.mainBlack)
                    Text("\(percentage)%")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.mainGrey)
                }
            }

            Button(action: onRestart) {
                Text("Try Again")
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.accentBlue)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    QuizMultipleChoiceView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}
