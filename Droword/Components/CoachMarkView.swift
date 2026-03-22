import SwiftUI

struct CoachMarkStep {
    let title: String
    let message: String
    let icon: String
}

struct CoachMarkView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let steps: [CoachMarkStep]
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var appeared = false

    private var step: CoachMarkStep { steps[currentStep] }
    private var isLast: Bool { currentStep >= steps.count - 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 16) {
                    // Step indicator
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Image(systemName: step.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0)

                    Text(step.title)
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(step.message)
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Button {
                        advance()
                    } label: {
                        Text(isLast ? "Get Started" : "Next")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    if !isLast {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip tour")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func advance() {
        Haptics.lightImpact()
        if isLast {
            onComplete()
        } else {
            appeared = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep += 1
                appeared = true
            }
        }
    }
}
