import SwiftUI

struct BadgeCardView: View {
    let badge: BadgeDefinition
    let currentProgress: Int
    let isUnlocked: Bool
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            Text(badge.emoji)
                .font(.system(size: 32))
                .grayscale(isUnlocked ? 0 : 1.0)
                .opacity(isUnlocked ? 1.0 : 0.4)

                .scaleEffect(appeared ? 1.0 : 0.6)

            Text(badge.title)
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(isUnlocked ? themeStore.mainText : themeStore.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isUnlocked {
                Text(badge.description)
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundColor(themeStore.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            } else {
                let ratio = min(1.0, Double(currentProgress) / Double(max(1, badge.requiredCount)))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(themeStore.secondaryText.opacity(0.15))
                            .frame(height: 4)
                        Capsule()
                            .fill(themeStore.accentBlue)
                            .frame(width: geo.size.width * ratio, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 4)

                Text("\(currentProgress)/\(badge.requiredCount)")
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundColor(themeStore.secondaryText)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isUnlocked ? themeStore.accentGold.opacity(0.3) : themeStore.dividerColor, lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
    }
}
