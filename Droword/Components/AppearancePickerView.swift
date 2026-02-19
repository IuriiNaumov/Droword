import SwiftUI

private struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct AppearancePickerView: View {
    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.light.rawValue

    private var selected: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .light
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Appearance")
                .font(.custom("Poppins-Bold", size: 26))
                .foregroundColor(.mainBlack)
                .padding(.top, 12)

            HStack(spacing: 16) {
                ForEach(AppAppearance.allCases, id: \.self) { option in
                    AppearanceCard(
                        title: option.title,
                        style: option,
                        isSelected: selected == option
                    ) {
                        storedAppearance = option.rawValue
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .animation(nil, value: storedAppearance)
        .padding(.bottom, 14)
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(selected.colorScheme)
    }
}

private struct PreferredColorSchemeModifier: ViewModifier {
    let appAppearance: AppAppearance

    func body(content: Content) -> some View {
        switch appAppearance {
        case .light:
            content.preferredColorScheme(.light)
        case .dark:
            content.preferredColorScheme(.dark)
        }
    }
}

private struct AppearanceCard: View {
    let title: String
    let style: AppAppearance
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                preview
                    .frame(width: 90, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.primary)

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.toastAndButtons : Color.mainGrey, lineWidth: 1)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(Color.toastAndButtons)
                            .frame(width: 28, height: 28)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 2)
                .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isSelected)
            }
            .frame(width: 104)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isSelected)
        }
        .buttonStyle(NoHighlightButtonStyle())
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(previewBackground)
            
            VStack(alignment: .leading, spacing: 8) {
                Circle()
                    .fill(previewAvatar)
                    .frame(width: 18, height: 18)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 7) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(previewLine)
                        .frame(width: 54, height: 10)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(previewLine.opacity(0.9))
                        .frame(width: 42, height: 10)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(previewBlock)
                        .frame(width: 60, height: 34)
                        .padding(.top, 6)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(previewBlock.opacity(0.95))
                        .frame(width: 60, height: 34)
                }
            }
        }
        .animation(nil, value: isSelected)
    }

    private var previewBackground: Color {
        switch style {
        case .light: return Color(hexRGB: 0xEEEEEE)
        case .dark: return Color(hexRGB: 0x1C1C1E)
        }
    }

    private var previewAvatar: Color {
        switch style {
        case .light: return Color(hexRGB: 0xC9CBD1)
        case .dark: return Color(hexRGB: 0x2B2E34)
        }
    }

    private var previewLine: Color {
        switch style {
        case .light: return Color(hexRGB: 0xB7BAC1)
        case .dark: return Color(hexRGB: 0x2C3139)
        }
    }

    private var previewBlock: Color {
        switch style {
        case .light: return Color(hexRGB: 0xC9CBD1)
        case .dark: return Color(hexRGB: 0x22262D)
        }
    }
}

#Preview {
    AppearancePickerView()
}

#Preview("Light") {
    AppearancePickerView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AppearancePickerView()
        .preferredColorScheme(.dark)
}
