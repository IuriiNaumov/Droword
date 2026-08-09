import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @AppStorage(AppStorageKeys.currentStreak) private var currentStreak: Int = 0
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
                Text("Achievements")
                    .sheetTitle()

                VStack(spacing: 6) {
                    Text("\(unlockedCount)/\(BadgeStore.allBadges.count)")
                        .font(themeStore.bold(32))
                        .foregroundStyle(themeStore.mainText)

                    Text("achievements unlocked")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                }

                ForEach(BadgeCategory.allCases, id: \.rawValue) { category in
                    let badges = BadgeStore.allBadges.filter { $0.category == category }
                    if !badges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.title)
                                .font(themeStore.bold(18))
                                .foregroundStyle(.primary)
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
            .padding(.bottom, 40)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }
}


