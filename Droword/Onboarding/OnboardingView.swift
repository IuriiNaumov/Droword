import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var page: Int = 0

    @EnvironmentObject private var languageStore: LanguageStore

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var animateStage: Bool = false
    @State private var dragOffset: CGSize = .zero

    private let pages: [OnboardingPageModel] = [
        .init(
            title: "Build your dictionary",
            subtitle: "Save words with examples, tags and notes so they stay with you.",
            systemImage: "book.fill",
            accent: .accentBlue
        ),
        .init(
            title: "Smart practice",
            subtitle: "Review with a spaced schedule to keep words fresh in memory.",
            systemImage: "rectangle.portrait.on.rectangle.portrait",
            accent: .accentGreen
        ),
        .init(
            title: "Make it yours",
            subtitle: "Choose languages, voices and themes. Track progress and level up!",
            systemImage: "star.fill",
            accent: .accentGold
        )
    ]

    private var totalPages: Int { pages.count + 2 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()

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
                            .padding(.horizontal, 28)
                            .padding(.top, 24)

                        OnboardingDetailsPage()
                            .tag(pages.count + 1)
                            .padding(.horizontal, 28)
                            .padding(.top, 24)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
                    .onChange(of: page) { _, _ in
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
                
                // Top-right Skip button overlay
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
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.mainBlack.opacity(0.75))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(Color.cardBackground.opacity(0.9))
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
                                    page = pages.count // jump to language selection page
                                }
                            }) {
                                Text("Skip")
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.mainBlack.opacity(0.75))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(Color.cardBackground.opacity(0.9))
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
            // Pagination dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { idx in
                    Circle()
                        .fill(idx == page ? Color.mainBlack : Color.mainGrey.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button(action: next) {
                Image(systemName: page == totalPages - 1 ? "checkmark" : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.toastAndButtons))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .accessibilityLabel(page == totalPages - 1 ? "Get Started" : "Continue")
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
            guard !trimmedName.isEmpty && trimmedName.count <= 40 else { return false }
            let trimmedEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedEmail.isEmpty {
                return true
            } else {
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
                return emailPredicate.evaluate(with: trimmedEmail)
            }
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

private struct OnboardingPageModel: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
}

private struct OnboardingPageView: View {
    let model: OnboardingPageModel
    let animateStage: Bool
    let dragOffset: CGSize
    let containerSize: CGSize

    // Local staged flags for fine control
    @State private var showArt = false
    @State private var showTitle = false
    @State private var showSubtitle = false

    var body: some View {
        VStack { 
            Spacer(minLength: 0)
            VStack(spacing: 24) {
                illustration
                    .opacity(showArt ? 1 : 0)
                    .offset(y: showArt ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: showArt)

                VStack(spacing: 10) {
                    Text(model.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.mainBlack)
                        .multilineTextAlignment(.center)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.9), value: showTitle)

                    Text(model.subtitle)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.mainBlack.opacity(0.75))
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
        let cardSize = min(containerSize.width * 0.75, 380)
        let parallaxX = dragOffset.width * 0.25
        let parallaxY = dragOffset.height * 0.18

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(model.accent.opacity(0.2))
                .frame(width: cardSize, height: cardSize * 0.62)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(model.accent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: model.accent.opacity(0.12), radius: 10, y: 6)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .frame(width: cardSize * 0.86, height: cardSize * 0.46)
                .offset(x: -8 + parallaxX * 0.4, y: -6 + parallaxY * 0.35)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)

            Image(systemName: model.systemImage)
                .font(.system(size: min(72, cardSize * 0.22), weight: .bold))
                .foregroundColor(model.accent)
                .padding(24)
                .background(
                    Circle()
                        .fill(model.accent.opacity(0.18))
                )
                .overlay(
                    Circle().stroke(model.accent.opacity(0.3), lineWidth: 1)
                )
                .offset(x: parallaxX, y: parallaxY)
                .rotation3DEffect(
                    .degrees(Double(parallaxX) * 0.06),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.6
                )
                .rotation3DEffect(
                    .degrees(Double(-parallaxY) * 0.06),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.6
                )
        }
        .accessibilityHidden(true)
    }

    private func stagedReveal() {
        // Reset before animating in
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

