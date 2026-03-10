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
            illustrationStyle: .dictionary,
            accent: .accentBlue
        ),
        .init(
            title: "Smart practice",
            subtitle: "Review with a spaced schedule to keep words fresh in memory.",
            illustrationStyle: .practice,
            accent: .accentGreen
        ),
        .init(
            title: "Make it yours",
            subtitle: "Choose languages, voices and themes. Track progress and level up!",
            illustrationStyle: .customize,
            accent: .accentGold
        )
    ]

    private var totalPages: Int { pages.count + 2 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBackground.ignoresSafeArea()

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
                                    page = pages.count
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
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { idx in
                    Circle()
                        .fill(idx == page ? Color.accentBlue : Color.mainGrey.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button(action: next) {
                Image(systemName: page == totalPages - 1 ? (canProceedOnCurrentPage ? "checkmark" : "xmark") : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentBlue))
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

private struct OnboardingPageModel: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let illustrationStyle: IllustrationStyle
    let accent: Color

    enum IllustrationStyle: Equatable {
        case dictionary
        case practice
        case customize
    }
}

private struct OnboardingPageView: View {
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
        .frame(width: size, height: size * 0.75)
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

private struct DictionaryIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.12))
                .frame(width: size * 0.58, height: size * 0.38)
                .rotationEffect(.degrees(-4))
                .offset(x: -size * 0.06 + px * 0.15, y: size * 0.04 + py * 0.1)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.2))
                .frame(width: size * 0.58, height: size * 0.38)
                .rotationEffect(.degrees(2))
                .offset(x: size * 0.02 + px * 0.25, y: -size * 0.01 + py * 0.15)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)

                VStack(alignment: .leading, spacing: size * 0.028) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(accent.opacity(0.6))
                        .frame(width: size * 0.22, height: size * 0.025)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(accent.opacity(0.3))
                        .frame(width: size * 0.30, height: size * 0.018)

                    Spacer().frame(height: size * 0.01)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.mainGrey.opacity(0.15))
                        .frame(width: size * 0.38, height: size * 0.014)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.mainGrey.opacity(0.12))
                        .frame(width: size * 0.28, height: size * 0.014)

                    Spacer().frame(height: size * 0.015)

                    Capsule()
                        .fill(accent.opacity(0.2))
                        .frame(width: size * 0.14, height: size * 0.025)
                }
                .padding(size * 0.045)
            }
            .frame(width: size * 0.58, height: size * 0.38)
            .offset(x: px * 0.35, y: py * 0.25)

            Circle()
                .fill(accent.opacity(0.35))
                .frame(width: size * 0.04)
                .offset(x: size * 0.34 + px * 0.5, y: -size * 0.22 + py * 0.4)

            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: size * 0.025)
                .offset(x: -size * 0.36 + px * 0.6, y: size * 0.18 + py * 0.5)
        }
    }
}

private struct PracticeIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(x: px * 0.1, y: py * 0.08)

            Circle()
                .stroke(accent.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 8]))
                .frame(width: size * 0.52, height: size * 0.52)
                .offset(x: px * 0.15, y: py * 0.12)

            ForEach(0..<5, id: \.self) { i in
                let angle = Double(i) * (360.0 / 5.0) + 20
                let radius = size * 0.35
                Circle()
                    .fill(accent.opacity(0.25 + Double(i) * 0.08))
                    .frame(width: size * 0.022)
                    .offset(
                        x: cos(angle * .pi / 180) * radius + px * 0.2,
                        y: sin(angle * .pi / 180) * radius + py * 0.15
                    )
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cardBackground)

                VStack(spacing: size * 0.025) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(accent.opacity(0.5))
                        .frame(width: size * 0.18, height: size * 0.022)

                    ZStack {
                        Circle()
                            .stroke(accent.opacity(0.15), lineWidth: size * 0.015)
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(accent.opacity(0.6), style: StrokeStyle(lineWidth: size * 0.015, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: size * 0.1, height: size * 0.1)

                    HStack(spacing: size * 0.018) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(i == 2 ? accent.opacity(0.6) : accent.opacity(0.2))
                                .frame(width: size * 0.055, height: size * 0.018)
                        }
                    }
                }
            }
            .frame(width: size * 0.42, height: size * 0.42)
            .offset(x: px * 0.3, y: py * 0.2)

            Circle()
                .fill(accent.opacity(0.3))
                .frame(width: size * 0.035)
                .offset(x: -size * 0.32 + px * 0.5, y: -size * 0.25 + py * 0.4)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent.opacity(0.2))
                .frame(width: size * 0.03, height: size * 0.03)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.30 + px * 0.6, y: size * 0.22 + py * 0.5)
        }
    }
}

private struct CustomizeIllustration: View {
    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private let palette: [Color] = [
        Color.accentBlue,
        Color.accentGreen,
        Color.accentPurple,
        Color.accentGold,
        Color.accentPink
    ]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(accent.opacity(0.08 + Double(i) * 0.03))
                    .frame(width: size * 0.6, height: 1)
                    .offset(
                        x: px * 0.1,
                        y: CGFloat(i - 1) * size * 0.2 + py * 0.1
                    )
            }

            HStack(spacing: size * 0.035) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(palette[i])
                        .frame(width: size * 0.065, height: size * 0.065)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                }
            }
            .offset(x: px * 0.2, y: -size * 0.15 + py * 0.15)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(accent.opacity(0.15))
                    .frame(width: size * 0.28, height: size * 0.035)

                Capsule()
                    .fill(accent.opacity(0.5))
                    .frame(width: size * 0.16, height: size * 0.035)

                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: size * 0.042, height: size * 0.042)

                    .offset(x: size * 0.135)
            }
            .offset(x: px * 0.25, y: size * 0.02 + py * 0.2)

            VStack(spacing: size * 0.025) {
                ForEach(0..<2, id: \.self) { i in
                    HStack(spacing: size * 0.02) {
                        Circle()
                            .fill(accent.opacity(0.25))
                            .frame(width: size * 0.03)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.mainGrey.opacity(0.15))
                            .frame(width: size * 0.15, height: size * 0.014)
                        Spacer()
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(accent.opacity(0.2))
                            .frame(width: size * 0.06, height: size * 0.014)
                    }
                    .frame(width: size * 0.35)
                }
            }
            .offset(x: px * 0.3, y: size * 0.16 + py * 0.25)

            Image(systemName: "sparkle")
                .font(.system(size: size * 0.05, weight: .light))
                .foregroundColor(accent.opacity(0.4))
                .offset(x: size * 0.32 + px * 0.5, y: -size * 0.28 + py * 0.4)

            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: size * 0.025)
                .offset(x: -size * 0.34 + px * 0.6, y: size * 0.15 + py * 0.5)
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
