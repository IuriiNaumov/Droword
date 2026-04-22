import SwiftUI

struct AppCustomizationView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @State private var showAppearanceSheet = false
    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("App customization")
                    .sheetTitle()

                // MARK: - Background (Theme)
                NavigationLink(value: SettingsDestination.theme) {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Background")
                                .font(themeStore.bold(16))
                                .foregroundColor(themeStore.mainText)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(availablePalettes) { palette in
                                        themeCard(palette: palette)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                // MARK: - App Icon
                sectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App icon")
                            .font(themeStore.bold(16))
                            .foregroundColor(themeStore.mainText)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                appIconCard(name: "Main", isSelected: true)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }

                // MARK: - Mode
                Button {
                    Haptics.selection()
                    showAppearanceSheet = true
                } label: {
                    sectionCard {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(themeStore.monoDark.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: appearance == .dark ? "moon.fill" : (appearance == .light ? "sun.max.fill" : "circle.lefthalf.filled"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeStore.monoDark)
                            }

                            Text("Mode")
                                .font(themeStore.regular(16))
                                .foregroundColor(themeStore.mainText)

                            Spacer()

                            Text(appearance.title)
                                .font(themeStore.regular(14))
                                .foregroundColor(themeStore.secondaryText)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeStore.accentBlue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.plain)

                // MARK: - Seasonal Effects
                NavigationLink(value: SettingsDestination.seasonalEffects) {
                    sectionCard {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(themeStore.iconPink.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeStore.iconPink)
                            }

                            HStack(spacing: 6) {
                                Text("Seasonal effects")
                                    .font(themeStore.regular(16))
                                    .foregroundColor(themeStore.mainText)

                                if !isPremium {
                                    Text("PRO")
                                        .font(themeStore.bold(9))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(themeStore.accentBlue))
                                }
                            }

                            Spacer()

                            Text(seasonalEffectsEnabled ? "On" : "Off")
                                .font(themeStore.regular(14))
                                .foregroundColor(themeStore.secondaryText)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeStore.accentBlue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerView()
                .environmentObject(themeStore)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Theme Card

    private func themeCard(palette: ThemeStore.Palette) -> some View {
        let c = ThemeStore.previewColors(for: palette)
        let isSelected = themeStore.palette == palette

        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(c.appBg)
            .frame(width: 80, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? themeStore.mainAccentColor : c.secondaryText.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - App Icon Card

    private func appIconCard(name: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(themeStore.mainAccentColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeStore.mainAccentColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    )
            }

            Text(name)
                .font(themeStore.regular(12))
                .foregroundColor(themeStore.mainText)
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
    }

    private var availablePalettes: [ThemeStore.Palette] {
        ThemeStore.Palette.allCases.filter { palette in
            if palette.requiresIOS26 {
                if #available(iOS 26, *) { return true }
                return false
            }
            return true
        }
    }
}

#Preview {
    NavigationStack {
        AppCustomizationView()
            .environmentObject(ThemeStore())
    }
}
