import SwiftUI

struct AnimatedCounter: View {
    let value: Int

    @State private var displayedValue: Int = 0

    var body: some View {
        Text("\(displayedValue)")
            .onAppear {
                guard displayedValue != value else { return }
                animateCount(to: value)
            }
            .onChange(of: value) { _, newValue in
                animateCount(to: newValue)
            }
    }

    private func animateCount(to target: Int) {
        let steps = 20
        let stepDuration = 0.035
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                let progress = Double(i) / Double(steps)
                let eased = 1.0 - pow(1.0 - progress, 3)
                displayedValue = Int(Double(target) * eased)
            }
        }
    }
}

struct StatCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        themeStore.isMonochrome ? Color.mainBlack.opacity(0.75) : themeStore.accentBlue
    }

    private var textColor: Color {
        if themeStore.isMonochrome { return .white }
        return darkerShade(of: baseColor, by: colorScheme == .dark ? 0.3 : 0.4)
    }

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let num = Int(value) {
                    AnimatedCounter(value: num)
                } else {
                    Text(value)
                }
            }
            .font(.custom("Poppins-Bold", size: 22))
            .foregroundColor(textColor)

            Text(title)
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(textColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(baseColor.opacity(colorScheme == .dark ? 0.9 : 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: value)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatCardView(title: "Total", value: "123")
            StatCardView(title: "Today", value: "5")
        }

        StatCardView(title: "Last 7 days", value: "28")
    }
    .padding()
    .preferredColorScheme(.light)

    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatCardView(title: "Total", value: "123")
            StatCardView(title: "Today", value: "5")
        }

        StatCardView(title: "Last 7 days", value: "28")
    }
    .padding()
    .preferredColorScheme(.dark)
}
