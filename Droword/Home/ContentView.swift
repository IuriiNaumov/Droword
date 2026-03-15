import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
        .environment(\.locale, .init(identifier: "en"))
}
