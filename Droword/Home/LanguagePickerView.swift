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
                        languages: LanguageCatalog.availableLanguages,
                        blockedLanguage: languageStore.learningLanguage
                    )
                    .onChange(of: languageStore.nativeLanguage) { _ in
                        showToastForChange()
                    }
                    
                    LanguageCubePicker(
                        selectedLanguage: $languageStore.learningLanguage,
                        title: "I’m learning",
                        languages: LanguageCatalog.availableLanguages,
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
