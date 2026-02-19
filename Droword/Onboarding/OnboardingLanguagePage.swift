import SwiftUI

struct OnboardingLanguagePage: View {
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                LanguageSelectionView()
                    .environmentObject(languageStore)
            }
            .padding(.horizontal, 0)
        }
    }
}
