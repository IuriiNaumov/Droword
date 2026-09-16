import SwiftUI

struct SeasonalEffectsSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @AppStorage(AppStorageKeys.seasonalAnimationEnabled) private var seasonalAnimationEnabled: Bool = true
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var showPremiumWall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Seasonal effects")
                    .sheetTitle()

                Text("Decorative elements that change with the season — cherry blossoms in spring, snowflakes in winter, and more.")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "sparkles",
                        color: themeStore.iconPink,
                        title: "Show effects",
                        isOn: isPremium ? $seasonalEffectsEnabled : .constant(false)
                    )
                    .onTapGesture {
                        if !isPremium { showPremiumWall = true }
                    }

                    if seasonalEffectsEnabled && isPremium {
                        Divider().padding(.leading, 68)

                        toggleRow(
                            icon: "wind",
                            color: themeStore.iconBlue,
                            title: "Animate",
                            isOn: $seasonalAnimationEnabled
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: seasonalEffectsEnabled)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current season")
                        .font(themeStore.bold(18))
                        .foregroundStyle(.primary)

                    let season = Season.current
                    HStack(spacing: 8) {
                        Text(season.shapes.first?.emoji ?? "")
                            .font(.system(size: 28))
                        Text(seasonName(season))
                            .font(themeStore.medium(16))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                if seasonalEffectsEnabled {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                            .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                            .frame(height: 180)
                        SeasonalOverlayView(animated: seasonalAnimationEnabled)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                            .allowsHitTesting(false)
                    }
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
                    .transition(.opacity)
                }
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
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private func toggleRow(icon: String, color: Color = .clear, title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(themeStore.mainText)
                .frame(width: 28, height: 28)
            Text(title)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(themeStore.mainAccentColor)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(themeStore.cardBg)
    }

    private func seasonName(_ season: Season) -> String {
        switch season {
        case .spring: return String(localized: "Spring")
        case .summer: return String(localized: "Summer")
        case .fall: return String(localized: "Fall")
        case .winter: return String(localized: "Winter")
        }
    }
}
