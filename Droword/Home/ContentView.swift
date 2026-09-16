import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }

            if showSplash {
                SplashView {
                    showSplash = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.45), value: showSplash)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}

#Preview {
    ContentView()
        .environment(\.locale, .init(identifier: "en"))
}
