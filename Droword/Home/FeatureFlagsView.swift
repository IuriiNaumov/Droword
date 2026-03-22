import SwiftUI

struct FeatureFlagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage("isPremium") private var isPremium: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeStore.iconGold.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeStore.iconGold)
                        }
                        Text("PRO")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $isPremium)
                            .labelsHidden()
                            .tint(themeStore.accentGold)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(themeStore.cardBg)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.large)
    }
}
