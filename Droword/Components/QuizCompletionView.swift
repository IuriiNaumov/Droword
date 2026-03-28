import SwiftUI

struct QuizCompletionView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let correct: Int
    let total: Int
    var bestStreak: Int = 0
    var missedWords: [(word: String, translation: String)] = []
    let onRestart: () -> Void

    @State private var animatedProgress: Double = 0

    private var percentage: Int {
        total > 0 ? Int(round(Double(correct) / Double(total) * 100)) : 0
    }

    private var scoreColor: Color {
        switch percentage {
        case 70...100: return themeStore.accentGreen
        case 40..<70: return themeStore.isMonochrome ? Color("MonoMedium") : Color(red: 1.0, green: 0.902, blue: 0.655)
        default: return themeStore.accentRed
        }
    }

    private var encouragementText: String {
        switch percentage {
        case 90...100: return "Outstanding!"
        case 70..<90: return "Great job!"
        case 50..<70: return "Keep going!"
        default: return "Keep practicing!"
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 40)

                    Text(encouragementText)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(themeStore.mainText)

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
                                .font(.custom("Poppins-Bold", size: 26))
                                .foregroundColor(themeStore.mainText)
                            Text("\(percentage)%")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(themeStore.secondaryText)
                        }
                    }

                    if bestStreak > 0 {
                        HStack(spacing: 24) {
                            statBubble(
                                icon: "flame.fill",
                                value: "\(bestStreak)",
                                label: "Best streak",
                                color: themeStore.accentRed
                            )
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

                    if !missedWords.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Words to review")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(themeStore.secondaryText)
                                .padding(.horizontal, 4)

                            ForEach(Array(missedWords.enumerated()), id: \.offset) { _, pair in
                                HStack {
                                    Text(pair.word)
                                        .font(.custom("Poppins-Medium", size: 15))
                                        .foregroundColor(themeStore.mainText)
                                    Spacer()
                                    Text(pair.translation)
                                        .font(.custom("Poppins-Regular", size: 15))
                                        .foregroundColor(themeStore.secondaryText)
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

                    Button(action: { Haptics.mediumImpact(); onRestart() }) {
                        Text("Try Again")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(themeStore.mainAccentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

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
        }
    }

    private func statBubble(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(themeStore.mainText)
            Text(label)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(themeStore.secondaryText)
        }
        .frame(minWidth: 70)
    }
}
