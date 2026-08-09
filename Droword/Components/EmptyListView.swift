import SwiftUI

struct EmptyListView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var icon: String = "text.badge.plus"
    var title: LocalizedStringKey = "Your word garden is waiting"
    var subtitle: LocalizedStringKey = "Add a couple of words — and we'll begin the journey."
    var tip: LocalizedStringKey? = nil

    @State private var iconScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(themeStore.secondaryText.opacity(0.35))
                .scaleEffect(iconScale)

            Text(title)
                .font(themeStore.medium(18))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)

            Text(subtitle)
                .font(themeStore.regular(14))
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            if let tip {
                Text(tip)
                    .font(themeStore.regular(13))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

#Preview {
    EmptyListView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EmptyListView()
        .preferredColorScheme(.dark)
}
