import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("featureFlagShowOnboarding") private var featureFlagShowOnboarding: Bool = false
    @StateObject private var store = WordsStore()
    @StateObject private var languageStore = LanguageStore()

    var body: some View {
        ZStack {
            
//            OnboardingView()
//                .environmentObject(languageStore)
//                .transition(.opacity)
            
            HomeView()
                .environmentObject(store)
                .environmentObject(languageStore)
//                .opacity((hasCompletedOnboarding && !featureFlagShowOnboarding) ? 1 : 0)

            
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
