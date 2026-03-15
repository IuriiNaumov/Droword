import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var unlockedCount: Int {
        BadgeStore.allBadges.filter {
            badgeStore.isUnlocked($0, totalWords: store.totalWordsAdded, currentStreak: currentStreak)
        }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("\(unlockedCount)/\(BadgeStore.allBadges.count)")
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundColor(.mainBlack)

                    Text("achievements unlocked")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)
                }
                .padding(.top, 12)

                ForEach(BadgeCategory.allCases, id: \.rawValue) { category in
                    let badges = BadgeStore.allBadges.filter { $0.category == category }
                    if !badges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.title)
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(.mainBlack)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(badges) { badge in
                                    BadgeCardView(
                                        badge: badge,
                                        currentProgress: badgeStore.progress(for: badge, totalWords: store.totalWordsAdded, currentStreak: currentStreak),
                                        isUnlocked: badgeStore.isUnlocked(badge, totalWords: store.totalWordsAdded, currentStreak: currentStreak)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Achievements")
                    .font(.custom("Poppins-Bold", size: 18))
            }
        }
    }
}

private struct BadgeCardView: View {
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
                .shadow(color: isUnlocked ? themeStore.accentGold.opacity(0.5) : .clear, radius: 8)
                .scaleEffect(appeared ? 1.0 : 0.6)

            Text(badge.title)
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(isUnlocked ? .mainBlack : .mainGrey)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isUnlocked {
                Text(badge.description)
                    .font(.custom("Poppins-Regular", size: 9))
                    .foregroundColor(.mainGrey)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            } else {
                let ratio = min(1.0, Double(currentProgress) / Double(max(1, badge.requiredCount)))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mainGrey.opacity(0.15))
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
                    .foregroundColor(.mainGrey)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isUnlocked ? themeStore.accentGold.opacity(0.3) : Color.divider, lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
    }
}
