import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            NotificationPreferencesForm(
                showsTitle: true,
                onboardingStyle: false,
                requestAuthOnAppear: true
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environmentObject(ThemeStore())
    .environmentObject(WordsStore())
    .environmentObject(LanguageStore())
}
