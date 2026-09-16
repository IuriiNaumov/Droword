import SwiftUI

struct QuickSessionCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let dueCount: Int
    var onStart: () -> Void

    private var estimateLabel: String {
        if dueCount <= 3 {
            return String(localized: "~1 min")
        }
        if dueCount <= 8 {
            return String(localized: "~2 min")
        }
        return String(localized: "~3 min")
    }

    private var heroBg: Color {
        colorScheme == .dark ? themeStore.mainAccentColor : themeStore.mainText
    }

    private var heroFg: Color { .white }

    private var heroMuted: Color {
        Color.white.opacity(0.72)
    }

    var body: some View {
        Button {
            onStart()
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(DuoChaosCopy.quickSessionTitle())
                            .font(themeStore.bold(24))
                            .foregroundStyle(heroFg)

                        Text(
                            dueCount == 1
                                ? String(localized: "1 word due · \(estimateLabel)")
                                : String(localized: "\(dueCount) words due · \(estimateLabel)")
                        )
                        .font(themeStore.regular(15))
                        .foregroundStyle(heroMuted)
                    }

                    Spacer(minLength: 8)

                    Text("\(dueCount)")
                        .font(themeStore.bold(20))
                        .foregroundStyle(colorScheme == .dark ? .white : themeStore.mainText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.22) : Color.white)
                        )
                }

                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(DuoChaosCopy.quickSessionCTA())
                        .font(themeStore.bold(16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.22) : themeStore.mainAccentColor)
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(heroBg)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("2-minute review session, \(dueCount) words due"))
        .accessibilityHint(Text("Double tap to start"))
    }
}
