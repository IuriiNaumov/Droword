import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    private var features: [WhatsNewFeature] {[
        WhatsNewFeature(
            icon: "character.book.closed.fill",
            color: themeStore.accentBlue,
            title: "Smart Dictionary",
            description: "AI-powered translations with examples, transcription and context."
        ),
        WhatsNewFeature(
            icon: "brain.head.profile.fill",
            color: themeStore.accentGreen,
            title: "Spaced Repetition",
            description: "Review words at optimal intervals so they stick in long-term memory."
        ),
        WhatsNewFeature(
            icon: "gamecontroller.fill",
            color: themeStore.accentGold,
            title: "Mixed Quizzes",
            description: "Multiple choice, cloze, matching, typing and sentence building exercises."
        ),
        WhatsNewFeature(
            icon: "waveform.circle.fill",
            color: themeStore.iconPink,
            title: "Voice & Pronunciation",
            description: "Listen to words with customizable voice and speech rate."
        ),
        WhatsNewFeature(
            icon: "paintpalette.fill",
            color: themeStore.iconPurple,
            title: "Themes & Customization",
            description: "Choose from multiple themes, seasonal effects and appearance settings."
        ),
        WhatsNewFeature(
            icon: "trophy.fill",
            color: themeStore.iconGold,
            title: "Achievements & Streaks",
            description: "Track your progress with badges, daily challenges and streak calendar."
        )
    ]}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What's New")
                        .font(themeStore.bold(28))
                        .foregroundColor(themeStore.mainText)

                    Text("Version \(appVersion)")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)
                }
                .padding(.top, 24)

                VStack(spacing: 16) {
                    ForEach(features) { feature in
                        featureRow(feature)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
            .iPadContentWidth(600)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func featureRow(_ feature: WhatsNewFeature) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: feature.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(themeStore.medium(16))
                    .foregroundColor(themeStore.mainText)
                Text(feature.description)
                    .font(themeStore.regular(13))
                    .foregroundColor(themeStore.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}
