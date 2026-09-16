import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore

    private enum PendingChange: Equatable {
        case learning(String)
        case swap(native: String, learning: String)
    }

    @State private var pending: PendingChange?

    private var learningBinding: Binding<String> {
        Binding(
            get: { languageStore.learningLanguage },
            set: { newValue in
                guard newValue != languageStore.learningLanguage else { return }
                if store.words.isEmpty {
                    languageStore.learningLanguage = newValue
                } else {
                    pending = .learning(newValue)
                }
            }
        )
    }

    private var pendingAlertTitle: String {
        switch pending {
        case .learning(let name):
            return String(localized: "Switch to \(name)?")
        case .swap(_, let learning):
            return String(localized: "Switch to \(learning)?")
        case .none:
            return ""
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Text("Language Preferences")
                    .sheetTitle()

                LanguagePairHero(
                    nativeName: languageStore.nativeLanguage,
                    learningName: languageStore.learningLanguage,
                    onSwap: swapLanguages
                )

                Text(LanguageLevels.localizedLabel(forCode: languageStore.learningLevel))
                    .font(themeStore.bold(13))
                    .foregroundStyle(themeStore.mainAccentColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(themeStore.mainAccentColor.opacity(0.15)))

                LanguageCubePicker(
                    selectedLanguage: $languageStore.nativeLanguage,
                    title: "I speak",
                    languages: LanguageCatalog.availableLanguages,
                    blockedLanguage: languageStore.learningLanguage
                )

                LanguageCubePicker(
                    selectedLanguage: learningBinding,
                    title: "I'm learning",
                    languages: LanguageCatalog.availableLanguages,
                    blockedLanguage: languageStore.nativeLanguage
                )

                LanguageLevelPicker()
            }
            .padding(.bottom, 50)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .overlay {
            if pending != nil {
                CustomAlertView(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: themeStore.accentGold,
                    title: LocalizedStringKey(pendingAlertTitle),
                    message: "You have \(store.words.count) words in \(languageStore.learningLanguage). They will stay in your dictionary.",
                    primaryButton: .init(title: "Switch", style: .primary) {
                        applyPending()
                    },
                    secondaryButton: .init(title: "Cancel", style: .cancel) {
                        pending = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeOut(duration: 0.2), value: pending)
    }

    private func swapLanguages() {
        let newNative = languageStore.learningLanguage
        let newLearning = languageStore.nativeLanguage
        guard newNative != newLearning else { return }

        if store.words.isEmpty {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                languageStore.nativeLanguage = newNative
                languageStore.learningLanguage = newLearning
            }
        } else {
            pending = .swap(native: newNative, learning: newLearning)
        }
    }

    private func applyPending() {
        switch pending {
        case .learning(let name):
            languageStore.learningLanguage = name
        case .swap(let native, let learning):
            languageStore.nativeLanguage = native
            languageStore.learningLanguage = learning
        case .none:
            break
        }
        pending = nil
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject({
            let store = LanguageStore()
            store.nativeLanguage = "Русский"
            store.learningLanguage = "日本語"
            return store
        }())
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
}
