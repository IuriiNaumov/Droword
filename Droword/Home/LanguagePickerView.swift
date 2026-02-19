import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageStore: LanguageStore
    
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
                        .foregroundColor(.mainBlack)
                        .padding(.top, 20)
                    
                    LanguageCubePicker(
                        selectedLanguage: $languageStore.nativeLanguage,
                        title: "I speak",
                        languages: Self.availableLanguages,
                        blockedLanguage: languageStore.learningLanguage
                    )
                    .onChange(of: languageStore.nativeLanguage) { _ in
                        showToastForChange()
                    }
                    
                    LanguageCubePicker(
                        selectedLanguage: $languageStore.learningLanguage,
                        title: "I’m learning",
                        languages: Self.availableLanguages,
                        blockedLanguage: languageStore.nativeLanguage
                    )
                    .onChange(of: languageStore.learningLanguage) { _ in
                        showToastForChange()
                    }
                }
                .padding(.bottom, 50)
            }
            .background(Color.appBackground.ignoresSafeArea())
            
            if showToast {
                ToastView(
                    type: toastType,
                    message: toastMessage,
                    duration: 2
                )
                .id(toastID)
            }
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
        LanguageOption(name: "English", flag: "🇬🇧", color: Color(hex: "#CDEBF1")),
        LanguageOption(name: "Español", flag: "🇲🇽", color: Color(hex: "#DEF1D0")),
        LanguageOption(name: "Русский", flag: "🇷🇺", color: Color(hex: "#FFE6A7")),
        LanguageOption(name: "Français", flag: "🇫🇷", color: Color(hex: "#E4D2FF")),
        LanguageOption(name: "Deutsch", flag: "🇩🇪", color: Color(hex: "#FFD1A9")),
        LanguageOption(name: "Italiano", flag: "🇮🇹", color: Color(hex: "#D2FFD5")),
        LanguageOption(name: "Português", flag: "🇧🇷", color: Color(hex: "#FFF4B0")),
        LanguageOption(name: "한국어", flag: "🇰🇷", color: Color(hex: "#D2E0FF")),
        LanguageOption(name: "中文", flag: "🇨🇳", color: Color(hex: "#FFD5D2")),
        LanguageOption(name: "日本語", flag: "🇯🇵", color: Color(hex: "#DDE8FF"))
    ]
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
