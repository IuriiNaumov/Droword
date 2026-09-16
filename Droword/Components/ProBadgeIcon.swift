import SwiftUI

struct ProBadgeIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 44
    var cornerRadius: CGFloat? = nil

    private var radius: CGFloat { cornerRadius ?? size * 0.28 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(themeStore.mainAccentColor)

            Text("PRO")
                .font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(size > 50 ? 1.2 : 0.4)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("PRO"))
    }
}

struct ProPlusMark: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(themeStore.mainAccentColor)

            Image(systemName: "plus")
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("Droword PRO"))
    }
}

struct ProPillBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        Text("PRO")
            .font(themeStore.bold(9))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(themeStore.mainAccentColor)
            )
    }
}
