import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Text("Theme")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    themeBlock(palette: .colorful)
                    themeBlock(palette: .duolingo)
                    themeBlock(palette: .monochrome)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private func themeBlock(palette: ThemeStore.Palette) -> some View {
        let isSelected = themeStore.palette == palette
        let colors = previewColors(for: palette)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                themeStore.set(palette)
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 12) {
                // Preview card
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(previewBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? Color.accentBlack : Color.divider, lineWidth: isSelected ? 2 : 1)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Circle()
                            .fill(colors.0)
                            .frame(width: 16, height: 16)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(colors.1)
                            .frame(width: 48, height: 7)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(colors.2)
                            .frame(width: 34, height: 7)

                        Spacer().frame(height: 2)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(colors.3)
                            .frame(width: 54, height: 24)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(colors.4)
                            .frame(width: 54, height: 24)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(height: 160)

                Text(palette.title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.primary)

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentBlack : Color.mainGrey.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(Color.accentBlack)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview colors per palette (avatar, line1, line2, card1, card2)

    private func previewColors(for palette: ThemeStore.Palette) -> (Color, Color, Color, Color, Color) {
        switch palette {
        case .colorful:
            return (
                Color(red: 0.35, green: 0.60, blue: 0.95),
                Color(red: 0.35, green: 0.75, blue: 0.55),
                Color(red: 0.90, green: 0.70, blue: 0.30),
                Color(red: 0.55, green: 0.45, blue: 0.85),
                Color(red: 0.90, green: 0.45, blue: 0.55)
            )
        case .duolingo:
            return (
                Color(hex: "#58CC02"),
                Color(hex: "#1CB0F6"),
                Color(hex: "#FFC800"),
                Color(hex: "#58CC02"),
                Color(hex: "#CE82FF")
            )
        case .monochrome:
            let mono = monoElement
            return (mono, mono.opacity(0.8), mono.opacity(0.6), mono.opacity(0.7), mono.opacity(0.5))
        }
    }

    // MARK: - Colors

    private var previewBg: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)
            : Color(red: 0.93, green: 0.93, blue: 0.93)
    }

    private var monoElement: Color {
        colorScheme == .dark
            ? Color(red: 0.30, green: 0.30, blue: 0.32)
            : Color(red: 0.72, green: 0.72, blue: 0.74)
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
