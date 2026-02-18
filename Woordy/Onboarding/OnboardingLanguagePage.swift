import SwiftUI

struct OnboardingLanguagePage: View {
    @EnvironmentObject var languageStore: LanguageStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Preferred Language")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 24)

            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

