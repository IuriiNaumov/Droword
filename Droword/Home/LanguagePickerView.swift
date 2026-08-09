import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.dismiss) private var dismiss

    @State private var pendingLearningLanguage: String?

    private func flag(for name: String) -> String {
        LanguageCatalog.availableLanguages.first { $0.name == name }?.flag ?? ""
    }

    private var learningBinding: Binding<String> {
        Binding(
            get: { languageStore.learningLanguage },
            set: { newValue in
                guard newValue != languageStore.learningLanguage else { return }
                if store.words.isEmpty {
                    languageStore.learningLanguage = newValue
                } else {
                    pendingLearningLanguage = newValue
                }
            }
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {

                Text("Language Preferences")
                    .sheetTitle()

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Text(flag(for: languageStore.nativeLanguage))
                            .font(.system(size: 28))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeStore.accentBlue)
                        Text(flag(for: languageStore.learningLanguage))
                            .font(.system(size: 28))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
                    )
                    .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 14))

                    Text(LanguageLevels.localizedLabel(forCode: languageStore.learningLevel))
                        .font(themeStore.bold(13))
                        .foregroundStyle(themeStore.mainAccentColor)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 14)
                        .background(Capsule().fill(themeStore.mainAccentColor.opacity(0.15)))
                }

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
            if let pending = pendingLearningLanguage {
                CustomAlertView(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: themeStore.accentGold,
                    title: "Switch to \(pending)?",
                    message: "You have \(store.words.count) words in \(languageStore.learningLanguage). They will stay in your dictionary.",
                    primaryButton: .init(title: "Switch", style: .primary) {
                        languageStore.learningLanguage = pending
                        pendingLearningLanguage = nil
                    },
                    secondaryButton: .init(title: "Cancel", style: .cancel) {
                        pendingLearningLanguage = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeOut(duration: 0.2), value: pendingLearningLanguage)
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
