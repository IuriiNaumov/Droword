import SwiftUI

struct LanguagePreferencesView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var showToast = false
    @State private var toastType: AppToastType = .success
    @State private var toastMessage = ""
    @State private var toastID = UUID()

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Text("Language Preferences")
                        .sheetTitle()

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
                            showToastForChange()
                        }
                    )

                    LanguageCubePicker(
                        selectedLanguage: $languageStore.nativeLanguage,
                        title: "I speak",
                        languages: LanguageCatalog.availableLanguages,
                        blockedLanguage: languageStore.learningLanguage
                    )
                    .onChange(of: languageStore.nativeLanguage) {
                        showToastForChange()
                    }

                    LanguageCubePicker(
                        selectedLanguage: $languageStore.learningLanguage,
                        title: "I'm learning",
                        languages: LanguageCatalog.availableLanguages,
                        blockedLanguage: languageStore.nativeLanguage
                    )
                    .onChange(of: languageStore.learningLanguage) {
                        showToastForChange()
                    }
                }
                .padding(.bottom, 50)
            }
            .background(themeStore.appBg.ignoresSafeArea())
        }
    }

    private func showToastForChange() {
        let native = languageStore.nativeLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        let learning = languageStore.learningLanguage.trimmingCharacters(in: .whitespacesAndNewlines)

        if native.isEmpty || learning.isEmpty {
            toastType = .success
            toastMessage = "Language has been updated"
        } else if native == learning {
            toastType = .error
            toastMessage = "Oops! Something went wrong."
        } else {
            toastType = .success
            toastMessage = "Language has been updated"
        }

        toastID = UUID()
        showToast = true
    }
}
