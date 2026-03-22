import SwiftUI

struct StatCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        themeStore.isMonochrome ? themeStore.mainText.opacity(0.75) : themeStore.accentBlue
    }

    private var textColor: Color {
        if themeStore.isMonochrome { return .white }
        return themeStore.mainText
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(themeStore.bold(22))
                .foregroundColor(textColor)

            Text(title)
                .font(themeStore.medium(13))
                .foregroundColor(textColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(baseColor.opacity(colorScheme == .dark ? 0.9 : 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(themeStore.dividerColor, lineWidth: 1)
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
