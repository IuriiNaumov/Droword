import SwiftUI

struct QuizNotEnoughView: View {
    var body: some View {
        PracticeEmptyContent(
            illustration: AnyView(EmptyPracticeArt()),
            icon: "rectangle.stack.badge.plus",
            title: String(localized: "Not enough words yet"),
            subtitle: String(localized: "Add at least 4 words with translations to start practicing. Every word counts!"),
            tip: String(localized: "Four words unlock practice"),
            ctaTitle: "Add a word",
            onCTA: {
                NotificationCenter.default.post(name: .openAddWord, object: nil)
            }
        )
    }
}

#Preview {
    QuizNotEnoughView()
        .environmentObject(ThemeStore())
}
