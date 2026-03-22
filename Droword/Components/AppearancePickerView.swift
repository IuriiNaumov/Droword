import SwiftUI

struct AppearancePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.system.rawValue

    private var selected: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Text("Appearance")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    ForEach(AppAppearance.allCases, id: \.self) { option in
                        appearanceBlock(option: option, isSelected: selected == option) {
                            storedAppearance = option.rawValue
                            Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(themeStore.appBg.ignoresSafeArea())
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

    private func appearanceBlock(option: AppAppearance, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(previewBg(option))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? themeStore.buttonAccent : themeStore.dividerColor, lineWidth: isSelected ? 2 : 1)
                        )

                    if option == .system {
                        HStack(spacing: 0) {
                            Color(red: 0.93, green: 0.93, blue: 0.93)
                            Color(red: 0.11, green: 0.11, blue: 0.12)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? themeStore.buttonAccent : themeStore.dividerColor, lineWidth: isSelected ? 2 : 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Circle()
                            .fill(mockAccent(option))
                            .frame(width: 16, height: 16)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(mockLine(option))
                            .frame(width: 50, height: 8)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(mockLine(option).opacity(0.7))
                            .frame(width: 36, height: 8)

                        Spacer().frame(height: 4)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(mockCard(option))
                            .frame(width: 58, height: 28)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(mockCard(option).opacity(0.85))
                            .frame(width: 58, height: 28)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(height: 160)

                Text(option.title)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.primary)

                ZStack {
                    Circle()
                        .stroke(isSelected ? themeStore.buttonAccent : themeStore.secondaryText.opacity(0.4), lineWidth: 1.5)
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

    private func previewBg(_ style: AppAppearance) -> Color {
        switch style {
        case .system: return .clear
        case .light: return Color(red: 0.93, green: 0.93, blue: 0.93)
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }

    private func mockAccent(_ style: AppAppearance) -> Color {
        switch style {
        case .system, .light: return Color(red: 0.78, green: 0.78, blue: 0.82)
        case .dark: return Color(red: 0.22, green: 0.24, blue: 0.28)
        }
    }

    private func mockLine(_ style: AppAppearance) -> Color {
        switch style {
        case .system, .light: return Color(red: 0.72, green: 0.73, blue: 0.76)
        case .dark: return Color(red: 0.20, green: 0.22, blue: 0.26)
        }
    }

    private func mockCard(_ style: AppAppearance) -> Color {
        switch style {
        case .system, .light: return Color(red: 0.82, green: 0.82, blue: 0.85)
        case .dark: return Color(red: 0.17, green: 0.18, blue: 0.21)
        }
    }
}

#Preview {
    NavigationStack {
        AppearancePickerView()
    }
}
