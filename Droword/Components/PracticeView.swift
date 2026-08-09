import SwiftUI

enum QuizDirection: String, CaseIterable {
    case normal = "Word → Translation"
    case reversed = "Translation → Word"
    case mixed = "Mixed"
}

struct PracticeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var hasEnoughWords: Bool = false

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 8)

                if hasEnoughWords {
                    QuizMixedView(sessionSize: 10)
                } else {
                    practiceEmptyState
                }
            }
            .iPadContentWidth()
        }
        .onAppear { recalcHasEnough() }
        .onChange(of: store.words.count) { recalcHasEnough() }
    }

    private func recalcHasEnough() {
        hasEnoughWords = store.words.filter { $0.translation != nil && !$0.translation!.isEmpty }.count >= 4
    }

    private var header: some View {
        HStack {
            Text("Practice")
                .font(themeStore.bold(38))
                .foregroundStyle(themeStore.mainText)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .transaction { $0.animation = nil }
    }

    private var practiceEmptyState: some View {
        PracticeEmptyContent(
            icon: "rectangle.stack.badge.plus",
            title: "Not enough words yet",
            subtitle: "Add at least 4 words with translations to start practicing.",
            tip: "Tip: grab words from movies, chats, or walks — learning feels alive that way."
        )
    }


}



#Preview {
    let store = WordsStore()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        store.clear()
        store.add(
            StoredWord(
                word: "No puedo creer lo que está pasando aquí",
                type: "adjective",
                translation: "Вкусный",
                example: "Este plato es muy sabroso y delicioso.",
                comment: "Моё любимое слово!",
                tag: "Suggested",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "chido",
                type: "adjective",
                translation: "Круто",
                example: "La fiesta estuvo chido y muy divertida.",
                comment: nil,
                tag: "Chat",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "食べ物",
                type: "noun",
                translation: "Еда",
                example: "この食べ物はとてもおいしいです。",
                comment: nil,
                tag: "Travel",
                fromLanguage: "ja",
                toLanguage: "ru"
            )
        )
    }
    return PracticeView()
        .environmentObject(store)
        .environmentObject(LanguageStore())
}
