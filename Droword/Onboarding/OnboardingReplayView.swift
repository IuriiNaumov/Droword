import SwiftUI

struct OnboardingReplayView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var page: Int = 0
    @State private var animateStage = false
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
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
                    .onChange(of: page) { retriggerAnimation() }
                    .gesture(
                        DragGesture(minimumDistance: 6)
                            .onChanged { value in
                                dragOffset = CGSize(
                                    width: value.translation.width * 0.12,
                                    height: value.translation.height * 0.08
                                )
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


            }
        }
        .onAppear { retriggerAnimation() }
    }

    private var controls: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == page ? themeStore.mainText : themeStore.secondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            if page < pages.count - 1 {
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        page += 1
                    }
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(themeStore.mainAccentColor))
                }
                .buttonStyle(ReplayScaledPressStyle())
            } else {
                Button {
                    Haptics.selection()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(themeStore.mainAccentColor))
                }
                .buttonStyle(ReplayScaledPressStyle())
            }
        }
    }

    private func retriggerAnimation() {
        animateStage = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                animateStage = true
            }
        }
    }
}

private struct ReplayScaledPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
