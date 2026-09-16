import SwiftUI

struct OnboardingLanguagePage: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    LanguagePairHero(
                        nativeName: languageStore.nativeLanguage,
                        learningName: languageStore.learningLanguage,
                        onSwap: {
                            let native = languageStore.nativeLanguage
                            let learning = languageStore.learningLanguage
                            guard native != learning else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                languageStore.nativeLanguage = learning
                                languageStore.learningLanguage = native
                            }
                        }
                    )
                    .padding(.top, 8)

                    LanguageCubePicker(
                        selectedLanguage: $languageStore.nativeLanguage,
                        title: "I speak",
                        languages: LanguageCatalog.availableLanguages,
                        blockedLanguage: languageStore.learningLanguage
                    )

                    LanguageCubePicker(
                        selectedLanguage: $languageStore.learningLanguage,
                        title: "I’m learning",
                        languages: LanguageCatalog.availableLanguages,
                        blockedLanguage: languageStore.nativeLanguage
                    )
                }
                .padding(.top, 54)
                .padding(.bottom, 12)
            }
        }
    }
}

struct OnboardingLevelPage: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your level?")
                            .font(themeStore.bold(28))
                            .foregroundStyle(themeStore.mainText)
                        Text("We'll match examples to how much you already know.")
                            .font(themeStore.regular(15))
                            .foregroundStyle(themeStore.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)

                    LanguageLevelPicker(showTitle: false)
                }
                .padding(.top, 54)
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview("Light") {
    let store = LanguageStore()
    store.nativeLanguage = "English"
    store.learningLanguage = "Español"
    return OnboardingLanguagePage()
        .environmentObject(store)
        .environmentObject(ThemeStore())
}

#Preview("Level") {
    let store = LanguageStore()
    store.learningLanguage = "日本語"
    return OnboardingLevelPage()
        .environmentObject(store)
        .environmentObject(ThemeStore())
}
