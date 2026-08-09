import SwiftUI

struct RadioButtonRow: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(themeStore.secondaryText.opacity(0.4), lineWidth: 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(themeStore.mainAccentColor)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Text(title)
                    .font(themeStore.regular(15))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
