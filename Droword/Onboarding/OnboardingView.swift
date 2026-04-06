import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var page: Int = 0

    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @AppStorage(AppStorageKeys.userName) private var userName: String = ""

    @State private var animateStage: Bool = false
    @State private var dragOffset: CGSize = .zero

    private var pages: [OnboardingPageModel] {[
        .init(
            title: "Build your dictionary",
            subtitle: "Save words with examples, tags and notes so they stay with you.",
            illustrationStyle: .dictionary,
            accent: themeStore.accentBlue
        ),
        .init(
            title: "Smart practice",
            subtitle: "Review with a spaced schedule to keep words fresh in memory.",
            illustrationStyle: .practice,
            accent: themeStore.accentGreen
        ),
        .init(
            title: "Make it yours",
            subtitle: "Choose languages, voices and themes. Make it yours!",
            illustrationStyle: .customize,
            accent: themeStore.accentGold
        )
    ]}

    private var totalPages: Int { pages.count + 2 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                themeStore.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        ForEach(pages.indices, id: \.self) { index in
                            OnboardingPageView(
                                model: pages[index],
                                animateStage: animateStage,
                                dragOffset: dragOffset,
                                containerSize: geo.size
                            )
                            .tag(index)
                            .padding(.horizontal, 28)
                            .padding(.top, 24)
                        }

                        OnboardingLanguagePage()
                            .environmentObject(languageStore)
                            .tag(pages.count)
                            .padding(.horizontal, 18)
                            .padding(.top, 24)

                        OnboardingDetailsPage()
                            .tag(pages.count + 1)
                            .padding(.horizontal, 28)
                            .padding(.top, 24)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
                    .onChange(of: page) {
                        retriggerStagedAnimation()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 6)
                            .onChanged { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                dragOffset = CGSize(width: dx * 0.12, height: dy * 0.08)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    dragOffset = .zero
                                }
                            }
                    )

                    controls
                        .padding(.horizontal, 28)
                        .padding(.bottom, 20)
                        .padding(.top, 8)
                }
                .iPadContentWidth(600)

                VStack {
                    HStack {
                        if page > 0 {
                            Button(action: {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    page = max(0, page - 1)
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeStore.mainAccentColor)
                                    .frame(height: 22)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(themeStore.cardBg.opacity(0.9))
                                    )
                            }
                            .buttonStyle(ScaledPressStyle())
                            .padding(.leading, 20)
                            .padding(.top, 12)
                        }

                        Spacer()

                        if page < pages.count {
                            Button(action: {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    page = pages.count
                                }
                            }) {
                                Text("Skip")
                                    .font(themeStore.regular(16))
                                    .foregroundColor(themeStore.mainText.opacity(0.75))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(themeStore.cardBg.opacity(0.9))
                                    )
                            }
                            .buttonStyle(ScaledPressStyle())
                            .padding(.trailing, 20)
                            .padding(.top, 12)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear { retriggerStagedAnimation() }
    }

    private var controls: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { idx in
                    Circle()
                        .fill(idx == page ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button(action: next) {
                Image(systemName: page == totalPages - 1 ? (canProceedOnCurrentPage ? "checkmark" : "xmark") : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(themeStore.mainAccentColor))
                    .accessibilityLabel(page == totalPages - 1 ? (canProceedOnCurrentPage ? "Get Started" : "Name required") : "Continue")
            }
            .buttonStyle(ScaledPressStyle())
            .disabled(!canProceedOnCurrentPage)
        }
    }

    private var canProceedOnCurrentPage: Bool {
        switch page {
        case 0...(pages.count - 1):
            return true
        case pages.count:
            let native = languageStore.nativeLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
            let learning = languageStore.learningLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
            return !native.isEmpty && !learning.isEmpty && native != learning
        case pages.count + 1:
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedName.isEmpty && trimmedName.count <= 40
        default:
            return false
        }
    }

    private func next() {
        Haptics.selection()
        if page < totalPages - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                page += 1
            }
        } else {
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty && trimmedName.count <= 40 else {
                Haptics.lightImpact(intensity: 0.5)
                return
            }
            finish()
        }
    }

    private func finish() {
        Haptics.lightImpact(intensity: 0.7)
        withAnimation(.easeInOut(duration: 0.25)) {
            isCompleted = true
        }
    }

    private func retriggerStagedAnimation() {
        animateStage = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                animateStage = true
            }
        }
    }
}

private struct ScaledPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

#Preview("Light") {
    OnboardingView(isCompleted: .constant(false))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingView(isCompleted: .constant(false))
        .preferredColorScheme(.dark)
}
