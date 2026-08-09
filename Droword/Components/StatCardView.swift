import SwiftUI

struct StatCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: LocalizedStringKey
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(themeStore.bold(22))
                .foregroundStyle(themeStore.isMonochrome ? .white : themeStore.mainText)
                .contentTransition(.numericText())

            Text(title)
                .font(themeStore.medium(13))
                .foregroundStyle(themeStore.isMonochrome ? .white.opacity(0.75) : themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.isGlass
                      ? Color.clear
                      : (themeStore.isMonochrome
                         ? themeStore.mainText.opacity(colorScheme == .dark ? 0.7 : 0.75)
                         : themeStore.appBg))
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        .cardDepth(cornerRadius: 16)
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
