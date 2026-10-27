import SwiftUI

struct PracticeEmptyContent: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var illustration: AnyView? = nil
    let icon: String
    let title: String
    let subtitle: String
    var tip: String? = nil
    var ctaTitle: LocalizedStringKey? = nil
    var onCTA: (() -> Void)? = nil
    var ctaFeedback: () -> Void = { Haptics.softTap() }

    @State private var iconScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            Group {
                if let illustration {
                    illustration
                } else if let art = StickerArt(systemName: icon) {
                    StickerIcon(art: art, size: 150)
                } else {
                    HaloIcon(symbol: icon, color: themeStore.iconAccent, size: 168)
                }
            }
            .frame(width: 176, height: 176)
            .scaleEffect(iconScale)

            Text(title)
                .font(themeStore.display(22))
                .foregroundStyle(themeStore.mainText)
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)

            Text(subtitle)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            if let tip, !tip.isEmpty {
                Text(tip)
                    .font(themeStore.bold(13))
                    .foregroundStyle(themeStore.mainAccentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(themeStore.mainAccentColor.opacity(0.12))
                    )
                    .padding(.horizontal, 28)
                    .opacity(subtitleOpacity)
            }

            if let ctaTitle, let onCTA {
                Button {
                    ctaFeedback()
                    onCTA()
                } label: {
                    HStack(spacing: 8) {
                        AddPlusIcon()
                        Text(ctaTitle)
                    }
                    .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .padding(.horizontal, 40)
                .opacity(subtitleOpacity)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

#Preview {
    PracticeEmptyContent(
        icon: "bolt",
        title: "Nothing due",
        subtitle: "Add a few words and come back.",
        tip: "Four words unlock practice"
    )
    .environmentObject(ThemeStore())
}
