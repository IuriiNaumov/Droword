import SwiftUI

struct LearningPreferencesForm: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var profile: LearningProfileStore

    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 22 : 28) {
            sectionHeader(
                title: "Your vibe",
                subtitle: "Why are you learning right now?"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LearningGoal.allCases) { goal in
                    preferenceCard(
                        icon: goal.icon,
                        title: goal.title,
                        subtitle: goal.subtitle,
                        selected: profile.goal == goal
                    ) {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            profile.goal = goal
                        }
                    }
                }
            }

            sectionHeader(
                title: "Topics you care about",
                subtitle: "Pick up to 4 — suggestions lean this way"
            )

            FlowLayout(spacing: 8) {
                ForEach(LearningTopic.allCases) { topic in
                    SelectionChip(
                        title: topic.title,
                        leading: topic.emoji,
                        color: themeStore.mainAccentColor,
                        isSelected: profile.topics.contains(topic),
                        isDisabled: !profile.topics.contains(topic) && profile.topics.count >= 4,
                        verticalPadding: 9,
                        horizontalPadding: 14,
                        titleFontSize: 14
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            profile.toggleTopic(topic)
                        }
                    }
                }
            }

            sectionHeader(
                title: "How you lock it in",
                subtitle: "Practice will bias toward this"
            )

            VStack(spacing: 8) {
                ForEach(LearningStyle.selectableCases) { style in
                    styleRow(style)
                }
            }
        }
    }

    private func sectionHeader(title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(themeStore.bold(compact ? 18 : 20))
                .foregroundStyle(themeStore.mainText)
            Text(subtitle)
                .font(themeStore.regular(13))
                .foregroundStyle(themeStore.secondaryText)
        }
    }

    private func preferenceCard(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : themeStore.mainAccentColor)

                Text(title)
                    .font(themeStore.bold(14))
                    .foregroundStyle(selected ? Color.white : themeStore.mainText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(themeStore.regular(11))
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : themeStore.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                    .fill(selected ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.55))
            )
            .scaleEffect(selected ? 1.0 : 0.98)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
    }

    private func styleRow(_ style: LearningStyle) -> some View {
        let selected = profile.style == style
        return Button {
            Haptics.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                profile.style = style
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : themeStore.mainAccentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.title)
                        .font(themeStore.bold(15))
                        .foregroundStyle(selected ? Color.white : themeStore.mainText)
                    Text(style.subtitle)
                        .font(themeStore.regular(12))
                        .foregroundStyle(selected ? Color.white.opacity(0.85) : themeStore.secondaryText)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(selected ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.55))
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
    }
}

struct LearningPreferencesView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profile = LearningProfileStore.shared

    var showsClose: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Learning vibe")
                    .sheetTitle()

                Text("Tune practice and suggestions to how you actually learn.")
                    .font(themeStore.regular(15))
                    .foregroundStyle(themeStore.secondaryText)

                LearningPreferencesForm(profile: profile)

                Button {
                    Haptics.buttonPress()
                    profile.markConfigured()
                    dismiss()
                } label: {
                    Text("Save vibe")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .iPadContentWidth(600)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if showsClose {
                    CloseButton()
                } else {
                    SettingsBackButton()
                }
            }
        }
        .enableSwipeBack()
    }
}

struct OnboardingPreferencesPage: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var profile = LearningProfileStore.shared

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Make it yours")
                            .font(themeStore.bold(28))
                            .foregroundStyle(themeStore.mainText)
                        Text("Goal, topics, style — so practice feels like you.")
                            .font(themeStore.regular(15))
                            .foregroundStyle(themeStore.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)

                    LearningPreferencesForm(profile: profile, compact: true)
                }
                .padding(.top, 54)
                .padding(.bottom, 12)
            }
        }
        .onDisappear {
            profile.markConfigured()
        }
    }
}

#Preview("Form") {
    LearningPreferencesForm(profile: LearningProfileStore.shared)
        .padding()
        .environmentObject(ThemeStore())
}

#Preview("Settings") {
    NavigationStack {
        LearningPreferencesView()
    }
    .environmentObject(ThemeStore())
}

#Preview("Onboarding") {
    OnboardingPreferencesPage()
        .environmentObject(ThemeStore())
}
