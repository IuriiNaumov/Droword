import SwiftUI

struct AppCustomizationView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @AppStorage(AppIconStyle.storageKey) private var storedIconStyle: String = AppIconStyle.classic.rawValue

    @State private var showPremiumWall = false
    @State private var showAppearanceSheet = false
    @State private var showThemeSheet = false
    @State private var themeSheetPalette: ThemeStore.Palette = .colorful
    @State private var iconToast: String?

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    private var selectedIcon: AppIconStyle {
        AppIconStyle.resolved(storedIconStyle)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 4)

                backgroundCard
                appIconCard
                modeCard

                linkCard(
                    destination: .fontSize,
                    systemImage: "textformat.size",
                    title: String(localized: "Font size"),
                    value: themeStore.fontScaleLabel
                )

                linkCard(
                    destination: .seasonalEffects,
                    systemImage: "sparkles",
                    title: String(localized: "Seasonal effects"),
                    value: seasonalEffectsEnabled ? String(localized: "On") : String(localized: "Off"),
                    showsPro: !isPremium
                )

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationTitle("App customization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .overlay(alignment: .top) {
            if let iconToast {
                BannerToastView(type: .success, message: iconToast, duration: 2.2)
            }
        }
        .sheet(isPresented: $showAppearanceSheet) {
            NavigationStack {
                AppearancePickerView(isSheet: true)
                    .environmentObject(themeStore)
            }
            .presentationDetents([.medium])
            .modernSheet()
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemePickerView(initialPalette: themeSheetPalette, isSheet: true)
                .environmentObject(themeStore)
                .presentationDetents([.large])
                .modernSheet()
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    // MARK: - Background (Plata)

    private var backgroundCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Background")
                .font(themeStore.bold(20))
                .foregroundStyle(themeStore.mainText)
                .padding(.horizontal, 18)
                .padding(.top, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availablePalettes) { palette in
                        backgroundTile(palette)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 18)
            }
        }
        .plataSurface(themeStore)
    }

    private func backgroundTile(_ palette: ThemeStore.Palette) -> some View {
        let selected = themeStore.palette == palette
        let colors = palette.tileColors

        return Button {
            Haptics.menuTap()
            themeSheetPalette = palette
            showThemeSheet = true
        } label: {
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    backgroundTilePattern(palette)
                        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(palette == .night ? 0.12 : 0.35),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .frame(width: 92, height: 122)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignRadius.large - 1.5, style: .continuous)
                        .strokeBorder(selected ? palette.tileAccent : Color.clear, lineWidth: 1.5)
                        .padding(1.5)
                }
                .overlay {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.tileAccent)
                            .background(Circle().fill(themeStore.cardBg).padding(1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(7)
                    } else if !isPremium && palette != .colorful {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(Circle().fill(.black.opacity(0.35)))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(7)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(palette.title))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func backgroundTilePattern(_ palette: ThemeStore.Palette) -> some View {
        switch palette {
        case .night:
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 90, height: 90)
                .offset(x: 18, y: -28)
        case .ocean:
            VStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 8)
                        .offset(x: i.isMultiple(of: 2) ? 8 : -8)
                }
            }
        case .sunset:
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 70, height: 70)
                .offset(y: 28)
        case .paper:
            VStack(spacing: 9) {
                ForEach(0..<10, id: \.self) { _ in
                    Rectangle().fill(Color.black.opacity(0.05)).frame(height: 1)
                }
            }
            .padding(.horizontal, 10)
        case .duolingo:
            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 10)
                .frame(width: 54, height: 54)
                .offset(y: 20)
        case .glass:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 48)
                .offset(y: 18)
        case .colorful:
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 48, height: 48)
                .offset(x: -16, y: 22)
        }
    }

    // MARK: - App icon (Plata)

    private var appIconCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App icon")
                .font(themeStore.bold(20))
                .foregroundStyle(themeStore.mainText)
                .padding(.horizontal, 18)
                .padding(.top, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppIconStyle.allCases) { style in
                        iconTile(style)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .plataSurface(themeStore)
    }

    private func iconTile(_ style: AppIconStyle) -> some View {
        let selected = selectedIcon == style
        let locked = style.requiresPremium && !isPremium

        return Button {
            Haptics.menuTap()
            if locked {
                showPremiumWall = true
                return
            }
            AppIconChanger.apply(style) { applied in
                storedIconStyle = style.rawValue
                if style != .classic && !applied {
                    withAnimation {
                        iconToast = String(localized: "Saved — home screen icon coming soon")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { iconToast = nil }
                    }
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AppIconArtwork(style: style, size: 60)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    selected ? themeStore.mainAccentColor : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                        .opacity(selected ? 1 : 0.85)

                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(themeStore.mainAccentColor)
                            .background(Circle().fill(themeStore.cardBg).padding(1))
                            .padding(3)
                    } else if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Circle().fill(.black.opacity(0.4)))
                            .padding(3)
                    }
                }

                Text(style.title)
                    .font(themeStore.regular(12))
                    .foregroundStyle(themeStore.mainText)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode (Plata)

    private var modeCard: some View {
        Button {
            Haptics.menuTap()
            showAppearanceSheet = true
        } label: {
            HStack(spacing: 14) {
                MenuSymbol(
                    systemName: "circle.lefthalf.filled",
                    size: 22
                )

                Text("Mode")
                    .font(themeStore.regular(17))
                    .foregroundStyle(themeStore.mainText)

                Spacer()

                Text(appearance.title)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .plataSurface(themeStore)
    }

    private func linkCard(
        destination: SettingsDestination,
        systemImage: String,
        title: String,
        value: String,
        showsPro: Bool = false
    ) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 14) {
                MenuSymbol(systemName: systemImage)

                HStack(spacing: 6) {
                    Text(title)
                        .font(themeStore.regular(17))
                        .foregroundStyle(themeStore.mainText)
                    if showsPro {
                        ProPillBadge()
                    }
                }

                Spacer()

                Text(value)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themeStore.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .plataSurface(themeStore)
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

private extension View {
    func plataSurface(_ themeStore: ThemeStore) -> some View {
        cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.large)
    }
}

#Preview {
    NavigationStack {
        AppCustomizationView()
            .environmentObject(ThemeStore())
    }
}
