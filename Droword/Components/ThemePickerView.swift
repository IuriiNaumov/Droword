import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var showPremiumWall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Theme")
                    .sheetTitle()

                VStack(spacing: 12) {
                    ForEach(ThemeStore.Palette.allCases) { palette in
                        themeRow(palette: palette, isSelected: themeStore.palette == palette) {
                            guard isPremium else {
                                showPremiumWall = true
                                return
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                themeStore.set(palette)
                            }
                            Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.bottom, 20)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPremiumWall) {
                PremiumView(asWall: true)
                    .environmentObject(themeStore)
                    .tint(themeStore.mainAccentColor)
            }
        }
    }

    private func themeRow(palette: ThemeStore.Palette, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Color dots
                HStack(spacing: 6) {
                    ForEach(accentColors(for: palette), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                }

                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(palette.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(themeStore.mainText)

                    Text(palette.subtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(themeStore.secondaryText)
                }

                Spacer()

                // Radio button
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
