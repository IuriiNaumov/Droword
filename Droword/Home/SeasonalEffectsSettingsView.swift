import SwiftUI

struct SeasonalEffectsSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @AppStorage(AppStorageKeys.seasonalAnimationEnabled) private var seasonalAnimationEnabled: Bool = true
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.seasonalEffectsSelection) private var selectionRaw: String = ""
    @State private var showPremiumWall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
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
                        toggleRow(
                            icon: "wind",
                            color: themeStore.iconBlue,
                            title: "Animate",
                            isOn: $seasonalAnimationEnabled
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: seasonalEffectsEnabled)

                Text("Choose effects")
                    .font(themeStore.bold(18))
                    .foregroundStyle(themeStore.mainText)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                    ForEach(Season.allCases) { season in
                        effectCard(season)
                    }
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
        Button {
            isOn.wrappedValue.toggle()
            Haptics.menuTap()
        } label: {
            HStack(spacing: 14) {
                MenuSymbol(systemName: icon)
                Text(title)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.mainText)
                Spacer()
                Toggle("", isOn: isOn)
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

    private var selectedSeasons: Set<Season> {
        Set(Season.selection(from: selectionRaw))
    }

    private func toggle(_ season: Season) {
        guard isPremium else {
            showPremiumWall = true
            return
        }
        var picked = selectedSeasons
        if !seasonalEffectsEnabled {
            picked = [season]
            seasonalEffectsEnabled = true
        } else if picked.contains(season) {
            guard picked.count > 1 else {
                Haptics.menuTap()
                return
            }
            picked.remove(season)
        } else {
            picked.insert(season)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectionRaw = Season.storageValue(picked)
        }
        Haptics.menuTap()
    }

    private func effectCard(_ season: Season) -> some View {
        let isSelected = seasonalEffectsEnabled && isPremium && selectedSeasons.contains(season)
        return Button {
            toggle(season)
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                        .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                    SeasonalOverlayView(animated: seasonalAnimationEnabled, seasonOverride: season)
                        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
                }
                .frame(height: 150)
                .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                        .strokeBorder(themeStore.mainAccentColor, lineWidth: isSelected ? 2.5 : 0)
                }

                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(themeStore.secondaryText.opacity(0.18))
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(themeStore.mainAccentColor)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text(season.title)
                        .font(themeStore.medium(15))
                        .foregroundStyle(themeStore.mainText)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
    }
}

#Preview {
    NavigationStack {
        SeasonalEffectsSettingsView()
    }
    .environmentObject(ThemeStore())
}
