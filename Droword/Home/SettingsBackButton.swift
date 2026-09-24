import SwiftUI

struct SettingsBackButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            Haptics.menuTap()
            dismiss()
        } label: {
            MenuSymbol(
                systemName: "chevron.left",
                color: themeStore.mainText,
                size: 14,
                weight: .semibold,
                frameSize: 22
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Back"))
    }
}

#Preview {
    SettingsBackButton()
        .padding()
        .environmentObject(ThemeStore())
}
