import SwiftUI

struct CloseButtonIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(themeStore.mainText)
    }
}
