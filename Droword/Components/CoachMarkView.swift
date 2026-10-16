import SwiftUI

struct CoachMarkStep {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let icon: String
}

enum CoachMarkCatalog {
    static var homeSteps: [CoachMarkStep] {
        let steps = [
            CoachMarkStep(
                title: "Add words",
                message: "Tap + to add a word. I translate it, find examples, and make a card.",
                icon: "plus.circle"
            ),
            CoachMarkStep(
                title: "Today's lesson",
                message: "One short session on Home. Due words and your vibe go in there.",
                icon: "bolt"
            ),
            CoachMarkStep(
                title: "Practice",
                message: "Want another round? Practice is extra. Home is just the lesson.",
                icon: "brain.head.profile"
            ),
            CoachMarkStep(
                title: "Your week",
                message: "The fire and the week dots are the same streak. Study keeps it alive.",
                icon: "flame"
            ),
        ]
        guard FeatureGates.streakEnabled else {
            return steps.filter { $0.icon != "flame" }
        }
        return steps
    }
}

struct CoachMarkView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let steps: [CoachMarkStep]
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0

    private var isLast: Bool { currentStep >= steps.count - 1 }
    private var tint: Color { accent(for: currentStep) }

    private func accent(for index: Int) -> Color {
        switch index {
        case 0: return themeStore.accentGreen
        case 1: return themeStore.accentGold
        case 2: return themeStore.accentPink
        default: return themeStore.accentRed
        }
    }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepPage(step, accent: accent(for: index))
                            .tag(index)
                            .padding(.horizontal, DesignSpacing.screenInset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: currentStep)

                VStack(spacing: 16) {
                    PageCapsules(count: steps.count, selection: currentStep)

                    VStack(spacing: DesignSpacing.buttonGap) {
                        Button {
                            advance()
                        } label: {
                            Text(isLast ? "Get Started" : "Next")
                                .duo3DStyle(tint)
                        }
                        .buttonStyle(Duo3DButtonStyle())

                        if !isLast {
                            Button {
                                Haptics.softTap()
                                onComplete()
                            } label: {
                                Text("Skip tour")
                                    .duo3DSecondaryStyle()
                            }
                            .buttonStyle(Duo3DButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, DesignSpacing.screenInset)
                .padding(.bottom, 12)
                .padding(.top, 8)
            }
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: play)
        .onChange(of: currentStep) {
            Haptics.lightImpact()
            replayStep()
        }
    }

    private func stepPage(_ step: CoachMarkStep, accent: Color) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            SoftCoverHero(
                systemName: step.icon,
                color: accent,
                iconScale: iconScale
            )

            VStack(spacing: 8) {
                Text(step.title)
                    .font(themeStore.display(32))
                    .foregroundStyle(themeStore.mainText)
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)

                Text(step.message)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)
            .padding(.horizontal, 4)
            .opacity(textOpacity)

            Spacer(minLength: 24)
        }
    }

    private func play() {
        Haptics.encourage()
        replayStep()
    }

    private func replayStep() {
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            return
        }
        iconScale = 0.72
        textOpacity = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
    }

    private func advance() {
        if isLast {
            Haptics.lightImpact()
            onComplete()
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                currentStep += 1
            }
        }
    }
}

#Preview {
    CoachMarkView(
        steps: CoachMarkCatalog.homeSteps,
        onComplete: {}
    )
    .environmentObject(ThemeStore())
}
