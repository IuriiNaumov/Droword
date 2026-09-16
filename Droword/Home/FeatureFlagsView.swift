import SwiftUI

struct FeatureFlagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.debugPremiumOverride) private var debugOverride: Bool = false
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Feature Flags")
                    .sheetTitle()

                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ProBadgeIcon(size: 28)
                        Text("PRO")
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.mainText)
                        Spacer()
                        Toggle("", isOn: $isPremium)
                            .labelsHidden()
                            .tint(themeStore.mainAccentColor)
                            .onChange(of: isPremium) { _, newValue in
                                debugOverride = newValue
                            }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .background(themeStore.cardBg)
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))

                VStack(spacing: 0) {
                    Button {
                        hasCompletedOnboarding.toggle()
                        Haptics.menuTap()
                    } label: {
                        HStack(spacing: 14) {
                            MenuSymbol(systemName: "hand.wave")
                            Text("Onboarding")
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.mainText)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { !hasCompletedOnboarding },
                                set: { newValue in
                                    hasCompletedOnboarding = !newValue
                                }
                            ))
                                .labelsHidden()
                                .tint(themeStore.mainAccentColor)
                                .allowsHitTesting(false)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(themeStore.cardBg)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }
}
