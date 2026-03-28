import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var showPremiumWall = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Theme")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    themeCard(palette: .colorful)
                    themeCard(palette: .duolingo)
                    themeCard(palette: .monochrome)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(themeStore.appBg.ignoresSafeArea())
        
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func themeCard(palette: ThemeStore.Palette) -> some View {
        let isSelected = themeStore.palette == palette
        let tags = tagChips(for: palette)

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
                VStack(alignment: .leading, spacing: 8) {
                    Text(palette.title)
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(themeStore.mainText)

                    HStack(spacing: 6) {
                        ForEach(tags, id: \.label) { tag in
                            Text(tag.label)
                                .font(.custom("Poppins-Medium", size: 11))
                                .foregroundColor(tagTextColor(tag.color))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(tag.color.opacity(0.18))
                                )
                        }
                    }
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
                    .stroke(isSelected ? themeStore.mainAccentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private struct TagChip {
        let label: String
        let color: Color
    }

    private func tagChips(for palette: ThemeStore.Palette) -> [TagChip] {
        switch palette {
        case .colorful:
            return [
                TagChip(label: "Pastel", color: Color(hex: "#5B9BD5")),
                TagChip(label: "Soft", color: Color(hex: "#D86B94")),
                TagChip(label: "Warm", color: Color(hex: "#EBA130"))
            ]
        case .duolingo:
            return [
                TagChip(label: "Vivid", color: Color(hex: "#58CC02")),
                TagChip(label: "Bold", color: Color(hex: "#CE82FF")),
                TagChip(label: "Fun", color: Color(hex: "#2EC4B6"))
            ]
        case .monochrome:
            return [
                TagChip(label: "Minimal", color: Color(red: 0.45, green: 0.45, blue: 0.47)),
                TagChip(label: "Clean", color: Color(red: 0.55, green: 0.55, blue: 0.57)),
                TagChip(label: "Calm", color: Color(red: 0.40, green: 0.40, blue: 0.42))
            ]
        }
    }

    private func tagTextColor(_ color: Color) -> Color {
        colorScheme == .dark ? color.opacity(1) : color
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
