import SwiftUI

struct WhatsNewView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    private var features: [WhatsNewFeature] {[
        WhatsNewFeature(
            icon: "character.book.closed",
            title: "Smart Dictionary",
            description: "AI-powered translations with examples, transcription and context."
        ),
        WhatsNewFeature(
            icon: "brain.head.profile",
            title: "Spaced Repetition",
            description: "Review words at optimal intervals so they stick in long-term memory."
        ),
        WhatsNewFeature(
            icon: "gamecontroller",
            title: "Mixed Quizzes",
            description: "Multiple choice, cloze, matching, typing and sentence building exercises."
        ),
        WhatsNewFeature(
            icon: "waveform",
            title: "Voice & Pronunciation",
            description: "Listen to words with customizable voice and speech rate."
        ),
        WhatsNewFeature(
            icon: "paintpalette",
            title: "Themes & Customization",
            description: "Choose from multiple themes, seasonal effects and appearance settings."
        ),
        WhatsNewFeature(
            icon: "trophy",
            title: "Achievements & Streaks",
            description: "Track your progress with badges, daily challenges and streak calendar."
        ),
        WhatsNewFeature(
            icon: "rectangle.stack",
            title: "Word Packs",
            description: "Themed vocabulary sets — basics, food, travel and more."
        )
    ]}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What's New")
                        .font(themeStore.bold(28))
                        .foregroundStyle(themeStore.mainText)

                    Text("Version \(appVersion)")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
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
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
    }

    private func featureRow(_ feature: WhatsNewFeature) -> some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(themeStore.mainText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(themeStore.medium(16))
                    .foregroundStyle(themeStore.mainText)
                Text(feature.description)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}
