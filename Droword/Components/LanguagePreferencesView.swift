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
                VStack(spacing: 30) {
                    Text("Language Preferences")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(themeStore.mainText)
                        .padding(.top, 30)
                    
                    LanguageCubePicker(
                        selectedLanguage: $languageStore.nativeLanguage,
                        title: "I speak",
                        languages: Self.availableLanguages,
                        blockedLanguage: languageStore.learningLanguage
                    )
                    .onChange(of: languageStore.nativeLanguage) {
                        showToastForChange()
                    }
                    
                    LanguageCubePicker(
                        selectedLanguage: $languageStore.learningLanguage,
                        title: "I'm learning",
                        languages: Self.availableLanguages,
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
    
    static let availableLanguages = [
        LanguageOption(name: "English", flag: "🇬🇧", color: Color.accentBlue),
        LanguageOption(name: "Español", flag: "🇲🇽", color: Color.accentBlue),
        LanguageOption(name: "Русский", flag: "🇷🇺", color: Color.accentBlue),
        LanguageOption(name: "Français", flag: "🇫🇷", color: Color.accentBlue),
        LanguageOption(name: "Deutsch", flag: "🇩🇪", color: Color.accentBlue),
        LanguageOption(name: "Italiano", flag: "🇮🇹", color: Color.accentBlue),
        LanguageOption(name: "Português", flag: "🇧🇷", color: Color.accentBlue),
        LanguageOption(name: "한국어", flag: "🇰🇷", color: Color.accentBlue),
        LanguageOption(name: "中文", flag: "🇨🇳", color: Color.accentBlue),
        LanguageOption(name: "日本語", flag: "🇯🇵", color: Color.accentBlue),
        LanguageOption(name: "العربية", flag: "🇸🇦", color: Color.accentBlue),
        LanguageOption(name: "हिन्दी", flag: "🇮🇳", color: Color.accentBlue)
    ]
}
