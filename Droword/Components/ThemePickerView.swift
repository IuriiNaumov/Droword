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
                    ForEach(ThemeStore.Palette.allCases) { palette in
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
                .fill(themeStore.cardBg)
        )
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
                    .fill(themeStore.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? themeStore.mainAccentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func accentColors(for palette: ThemeStore.Palette) -> [Color] {
        switch palette {
        case .colorful:
            return [Color(hex: "#5B9BD5"), Color(hex: "#D86B94"), Color(hex: "#EBA130")]
        case .duolingo:
            return [Color(hex: "#58CC02"), Color(hex: "#2EC4B6"), Color(hex: "#CE82FF")]
        case .monochrome:
            return [Color(hex: "#8E8E93"), Color(hex: "#AEAEB2"), Color(hex: "#3D3D3D")]
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
