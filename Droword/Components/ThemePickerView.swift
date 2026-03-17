import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var showPremiumWall = false

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
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func themeBlock(palette: ThemeStore.Palette) -> some View {
        let isSelected = themeStore.palette == palette
        let colors = previewColors(for: palette)

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
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(previewBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? themeStore.buttonAccent : Color.divider, lineWidth: isSelected ? 2 : 1)
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

                ZStack {
                    Circle()
                        .stroke(isSelected ? themeStore.buttonAccent : Color.mainGrey.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(themeStore.buttonAccent)
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

    private func previewColors(for palette: ThemeStore.Palette) -> (Color, Color, Color, Color, Color) {
        switch palette {
        case .colorful:
            return (
                Color(red: 0.60, green: 0.76, blue: 0.95),
                Color(red: 0.58, green: 0.84, blue: 0.70),
                Color(red: 0.93, green: 0.82, blue: 0.55),
                Color(red: 0.72, green: 0.64, blue: 0.90),
                Color(red: 0.93, green: 0.65, blue: 0.70)
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
