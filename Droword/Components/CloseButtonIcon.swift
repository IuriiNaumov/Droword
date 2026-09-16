import SwiftUI

struct CloseButtonIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(themeStore.mainAccentColor)
            .accessibilityLabel(Text("Close"))
    }
}

struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                dismiss()
            }
        } label: {
            CloseButtonIcon()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close"))
    }
}
