import SwiftUI

struct DailyLessonSessionView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var badgeStore: BadgeStore

    let plan: DailyLessonPlan

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(plan.title)
                    .font(themeStore.bold(16))
                    .foregroundStyle(themeStore.mainText)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)

                if plan.canStart {
                    QuizMixedView(
                        sessionSize: plan.words.count,
                        persistSession: false,
                        presetWords: plan.words,
                        recordsLesson: true
                    )
                } else {
                    PracticeEmptyContent(
                        illustration: AnyView(EmptyPracticeArt()),
                        icon: "rectangle.stack.badge.plus",
                        title: String(localized: "Need a few more words"),
                        subtitle: String(localized: "Add at least 4 words with translations and this lesson unlocks."),
                        tip: String(localized: "Tag them with your topics so the next lesson hits harder.")
                    )
                }
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
    }
}
