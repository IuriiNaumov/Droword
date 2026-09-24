import SwiftUI

/// System-style list disclosure chevron (Telegram / iOS Settings gray ›).
struct DisclosureChevron: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var opacity: Double = 0.45

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(themeStore.secondaryText.opacity(opacity))
            .frame(width: 28, height: 28, alignment: .center)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        Text("Row")
        Spacer()
        DisclosureChevron()
    }
    .padding()
    .environmentObject(ThemeStore())
}
