import SwiftUI

struct TagBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Poppins-Medium", size: 14))
            .foregroundColor(themeStore.mainText)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
