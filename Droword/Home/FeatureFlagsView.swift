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
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeStore.iconGold.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeStore.iconGold)
                        }
                        Text("PRO")
                            .font(themeStore.regular(16))
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: $isPremium)
                            .labelsHidden()
                            .tint(themeStore.accentGold)
                            .onChange(of: isPremium) { _, newValue in
                                debugOverride = newValue
                            }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(themeStore.cardBg)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeStore.mainAccentColor.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeStore.mainAccentColor)
                        }
                        Text("Onboarding")
                            .font(themeStore.regular(16))
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { !hasCompletedOnboarding },
                            set: { newValue in
                                hasCompletedOnboarding = !newValue
                            }
                        ))
                            .labelsHidden()
                            .tint(themeStore.mainAccentColor)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(themeStore.cardBg)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
