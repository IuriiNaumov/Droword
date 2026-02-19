import SwiftUI

struct OnboardingLanguagePage: View {
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
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

#Preview("Light") {
    let store = LanguageStore()
    store.nativeLanguage = "English"
    store.learningLanguage = "Español"
    return OnboardingLanguagePage()
        .environmentObject(store)
}

#Preview("Dark") {
    let store = LanguageStore()
    store.nativeLanguage = "English"
    store.learningLanguage = "Español"
    return OnboardingLanguagePage()
        .environmentObject(store)
        .preferredColorScheme(.dark)
}
