import SwiftUI

struct OnboardingLanguagePage: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
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

/// Dedicated onboarding step for picking the proficiency level as a tile grid.
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
                    .padding(.horizontal)

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
}

#Preview("Level") {
    let store = LanguageStore()
    store.learningLanguage = "日本語"
    return OnboardingLevelPage()
        .environmentObject(store)
        .environmentObject(ThemeStore())
}

#Preview("Dark") {
    let store = LanguageStore()
    store.nativeLanguage = "English"
    store.learningLanguage = "Español"
    return OnboardingLanguagePage()
        .environmentObject(store)
        .preferredColorScheme(.dark)
}
