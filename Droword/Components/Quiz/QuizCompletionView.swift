import SwiftUI

struct QuizCompletionView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let correct: Int
    let total: Int
    var bestStreak: Int = 0
    var missedWords: [(word: String, translation: String)] = []
    var moments: [StudyMoment] = []
    var isLesson: Bool = false
    var onScene: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    let onRestart: () -> Void

    @State private var animatedProgress: Double = 0

    private var percentage: Int {
        total > 0 ? Int(round(Double(correct) / Double(total) * 100)) : 0
    }

    private var scoreColor: Color {
        switch percentage {
        case 70...100: return themeStore.accentGreen
        case 40..<70: return themeStore.isSunset ? themeStore.accentGold : Color(red: 1.0, green: 0.902, blue: 0.655)
        default: return themeStore.accentRed
        }
    }

    private var encouragementText: String {
        DuoChaosCopy.quizDone(percentage: percentage).title
    }

    private var encouragementSubtitle: String {
        DuoChaosCopy.quizDone(percentage: percentage).subtitle
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 40)
                    titleBlock
                    subtitleBlock
                    if percentage == 100 {
                        PerfectLessonBadge()
                    }
                    scoreRing
                    if bestStreak > 0 {
                        streakRow
                    }
                    if !moments.isEmpty {
                        momentsBlock
                    }
                    if !missedWords.isEmpty {
                        missedBlock
                    }
                    actionButtons
                    Spacer(minLength: 40)
                }
            }

            if percentage >= 70 {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = Double(percentage) / 100.0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                if percentage == 100 {
                    SoundFX.play(.sparkle)
                    Haptics.celebration()
                } else if percentage >= 70 {
                    Haptics.celebration()
                } else {
                    Haptics.lightImpact()
                }
            }
        }
    }

    private var titleBlock: some View {
        Text(isLesson ? String(localized: "Lesson done") : encouragementText)
            .zoomerTitle(28)
            .environmentObject(themeStore)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }

    private var subtitleBlock: some View {
        HStack(spacing: 4) {
            Text(subtitleCopy)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)

            if isLesson, missedWords.isEmpty {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themeStore.accentPink)
                    .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
    }

    private var subtitleCopy: String {
        if isLesson {
            return missedWords.isEmpty
                ? String(localized: "See you tomorrow.")
                : String(localized: "These come back tomorrow.")
        }
        return encouragementSubtitle
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(scoreColor.opacity(0.2), lineWidth: 10)
                .frame(width: 130, height: 130)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(correct)/\(total)")
                    .font(themeStore.bold(26))
                    .foregroundStyle(themeStore.mainText)
                Text("\(percentage)%")
                    .font(themeStore.medium(14))
                    .foregroundStyle(themeStore.secondaryText)
            }
        }
    }

    private var streakRow: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                BurningFlameIcon(size: 20)
                Text("\(bestStreak)")
                    .font(themeStore.bold(18))
                    .foregroundStyle(StreakFireStyle.red)
                Text("Best streak")
                    .font(themeStore.regular(11))
                    .foregroundStyle(themeStore.secondaryText)
            }
            .frame(minWidth: 70)

            statBubble(
                icon: "checkmark.circle.fill",
                value: "\(correct)",
                label: "Correct",
                color: themeStore.accentGreen
            )
            statBubble(
                icon: "xmark.circle.fill",
                value: "\(total - correct)",
                label: "Missed",
                color: themeStore.accentRed
            )
        }
        .padding(.top, 4)
    }

    private var momentsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(moments.contains(where: \.landed)
                 ? String(localized: "What landed")
                 : String(localized: "Still sticky"))
                .font(themeStore.medium(16))
                .foregroundStyle(themeStore.secondaryText)
                .padding(.horizontal, 4)

            ForEach(moments) { moment in
                VStack(alignment: .leading, spacing: 4) {
                    Text(moment.word.displayCapitalized)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                    Text(moment.landed
                         ? String(localized: "Yesterday this was hard. Today you got it.")
                         : String(localized: "Keep this one close. It will come back tomorrow."))
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((moment.landed ? themeStore.accentGreen : themeStore.accentRed).opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }

    private var missedBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Words to review")
                .font(themeStore.medium(16))
                .foregroundStyle(themeStore.secondaryText)
                .padding(.horizontal, 4)

            ForEach(Array(missedWords.enumerated()), id: \.offset) { _, pair in
                HStack {
                    Text(pair.word.displayCapitalized)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                    Spacer()
                    Text(pair.translation.displayCapitalized)
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(themeStore.accentRed.opacity(0.08))
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if isLesson, let onScene {
            VStack(spacing: 10) {
                Button {
                    Haptics.buttonPress()
                    onScene()
                } label: {
                    Text("Drop it in a chat")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())

                Button {
                    Haptics.softTap()
                    onRestart()
                } label: {
                    Text("Once more")
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(.plain)

                if let onClose {
                    closeButton(onClose)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        } else {
            VStack(spacing: 10) {
                Button(action: { Haptics.buttonPress(); onRestart() }) {
                    Text(isLesson ? "Once more" : "Try Again")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())

                if let onClose {
                    closeButton(onClose)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    private func closeButton(_ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.softTap()
            action()
        } label: {
            Text("Close")
                .duo3DStyle(themeStore.secondaryText.opacity(0.55))
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    private func statBubble(icon: String, value: String, label: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)
            Text(label)
                .font(themeStore.regular(11))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(minWidth: 70)
    }
}

#Preview {
    QuizCompletionView(correct: 8, total: 10, onRestart: {})
        .environmentObject(ThemeStore())
}
