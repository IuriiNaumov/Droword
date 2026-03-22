import SwiftUI

struct PracticeEmptyContent: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let icon: String
    let title: String
    let subtitle: String
    let tip: String

    @State private var iconScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(themeStore.secondaryText.opacity(0.35))
                .scaleEffect(iconScale)

            Text(title)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)

            Text(subtitle)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            Text(tip)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
                subtitleOpacity = 1.0
            }
        }
    }
}
