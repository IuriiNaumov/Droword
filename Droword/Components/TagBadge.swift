import SwiftUI

struct TagBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let text: String

    var body: some View {
        Text(text)
            .font(themeStore.bold(12))
            .foregroundStyle(themeStore.colorForTag(text))
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(themeStore.colorForTag(text).opacity(0.2))
            )
    }
}
