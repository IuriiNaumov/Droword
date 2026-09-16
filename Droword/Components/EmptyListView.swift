import SwiftUI

struct EmptyListView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var icon: String? = "text.badge.plus"
    var illustration: AnyView? = nil
    var title: String = String(localized: "Your word garden is waiting")
    var subtitle: String = String(localized: "Add a couple of words — and we'll begin the journey.")
    var tip: String? = nil

    @State private var iconScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            if illustration != nil || icon != nil {
                Group {
                    if let illustration {
                        illustration
                    } else if let icon {
                        HaloIcon(symbol: icon, color: themeStore.mainAccentColor, size: 168)
                    }
                }
                .frame(width: 176, height: 176)
                .scaleEffect(iconScale)
            }

            Text(title)
                .font(themeStore.display(20))
                .foregroundStyle(themeStore.mainText)
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)

            Text(subtitle)
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            if let tip {
                Text(tip)
                    .font(themeStore.bold(13))
                    .foregroundStyle(themeStore.mainAccentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(themeStore.mainAccentColor.opacity(0.12))
                    )
                    .padding(.horizontal, 28)
                    .opacity(subtitleOpacity)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if illustration != nil || icon != nil {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    iconScale = 1.0
                }
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
    EmptyListView(
        illustration: AnyView(EmptyDictionaryArt()),
        title: "No words yet",
        subtitle: "It's so empty we're crying."
    )
    .environmentObject(ThemeStore())
    .preferredColorScheme(.light)
}
