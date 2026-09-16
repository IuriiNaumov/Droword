import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var selectedPalette: ThemeStore.Palette = .colorful
    @State private var showPremiumWall = false
    @Environment(\.dismiss) private var dismiss

    var initialPalette: ThemeStore.Palette? = nil
    var isSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $selectedPalette) {
                ForEach(availablePalettes) { palette in
                    previewStage(palette: palette)
                        .tag(palette)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: .infinity)

            setButton
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .onAppear {
            selectedPalette = initialPalette ?? themeStore.palette
            let accent = UIColor(themeStore.mainAccentColor)
            UIPageControl.appearance().currentPageIndicatorTintColor = accent
            UIPageControl.appearance().pageIndicatorTintColor = accent.withAlphaComponent(0.25)
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
        .toolbar {
            if !isSheet {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsBackButton()
                }
            }
        }
        .navigationBarBackButtonHidden(!isSheet)
        .enableSwipeBack()
    }

    private var header: some View {
        ZStack {
            Text("Choose background")
                .font(themeStore.bold(18))
                .foregroundStyle(themeStore.mainText)

            HStack {
                if isSheet {
                    CloseButton()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isSheet ? 16 : 8)
        .padding(.bottom, 8)
    }

    private func previewStage(palette: ThemeStore.Palette) -> some View {
        let c = ThemeStore.previewColors(for: palette)

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(c.mainAccentColor.opacity(0.22))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(c.mainAccentColor)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(c.mainText.opacity(0.35)).frame(width: 96, height: 8)
                        Capsule().fill(c.secondaryText.opacity(0.3)).frame(width: 64, height: 6)
                    }
                    Spacer(minLength: 0)
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

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(c.appBg)
            )
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
        }
    }

    private func glassMiniCard(_ c: ThemeStore.PreviewColors) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(c.cardBg.opacity(c.isGlass ? 0.35 : 0.72))
            .frame(height: 64)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Capsule().fill(c.mainText.opacity(0.28)).frame(width: 40, height: 6)
                    Capsule().fill(c.secondaryText.opacity(0.25)).frame(width: 56, height: 5)
                }
                .padding(.leading, 14)
            }
    }

    private func glassPlate(_ c: ThemeStore.PreviewColors) -> some View {
        RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
            .fill(c.cardBg.opacity(c.isGlass ? 0.3 : 0.55))
    }

    private func wordPreviewCard(_ c: ThemeStore.PreviewColors, muted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(c.cardBg.opacity(muted ? 0.85 : 1))
        )
    }

    private var setButton: some View {
        let isCurrent = themeStore.palette == selectedPalette
        let c = ThemeStore.previewColors(for: selectedPalette)

        return Button {
            Haptics.menuTap()
            guard isPremium else {
                showPremiumWall = true
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                themeStore.set(selectedPalette)
            }
            dismiss()
        } label: {
            Group {
                if isCurrent {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                        Text("Current background")
                    }
                } else if !isPremium {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Set background")
                    }
                } else {
                    Text("Set background")
                }
            }
            .duo3DStyle(
                isCurrent ? themeStore.secondaryText.opacity(0.55) : c.mainAccentColor,
                isDisabled: isCurrent
            )
        }
        .buttonStyle(Duo3DButtonStyle())
        .disabled(isCurrent)
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
    ThemePickerView(isSheet: true)
        .environmentObject(ThemeStore())
}
