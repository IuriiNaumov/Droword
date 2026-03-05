import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("featureFlagShowOnboarding") private var featureFlagShowOnboarding: Bool = false
    @StateObject private var store = WordsStore()
    @StateObject private var languageStore = LanguageStore()
    @State private var hasCompletedOnboardingThisSession: Bool = false

    var body: some View {
        ZStack {
            if featureFlagShowOnboarding && !hasCompletedOnboardingThisSession {
                OnboardingView(isCompleted: $hasCompletedOnboardingThisSession)
                    .environmentObject(languageStore)
                    .transition(.opacity)
            } else {
                HomeView()
                    .environmentObject(store)
                    .environmentObject(languageStore)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
        .environment(\.locale, .init(identifier: "en"))
}
