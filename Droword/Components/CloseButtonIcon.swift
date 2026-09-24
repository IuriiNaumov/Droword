import SwiftUI

struct CloseButtonIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        MenuSymbol(
            systemName: "xmark",
            color: themeStore.mainText,
            size: 14,
            weight: .semibold,
            frameSize: 22
        )
        .accessibilityLabel(Text("Close"))
    }
}

struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            Haptics.menuTap()
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

#Preview {
    HStack(spacing: 20) {
        CloseButtonIcon()
        CloseButton()
    }
    .padding()
    .environmentObject(ThemeStore())
}
