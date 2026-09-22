import SwiftUI

struct HomeExtrasToggleList: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @AppStorage(AppStorageKeys.showHomeReading) private var showHomeReading: Bool = true
    @AppStorage(AppStorageKeys.showHomeChat) private var showHomeChat: Bool = true
    @AppStorage(AppStorageKeys.showWordPacks) private var showWordPacks: Bool = true
    @AppStorage(AppStorageKeys.showDailyChallenges) private var showDailyChallenges: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            row(
                icon: "book.pages",
                title: "Reading",
                subtitle: "A short story that hides a few of your words.",
                isOn: $showHomeReading
            )
            if FeatureGates.homeChatEnabled {
                row(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat",
                    subtitle: "Tiny role-play scenes to use a word in conversation.",
                    isOn: $showHomeChat
                )
            }
            row(
                icon: "rectangle.stack.fill",
                title: "Word Packs",
                subtitle: "Ready-made lists you can add to your dictionary.",
                isOn: $showWordPacks
            )
            row(
                icon: "dumbbell.fill",
                title: "Daily Challenges",
                subtitle: "Small daily goals that keep you coming back.",
                isOn: $showDailyChallenges,
                showDivider: false
            )
        }
        .background(themeStore.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
    }

    private func row(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        isOn: Binding<Bool>,
        showDivider: Bool = true
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                isOn.wrappedValue.toggle()
                Haptics.menuTap()
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    MenuSymbol(systemName: icon)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                        Text(subtitle)
                            .font(themeStore.regular(13))
                            .foregroundStyle(themeStore.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .tint(themeStore.mainAccentColor)
                        .allowsHitTesting(false)
                        .padding(.top, 2)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDivider {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

struct OnboardingHomeExtrasPage: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Home extras")
                    .zoomerTitle(32)
                    .environmentObject(themeStore)

                Text("Pick what shows on Home. Keep it calm or keep it busy — your call.")
                    .font(themeStore.regular(15))
                    .foregroundStyle(themeStore.secondaryText)

                HomeExtrasToggleList()
                    .padding(.top, 4)

                Text("You can always turn these on or off later in Dictionary settings.")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
            }
            .padding(.bottom, 12)
        }
    }
}

#Preview("List") {
    HomeExtrasToggleList()
        .padding()
        .environmentObject(ThemeStore())
}

#Preview("Onboarding") {
    OnboardingHomeExtrasPage()
        .padding()
        .environmentObject(ThemeStore())
}
