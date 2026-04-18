import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var showPremiumWall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Text("Theme")
                    .sheetTitle()

                wordCardPreview
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: themeStore.palette)

                // Theme selector
                VStack(spacing: 10) {
                    ForEach(availablePalettes) { palette in
                        themeOption(palette: palette)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    // MARK: - Word Card Preview

    private var wordCardPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag badge
            Text("Travel")
                .font(themeStore.medium(13))
                .foregroundColor(themeStore.accentBlue)
                .padding(.vertical, 4)
                .padding(.horizontal, 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(themeStore.accentBlue, lineWidth: 1)
                )
                .padding(.bottom, 2)

            Text("Serendipity")
                .font(themeStore.bold(24))
                .foregroundColor(themeStore.mainText)

            Text("/ˌsɛr.ənˈdɪp.ɪ.ti/")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.mainText.opacity(0.8))

            Text("Noun")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.mainText.opacity(0.8))
                .padding(.bottom, 2)

            Text("Счастливая случайность")
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.mainText)

            Text("Finding that book was pure serendipity.")
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.mainText)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 20))
        .shadow(color: themeStore.cardShadowColor, radius: themeStore.cardShadowRadius, x: 0, y: 3)
    }

    // MARK: - Theme Option

    private func themeOption(palette: ThemeStore.Palette) -> some View {
        let isSelected = themeStore.palette == palette

        return Button {
            guard isPremium else {
                showPremiumWall = true
                return
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                themeStore.set(palette)
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 14) {
                // Color dots
                HStack(spacing: 6) {
                    ForEach(accentColors(for: palette), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(palette.title)
                        .font(themeStore.bold(16))
                        .foregroundColor(themeStore.mainText)

                    Text(palette.subtitle)
                        .font(themeStore.regular(13))
                        .foregroundColor(themeStore.secondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(themeStore.mainAccentColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? themeStore.mainAccentColor : Color.clear, lineWidth: 1.5)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
        }
        .buttonStyle(.plain)
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

    private func accentColors(for palette: ThemeStore.Palette) -> [Color] {
        switch palette {
        case .colorful:
            return [Color(hex: "#5B9BD5"), Color(hex: "#D86B94"), Color(hex: "#EBA130")]
        case .duolingo:
            return [Color(hex: "#58CC02"), Color(hex: "#2EC4B6"), Color(hex: "#CE82FF")]
        case .sunset:
            return [Color(hex: "#E8825C"), Color(hex: "#F0967A"), Color(hex: "#F0A850")]
        case .glass:
            return [Color(hex: "#007AFF"), Color(hex: "#AF52DE"), Color(hex: "#FF9500")]
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
