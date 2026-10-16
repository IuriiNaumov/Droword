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
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

    var onCloseResults: (() -> Void)? = nil

    @State private var hasEnoughWords: Bool = false
    @State private var showingResults: Bool = false

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                if !showingResults {
                    header
                        .padding(.bottom, 8)
                }

                if hasEnoughWords {
                    QuizMixedView(
                        sessionSize: 10,
                        onClose: {
                            showingResults = false
                            tabBarVisibility.show()
                            onCloseResults?()
                        },
                        onCompleteChange: { complete in
                            showingResults = complete
                            if complete {
                                tabBarVisibility.hide()
                            } else {
                                tabBarVisibility.show()
                            }
                        }
                    )
                } else {
                    practiceEmptyState
                }
            }
            .iPadContentWidth()
        }
        .onAppear {
            recalcHasEnough()
            if showingResults {
                tabBarVisibility.hide()
            }
        }
        .onChange(of: store.words.count) { recalcHasEnough() }
        .onDisappear {
            if showingResults {
                tabBarVisibility.show()
            }
        }
    }

    private func recalcHasEnough() {
        hasEnoughWords = store.words.filter { $0.translation != nil && !$0.translation!.isEmpty }.count >= 4
    }

    private var header: some View {
        HStack {
            Text("Practice")
                .zoomerTitle(38)
                .environmentObject(themeStore)

            Spacer()
        }
        .padding(.horizontal, DesignSpacing.screenInset)
        .padding(.top, DesignSpacing.titleTop)
        .transaction { $0.animation = nil }
    }

    private var practiceEmptyState: some View {
        let copy = DuoChaosCopy.practiceEmpty()
        return PracticeEmptyContent(
            illustration: AnyView(EmptyPracticeArt()),
            icon: "rectangle.stack.badge.plus",
            title: copy.title,
            subtitle: copy.subtitle,
            ctaTitle: "Add a word",
            onCTA: {
                NotificationCenter.default.post(name: .openAddWord, object: nil)
            }
        )
    }
}

#Preview {
    PracticeView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
        .environmentObject(TabBarVisibility())
}
