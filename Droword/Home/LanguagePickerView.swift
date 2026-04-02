import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                
                Text("Language Preferences")
                    .sheetTitle()
                
                LanguageCubePicker(
                    selectedLanguage: $languageStore.nativeLanguage,
                    title: "I speak",
                    languages: LanguageCatalog.availableLanguages,
                    blockedLanguage: languageStore.learningLanguage
                )
                
                LanguageCubePicker(
                    selectedLanguage: $languageStore.learningLanguage,
                    title: "I'm learning",
                    languages: LanguageCatalog.availableLanguages,
                    blockedLanguage: languageStore.nativeLanguage
                )
            }
            .padding(.bottom, 50)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        
    }
    
}

#Preview {
    LanguageSelectionView()
        .environmentObject(mockLanguageStore())
}

#Preview("Light") {
    LanguageSelectionView()
        .environmentObject(mockLanguageStore())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LanguageSelectionView()
        .environmentObject(mockLanguageStore())
        .preferredColorScheme(.dark)
}

private func mockLanguageStore() -> LanguageStore {
    let store = LanguageStore()
    store.nativeLanguage = "Русский"
    store.learningLanguage = "日本語"
    return store
}
