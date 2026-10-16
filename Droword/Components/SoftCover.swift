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

struct SoftCoverCentered<Content: View, Footer: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            content()
            Spacer(minLength: 24)
            footer()
                .padding(.bottom, 12)
        }
        .frame(maxWidth: 460)
        .padding(.horizontal, DesignSpacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension SoftCoverCentered where Footer == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(content: content, footer: { EmptyView() })
    }
}

struct SoftCoverScrollCentered<Content: View, Footer: View>: View {
    var footerHeight: CGFloat = 88
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    content()
                        .frame(maxWidth: 460)
                        .padding(.horizontal, DesignSpacing.screenInset)
                        .frame(maxWidth: .infinity)
                        .frame(
                            minHeight: max(0, geo.size.height - footerHeight),
                            alignment: .center
                        )
                }

                footer()
                    .frame(maxWidth: 460)
                    .padding(.horizontal, DesignSpacing.screenInset)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
