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

                HStack(alignment: .top, spacing: 12) {
                    ForEach(ThemeStore.Palette.allCases) { palette in
                        themeCard(palette: palette, isSelected: themeStore.palette == palette) {
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

    private func themeCard(palette: ThemeStore.Palette, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                themePreview(for: palette)
                    .aspectRatio(200.0 / 340.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.6), lineWidth: isSelected ? 2 : 1)
                    )

                Text(palette.title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(themeStore.mainText)

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
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func themePreview(for palette: ThemeStore.Palette) -> some View {
        let colors = previewColors(for: palette)
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sx = w / 200.0
            let sy = h / 340.0

            ZStack(alignment: .topLeading) {
                colors.bg

                RoundedRectangle(cornerRadius: 16 * sx, style: .continuous)
                    .fill(colors.card)
                    .frame(width: 32 * sx, height: 32 * sy)
                    .offset(x: 16 * sx, y: 16 * sy)

                RoundedRectangle(cornerRadius: 5 * sx, style: .continuous)
                    .fill(colors.title)
                    .frame(width: 72 * sx, height: 10 * sy)
                    .offset(x: 58 * sx, y: 20 * sy)

                RoundedRectangle(cornerRadius: 3.5 * sx, style: .continuous)
                    .fill(colors.subtitle)
                    .frame(width: 50 * sx, height: 7 * sy)
                    .offset(x: 58 * sx, y: 36 * sy)

                Rectangle()
                    .fill(colors.subtitle.opacity(0.5))
                    .frame(width: 168 * sx, height: max(1, 1 * sy))
                    .offset(x: 16 * sx, y: 60 * sy)

                RoundedRectangle(cornerRadius: 10 * sx, style: .continuous)
                    .fill(colors.card)
                    .frame(width: 168 * sx, height: 42 * sy)
                    .offset(x: 16 * sx, y: 74 * sy)
                RoundedRectangle(cornerRadius: 4 * sx, style: .continuous)
                    .fill(colors.title)
                    .frame(width: 60 * sx, height: 8 * sy)
                    .offset(x: 28 * sx, y: 86 * sy)
                RoundedRectangle(cornerRadius: 3 * sx, style: .continuous)
                    .fill(colors.subtitle)
                    .frame(width: 38 * sx, height: 6 * sy)
                    .offset(x: 28 * sx, y: 100 * sy)
                Capsule()
                    .fill(colors.accent1)
                    .frame(width: 28 * sx, height: 16 * sy)
                    .offset(x: 144 * sx, y: 87 * sy)

                RoundedRectangle(cornerRadius: 10 * sx, style: .continuous)
                    .fill(colors.card)
                    .frame(width: 168 * sx, height: 42 * sy)
                    .offset(x: 16 * sx, y: 125 * sy)
                RoundedRectangle(cornerRadius: 4 * sx, style: .continuous)
                    .fill(colors.title)
                    .frame(width: 60 * sx, height: 8 * sy)
                    .offset(x: 28 * sx, y: 137 * sy)
                RoundedRectangle(cornerRadius: 3 * sx, style: .continuous)
                    .fill(colors.subtitle)
                    .frame(width: 38 * sx, height: 6 * sy)
                    .offset(x: 28 * sx, y: 151 * sy)
                Capsule()
                    .fill(colors.accent2)
                    .frame(width: 28 * sx, height: 16 * sy)
                    .offset(x: 144 * sx, y: 138 * sy)

                RoundedRectangle(cornerRadius: 10 * sx, style: .continuous)
                    .fill(colors.card)
                    .frame(width: 168 * sx, height: 42 * sy)
                    .offset(x: 16 * sx, y: 176 * sy)
                RoundedRectangle(cornerRadius: 4 * sx, style: .continuous)
                    .fill(colors.title)
                    .frame(width: 60 * sx, height: 8 * sy)
                    .offset(x: 28 * sx, y: 188 * sy)
                RoundedRectangle(cornerRadius: 3 * sx, style: .continuous)
                    .fill(colors.subtitle)
                    .frame(width: 38 * sx, height: 6 * sy)
                    .offset(x: 28 * sx, y: 202 * sy)
                Capsule()
                    .fill(colors.accent3)
                    .frame(width: 28 * sx, height: 16 * sy)
                    .offset(x: 144 * sx, y: 189 * sy)

                RoundedRectangle(cornerRadius: 10 * sx, style: .continuous)
                    .fill(colors.button)
                    .frame(width: 168 * sx, height: 40 * sy)
                    .offset(x: 16 * sx, y: 284 * sy)
                RoundedRectangle(cornerRadius: 4 * sx, style: .continuous)
                    .fill(colors.bg)
                    .frame(width: 56 * sx, height: 8 * sy)
                    .offset(x: 72 * sx, y: 300 * sy)
            }
        }
    }

    private struct PreviewColors {
        let bg: Color
        let card: Color
        let title: Color
        let subtitle: Color
        let accent1: Color
        let accent2: Color
        let accent3: Color
        let button: Color
    }

    private func previewColors(for palette: ThemeStore.Palette) -> PreviewColors {
        switch palette {
        case .colorful:
            return PreviewColors(
                bg: Color(hex: "#F2F2F7"),
                card: Color(hex: "#E5E5EA"),
                title: Color(hex: "#3D3D3D"),
                subtitle: Color(hex: "#AEAEB2"),
                accent1: Color(hex: "#5B9BD5"),
                accent2: Color(hex: "#D86B94"),
                accent3: Color(hex: "#EBA130"),
                button: Color(hex: "#3D3D3D")
            )
        case .duolingo:
            return PreviewColors(
                bg: Color(hex: "#F2F2F7"),
                card: Color(hex: "#E5E5EA"),
                title: Color(hex: "#3D3D3D"),
                subtitle: Color(hex: "#AEAEB2"),
                accent1: Color(hex: "#58CC02"),
                accent2: Color(hex: "#2EC4B6"),
                accent3: Color(hex: "#CE82FF"),
                button: Color(hex: "#58CC02")
            )
        case .monochrome:
            return PreviewColors(
                bg: Color(hex: "#F2F2F7"),
                card: Color(hex: "#E5E5EA"),
                title: Color(hex: "#3D3D3D"),
                subtitle: Color(hex: "#AEAEB2"),
                accent1: Color(hex: "#AEAEB2"),
                accent2: Color(hex: "#AEAEB2"),
                accent3: Color(hex: "#AEAEB2"),
                button: Color(hex: "#3D3D3D")
            )
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
