import SwiftUI

struct CoachMarkStep {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let icon: String
}

enum CoachMarkCatalog {
    static let homeSteps: [CoachMarkStep] = [
        CoachMarkStep(
            title: "Add words",
            message: "Tap + to add a word. I translate it, find examples, and make a card.",
            icon: "plus.circle.fill"
        ),
        CoachMarkStep(
            title: "Today's lesson",
            message: "One short session on Home. Due words and your vibe go in there.",
            icon: "bolt.fill"
        ),
        CoachMarkStep(
            title: "Practice",
            message: "Want another round? Practice is extra. Home is just the lesson.",
            icon: "brain.head.profile"
        ),
        CoachMarkStep(
            title: "Your week",
            message: "The fire and the week dots are the same streak. Study keeps it alive.",
            icon: "flame.fill"
        ),
    ]
}

struct CoachMarkView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let steps: [CoachMarkStep]
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0

    private var step: CoachMarkStep { steps[currentStep] }
    private var isLast: Bool { currentStep >= steps.count - 1 }

    var body: some View {
        ZStack {
            themeStore.appBg.opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 18) {
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule(style: .continuous)
                            .fill(i == currentStep ? themeStore.mainAccentColor : themeStore.secondaryText.opacity(0.25))
                            .frame(width: i == currentStep ? 18 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)

                Image(systemName: step.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(themeStore.mainAccentColor)
                    .id(currentStep)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))

                VStack(spacing: 8) {
                    Text(step.title)
                        .font(themeStore.display(22))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)
                        .id("title-\(currentStep)")

                    Text(step.message)
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .id("msg-\(currentStep)")
                }
                .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    Button {
                        advance()
                    } label: {
                        Text(isLast ? "Get Started" : "Next")
                            .duo3DStyle(themeStore.mainAccentColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())

                    if !isLast {
                        Button {
                            Haptics.lightImpact()
                            onComplete()
                        } label: {
                            Text("Skip tour")
                                .duo3DSecondaryStyle()
                        }
                        .buttonStyle(Duo3DButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 360)
            .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.dialog)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentStep)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                cardScale = 1
                cardOpacity = 1
            }
        }
    }

    private func advance() {
        Haptics.lightImpact()
        if isLast {
            onComplete()
        } else {
            currentStep += 1
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
