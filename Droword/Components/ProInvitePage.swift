import SwiftUI

enum ProInvite {
    static let firstDay = 2
    static let gapDays = 4

    static func isDue(firstUse: String, lastPrompt: String, today: Date = Date()) -> Bool {
        guard let start = DateFormatting.dayFormatter.date(from: firstUse) else { return false }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let todayDay = calendar.startOfDay(for: today)
        let sinceInstall = calendar.dateComponents([.day], from: startDay, to: todayDay).day ?? 0
        guard sinceInstall >= firstDay else { return false }
        guard !lastPrompt.isEmpty, let last = DateFormatting.dayFormatter.date(from: lastPrompt) else { return true }
        let sincePrompt = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: todayDay).day ?? 0
        return sincePrompt >= gapDays
    }
}

private struct ProInviteBenefit: Identifiable {
    let id: Int
    let icon: String
    let text: LocalizedStringKey
}

struct ProInvitePage: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onSeePro: () -> Void
    let onLater: () -> Void

    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var rowsVisible = false
    @State private var footerOpacity: Double = 0

    private let benefits: [ProInviteBenefit] = [
        ProInviteBenefit(id: 0, icon: "wand.and.stars", text: "Every new card can be a full AI card."),
        ProInviteBenefit(id: 1, icon: "camera", text: "Scan as many pages as you need."),
        ProInviteBenefit(id: 2, icon: "speaker.wave.2", text: "Hear a word as often as you like."),
    ]

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            SoftCoverScrollCentered(footerHeight: 140) {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 8) {
                        Text("Want the cap off?")
                            .font(themeStore.display(32))
                            .foregroundStyle(themeStore.mainText)
                            .tracking(-0.4)
                            .multilineTextAlignment(.center)

                        Text("AI cards, scans, and voice, without the daily limit.")
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 18)
                    .opacity(textOpacity)

                    VStack(spacing: 10) {
                        ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                            row(benefit)
                                .opacity(rowsVisible ? 1 : 0)
                                .offset(y: rowsVisible ? 0 : 14)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.82)
                                        .delay(reduceMotion ? 0 : 0.2 + Double(index) * 0.08),
                                    value: rowsVisible
                                )
                        }
                    }
                    .padding(.top, 28)
                }
            } footer: {
                VStack(spacing: DesignSpacing.buttonGap) {
                    Button {
                        Haptics.success()
                        onSeePro()
                    } label: {
                        Text("See PRO")
                            .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())

                    Button {
                        Haptics.softTap()
                        onLater()
                    } label: {
                        Text("Not now")
                            .duo3DSecondaryStyle()
                    }
                    .buttonStyle(Duo3DButtonStyle())
                }
                .opacity(footerOpacity)
            }
        }
        .onAppear(perform: play)
    }

    private var hero: some View {
        SoftCoverHero(
            systemName: "sparkle",
            color: themeStore.iconAccent,
            iconScale: iconScale
        )
    }

    private func row(_ benefit: ProInviteBenefit) -> some View {
        HStack(spacing: 12) {
            StickerSymbol(systemName: benefit.icon, size: 28, color: themeStore.mainAccentColor)

            Text(benefit.text)
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.mainText.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    private func play() {
        Haptics.encourage()
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            rowsVisible = true
            footerOpacity = 1
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        Task { @MainActor in
            rowsVisible = true
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeOut(duration: 0.3)) {
                footerOpacity = 1
            }
        }
    }
}

#Preview {
    ProInvitePage(onSeePro: {}, onLater: {})
        .environmentObject(ThemeStore())
}
