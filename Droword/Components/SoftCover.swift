import SwiftUI

struct SoftCoverWash: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let color: Color

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            color
                .opacity(colorScheme == .dark ? 0.22 : 0.16)
                .ignoresSafeArea()
        }
    }
}

struct SoftCoverHero: View {
    let systemName: String
    let color: Color
    var iconScale: CGFloat = 1

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 52, weight: .semibold))
            .foregroundStyle(color)
            .scaleEffect(iconScale)
            .frame(height: 64)
            .accessibilityHidden(true)
    }
}
