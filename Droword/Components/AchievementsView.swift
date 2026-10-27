import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore
    @AppStorage(AppStorageKeys.currentStreak) private var currentStreak: Int = 0
    @Environment(\.dismiss) private var dismiss
    var previewAllUnlocked: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var visibleBadges: [BadgeDefinition] {
        BadgeStore.allBadges.filter { previewAllUnlocked || FeatureGates.streakEnabled || $0.category != .streak }
    }

    private var unlockedCount: Int {
        if previewAllUnlocked { return visibleBadges.count }
        return visibleBadges.filter {
            badgeStore.isUnlocked($0, totalWords: store.totalWordsAdded, currentStreak: currentStreak)
        }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Achievements")
                    .sheetTitle()

                VStack(spacing: 6) {
                    Text("\(unlockedCount)/\(visibleBadges.count)")
                        .font(themeStore.bold(32))
                        .foregroundStyle(themeStore.mainText)

                    Text("achievements unlocked")
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                }

                ForEach(BadgeCategory.allCases.filter { previewAllUnlocked || FeatureGates.streakEnabled || $0 != .streak }, id: \.rawValue) { category in
                    let badges = BadgeStore.allBadges.filter { $0.category == category }
                    if !badges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.title)
                                .font(themeStore.bold(18))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, DesignSpacing.screenInset)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(badges) { badge in
                                    BadgeCardView(
                                        badge: badge,
                                        currentProgress: previewAllUnlocked
                                            ? badge.requiredCount
                                            : badgeStore.progress(for: badge, totalWords: store.totalWordsAdded, currentStreak: currentStreak),
                                        isUnlocked: previewAllUnlocked
                                            || badgeStore.isUnlocked(badge, totalWords: store.totalWordsAdded, currentStreak: currentStreak)
                                    )
                                }
                            }
                            .padding(.horizontal, DesignSpacing.screenInset)
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

#Preview {
    AchievementsView()
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .environmentObject(BadgeStore())
}
