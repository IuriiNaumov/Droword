import SwiftUI

struct SettingsBackButton: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(themeStore.mainAccentColor)
        }
        .buttonStyle(.plain)
    }
}
