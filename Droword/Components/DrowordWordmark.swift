import SwiftUI

struct DrowordWordmark: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var size: CGFloat = 48

    var body: some View {
        Text("droword")
            .font(themeStore.display(size))
            .kerning(-size / 30)
            .accessibilityLabel(Text("Droword"))
    }
}

#Preview {
    VStack(spacing: 24) {
        DrowordWordmark()
        DrowordWordmark(size: 22)
    }
    .padding()
    .environmentObject(ThemeStore())
}
