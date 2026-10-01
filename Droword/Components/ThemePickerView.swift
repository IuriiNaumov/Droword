import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var selectedPalette: ThemeStore.Palette = .colorful
    @State private var showPremiumWall = false
    @State private var customPickerColor: Color = Color(hex: ThemeStore.defaultCustomAccentHex)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var initialPalette: ThemeStore.Palette? = nil
    var isSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("App background")
                    .sheetTitle()
                Text(selectedPalette.title)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .animation(.easeOut(duration: 0.2), value: selectedPalette)
            }
            .padding(.bottom, 12)

            TabView(selection: $selectedPalette) {
                ForEach(availablePalettes) { palette in
                    previewStage(palette: palette)
                        .tag(palette)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            PageCapsules(
                count: availablePalettes.count,
                selection: availablePalettes.firstIndex(of: selectedPalette) ?? 0,
                activeColor: ThemeStore.previewColors(
                    for: selectedPalette,
                    customHex: themeStore.customAccentHex
                ).mainAccentColor,
                glass: selectedPalette == .glass
            )
            .padding(.top, 4)

            setButton
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isSheet {
                    CloseButton()
                } else {
                    SettingsBackButton()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .onAppear {
            selectedPalette = initialPalette ?? themeStore.palette
            customPickerColor = Color(hex: themeStore.customAccentHex)
        }
        .onChange(of: selectedPalette) { _, new in
            if new == .custom {
                customPickerColor = Color(hex: themeStore.customAccentHex)
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private func previewStage(palette: ThemeStore.Palette) -> some View {
        let c = ThemeStore.previewColors(
            for: palette,
            customHex: palette == .custom ? themeStore.customAccentHex : ThemeStore.defaultCustomAccentHex
        )

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(c.mainAccentColor.opacity(0.22))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(c.mainAccentColor)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(c.mainText.opacity(0.35)).frame(width: 96, height: 8)
                        Capsule().fill(c.secondaryText.opacity(0.3)).frame(width: 64, height: 6)
                    }
                    Spacer(minLength: 0)
                    if palette == .custom {
                        ColorPicker("", selection: $customPickerColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 44, height: 44)
                            .onChange(of: customPickerColor) { _, newColor in
                                if let hex = newColor.toHexRGB() {
                                    themeStore.customAccentHex = hex
                                }
                            }
                    }
                }

                HStack(spacing: 10) {
                    glassMiniCard(c)
                    glassMiniCard(c)
                }

                HStack {
                    Capsule().fill(c.mainText.opacity(0.2)).frame(width: 72, height: 8)
                    Spacer()
                    Capsule()
                        .fill(c.cardBg.opacity(0.95))
                        .frame(width: 52, height: 30)
                        .overlay(alignment: .trailing) {
                            Circle()
                                .fill(c.mainAccentColor)
                                .padding(3)
                        }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(glassPlate(c))

                wordPreviewCard(c)
                wordPreviewCard(c, muted: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .top)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(c.appBg)
                    if c.isGlass {
                        glassPreviewWash
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .id(palette.rawValue)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var glassPreviewWash: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#9BB7E8"))
                .frame(width: 160, height: 160)
                .blur(radius: 36)
                .offset(x: -90, y: -30)
            Circle()
                .fill(Color(hex: "#007AFF").opacity(0.38))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: 100, y: 70)
            Circle()
                .fill(Color(hex: "#E8F1FF"))
                .frame(width: 180, height: 180)
                .blur(radius: 28)
                .offset(x: 20, y: 220)
        }
        .allowsHitTesting(false)
    }

    private func glassMiniCard(_ c: ThemeStore.PreviewColors) -> some View {
        let radius: CGFloat = c.isDuolingo ? 16 : DesignRadius.large
        return Color.clear
            .frame(height: 64)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(c.isGlass ? Color.clear : c.cardBg.opacity(c.isDuolingo ? 1 : 0.72))
            }
            .modifier(GlassCardModifier(isGlass: c.isGlass, cornerRadius: radius))
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Capsule().fill(c.mainText.opacity(0.28)).frame(width: 40, height: 6)
                    Capsule().fill(c.secondaryText.opacity(0.25)).frame(width: 56, height: 5)
                }
                .padding(.leading, 14)
            }
    }

    private func glassPlate(_ c: ThemeStore.PreviewColors) -> some View {
        let radius: CGFloat = c.isDuolingo ? 16 : DesignRadius.large
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(c.isGlass ? Color.clear : c.cardBg.opacity(c.isDuolingo ? 1 : 0.55))
            .modifier(GlassCardModifier(isGlass: c.isGlass, cornerRadius: radius))
    }

    private func wordPreviewCard(_ c: ThemeStore.PreviewColors, muted: Bool = false) -> some View {
        let radius: CGFloat = c.isDuolingo ? 16 : 22
        return VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(c.mainAccentColor.opacity(muted ? 0.25 : 0.45))
                .frame(width: muted ? 48 : 56, height: 7)
            Text(muted ? "Ephemeral" : "Serendipity")
                .font(c.bold(16))
                .foregroundStyle(c.mainText.opacity(muted ? 0.55 : 1))
            Text(muted ? "…" : "Счастливая случайность")
                .font(c.regular(12))
                .foregroundStyle(c.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(c.isGlass ? Color.clear : c.cardBg.opacity(muted ? 0.85 : 1))
        )
        .modifier(GlassCardModifier(isGlass: c.isGlass, cornerRadius: radius))
    }

    private var setButton: some View {
        let isCurrent = themeStore.palette == selectedPalette
            && (selectedPalette != .custom || themeStore.customAccentHex == (customPickerColor.toHexRGB() ?? themeStore.customAccentHex))
        let c = ThemeStore.previewColors(
            for: selectedPalette,
            customHex: selectedPalette == .custom ? themeStore.customAccentHex : ThemeStore.defaultCustomAccentHex
        )
        let useDuoChrome = selectedPalette == .duolingo || themeStore.isDuolingo
        let accent = isCurrent
            ? (useDuoChrome ? Color(hex: "#E5E5E5") : themeStore.secondaryText.opacity(0.55))
            : c.mainAccentColor

        return Button(action: applySelection) {
            setButtonLabel(isCurrent: isCurrent)
                .modifier(SetButtonChrome(
                    accent: accent,
                    isCurrent: isCurrent,
                    useDuoChrome: useDuoChrome,
                    useGlass: selectedPalette == .glass,
                    labelColor: colorScheme == .dark ? .white : .black
                ))
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(isCurrent && themeStore.palette == selectedPalette)
    }

    private func setButtonLabel(isCurrent: Bool) -> some View {
        HStack(spacing: 8) {
            if isCurrent && themeStore.palette == selectedPalette {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                Text("Current background")
            } else if !isPremium && selectedPalette != .colorful {
                Image(systemName: "lock")
                    .font(.system(size: 14, weight: .bold))
                Text("Choose")
            } else {
                Text("Choose")
            }
        }
    }

    private func applySelection() {
        Haptics.menuTap()
        guard isPremium || selectedPalette == .colorful else {
            showPremiumWall = true
            return
        }
        if selectedPalette == .custom, let hex = customPickerColor.toHexRGB() {
            themeStore.customAccentHex = hex
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            themeStore.set(selectedPalette)
        }
        dismiss()
    }

    private var availablePalettes: [ThemeStore.Palette] {
        ThemeStore.Palette.pickerOrder.filter { palette in
            if palette.requiresIOS26 {
                if #available(iOS 26, *) { return true }
                return false
            }
            return true
        }
    }
}

private struct SetButtonChrome: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let isCurrent: Bool
    let useDuoChrome: Bool
    let useGlass: Bool
    let labelColor: Color

    func body(content: Content) -> some View {
        if useGlass {
            content
                .font(themeStore.bold(17))
                .foregroundStyle(isCurrent ? themeStore.secondaryText : labelColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                        .fill(isCurrent ? themeStore.secondaryText.opacity(0.25) : accent.opacity(0.28))
                }
                .modifier(GlassCardModifier(isGlass: !isCurrent, cornerRadius: DesignRadius.large))
        } else {
            content.duo3DStyle(
                accent,
                isDisabled: isCurrent,
                force3D: useDuoChrome,
                verticalPadding: useDuoChrome ? 14 : 16
            )
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView(isSheet: true)
            .environmentObject(ThemeStore())
    }
}
