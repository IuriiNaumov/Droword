import SwiftUI

struct QuizCompletionView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let correct: Int
    let total: Int
    let onRestart: () -> Void

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

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Session Complete!")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(themeStore.mainText)

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
                            .foregroundColor(themeStore.mainText)
                        Text("\(percentage)%")
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(themeStore.secondaryText)
                    }
                }

                Button(action: { Haptics.mediumImpact(); onRestart() }) {
                    Text("Try Again")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themeStore.buttonAccent)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)

                Spacer()
            }

            if percentage >= 70 {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
