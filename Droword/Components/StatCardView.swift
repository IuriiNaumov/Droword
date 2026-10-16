import SwiftUI

struct StatCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(themeStore.bold(22))
                .foregroundStyle(themeStore.mainText)
                .contentTransition(.numericText())

            Text(title)
                .font(themeStore.medium(13))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.appBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
        .cardDepth(cornerRadius: themeStore.cardRadius)
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
