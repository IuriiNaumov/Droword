import SwiftUI

struct AppearancePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue

    private var selected: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Appearance")
                    .sheetTitle()

                HStack(alignment: .top, spacing: 12) {
                    ForEach(AppAppearance.allCases, id: \.self) { option in
                        appearanceCard(option: option, isSelected: selected == option) {
                            storedAppearance = option.rawValue
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
        }
    }

    private func appearanceCard(option: AppAppearance, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                previewBlock(for: option, isSelected: isSelected)
                    .aspectRatio(200.0 / 340.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.6), lineWidth: isSelected ? 2 : 1)
                    )

                Text(option.title)
                    .font(themeStore.medium(14))
                    .foregroundStyle(themeStore.mainText)

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
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func previewBlock(for option: AppAppearance, isSelected: Bool) -> some View {
        switch option {
        case .light:
            singlePreview(isDark: false)
        case .dark:
            singlePreview(isDark: true)
        case .system:
            systemPreview()
        }
    }

    private func systemPreview() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                singlePreview(isDark: false)
                    .frame(width: w, height: h)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Color.black
                            Color.clear
                        }
                    )

                singlePreview(isDark: true)
                    .frame(width: w, height: h)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Color.clear
                            Color.black
                        }
                    )
            }
        }
    }

    private func singlePreview(isDark: Bool) -> some View {
        let bg = isDark
            ? Color(hex: "#1C1C1E")
            : Color(hex: "#F2F2F7")
        let element = isDark
            ? Color(hex: "#3A3A3C")
            : Color(hex: "#C7C7CC")
        let card = isDark
            ? Color(hex: "#2C2C2E")
            : Color(hex: "#E5E5EA")

        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sx = w / 200.0
            let sy = h / 340.0

            ZStack(alignment: .topLeading) {
                bg

                Circle()
                    .fill(element)
                    .frame(width: 44 * sx, height: 44 * sy)
                    .offset(x: (44 - 22) * sx, y: (60 - 22) * sy)

                RoundedRectangle(cornerRadius: 5 * sx, style: .continuous)
                    .fill(element)
                    .frame(width: 52 * sx, height: 10 * sy)
                    .offset(x: 78 * sx, y: 48 * sy)

                RoundedRectangle(cornerRadius: 5 * sx, style: .continuous)
                    .fill(element)
                    .frame(width: 84 * sx, height: 10 * sy)
                    .offset(x: 78 * sx, y: 64 * sy)

                Rectangle()
                    .fill(card)
                    .frame(width: 160 * sx, height: max(1, 1 * sy))
                    .offset(x: 20 * sx, y: 100 * sy)

                RoundedRectangle(cornerRadius: 12 * sx, style: .continuous)
                    .fill(card)
                    .frame(width: 160 * sx, height: 44 * sy)
                    .offset(x: 20 * sx, y: 116 * sy)

                RoundedRectangle(cornerRadius: 12 * sx, style: .continuous)
                    .fill(card)
                    .frame(width: 160 * sx, height: 44 * sy)
                    .offset(x: 20 * sx, y: 172 * sy)

                RoundedRectangle(cornerRadius: 12 * sx, style: .continuous)
                    .fill(card)
                    .frame(width: 160 * sx, height: 44 * sy)
                    .offset(x: 20 * sx, y: 228 * sy)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearancePickerView()
            .environmentObject(ThemeStore())
    }
}
