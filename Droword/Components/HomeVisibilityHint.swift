import SwiftUI

struct HomeVisibilityHint: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore

    let message: LocalizedStringKey

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(themeStore.regular(14))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                Haptics.softTap()
                showSettings = true
            } label: {
                Text("Open settings")
                    .font(themeStore.medium(14))
                    .foregroundStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens Home visibility settings"))
        }
        .padding(.top, 16)
        .navigationDestination(isPresented: $showSettings) {
            DictionarySettingsView()
                .environmentObject(store)
                .environmentObject(languageStore)
                .environmentObject(themeStore)
        }
    }
}
