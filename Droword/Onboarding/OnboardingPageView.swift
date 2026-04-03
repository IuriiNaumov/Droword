import SwiftUI

struct OnboardingPageModel: Identifiable, Equatable {
    let id = UUID()
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let illustrationStyle: IllustrationStyle
    let accent: Color

    enum IllustrationStyle: Equatable {
        case dictionary
        case practice
        case customize
    }
}

struct OnboardingPageView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let model: OnboardingPageModel
    let animateStage: Bool
    let dragOffset: CGSize
    let containerSize: CGSize

    @State private var showArt = false
    @State private var showTitle = false
    @State private var showSubtitle = false

    var body: some View {
        VStack { 
            Spacer(minLength: 0)
            VStack(spacing: 34) {
                illustration
                    .opacity(showArt ? 1 : 0)
                    .offset(y: showArt ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: showArt)

                VStack(spacing: 10) {
                    Text(model.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(themeStore.mainText)
                        .multilineTextAlignment(.center)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.9), value: showTitle)

                    Text(model.subtitle)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(themeStore.mainText.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.92), value: showSubtitle)
                }
                .padding(.horizontal, 6)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: animateStage) { _, newValue in
            if newValue { stagedReveal() }
        }
        .onAppear { stagedReveal() }
    }

    private var illustration: some View {
        let size = min(containerSize.width * 0.65, 300)
        let px = dragOffset.width * 0.25
        let py = dragOffset.height * 0.18

        return ZStack {
            switch model.illustrationStyle {
            case .dictionary:
                DictionaryIllustration(accent: model.accent, size: size, px: px, py: py)
            case .practice:
                PracticeIllustration(accent: model.accent, size: size, px: px, py: py)
            case .customize:
                CustomizeIllustration(accent: model.accent, size: size, px: px, py: py)
            }
        }
        .frame(width: size, height: size * 1.15)
        .clipped()
        .accessibilityHidden(true)
    }

    private func stagedReveal() {
        showArt = false
        showTitle = false
        showSubtitle = false
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showArt = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                    showTitle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.92)) {
                    showSubtitle = true
                }
            }
        }
    }
}
