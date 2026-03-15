import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var page: Int = 0

    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

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
            subtitle: "Choose languages, voices and themes. Track progress and level up!",
            illustrationStyle: .customize,
            accent: themeStore.accentGold
        )
    ]}

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
                        .fill(idx == page ? Color.mainBlack : Color.mainGrey.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button(action: next) {
                Image(systemName: page == totalPages - 1 ? (canProceedOnCurrentPage ? "checkmark" : "xmark") : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(themeStore.buttonAccent))
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.15))
                .frame(width: size * 0.68, height: size * 0.52)
                .rotationEffect(.degrees(-3))
                .offset(x: -size * 0.02 + px * 0.12, y: size * 0.02 + py * 0.08)

            VStack(alignment: .leading, spacing: 0) {
                Text("Travel")
                    .font(.custom("Poppins-Medium", size: size * 0.04))
                    .foregroundColor(darkerShade(of: accent, by: 0.45))
                    .padding(.vertical, size * 0.014)
                    .padding(.horizontal, size * 0.03)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accent.opacity(0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(darkerShade(of: accent, by: 0.15), lineWidth: 1)
                    )

                Spacer().frame(height: size * 0.025)

                HStack(alignment: .top, spacing: size * 0.015) {
                    Text("Serendipity")
                        .font(.custom("Poppins-Bold", size: size * 0.065))
                        .foregroundColor(.mainBlack)

                    Spacer()

                    Image(systemName: "waveform")
                        .font(.system(size: size * 0.032, weight: .medium))
                        .foregroundColor(.mainBlack.opacity(0.4))
                        .padding(.top, size * 0.015)
                }

                Text("/ˌser.ənˈdɪp.ə.ti/")
                    .font(.custom("Poppins-Regular", size: size * 0.035))
                    .foregroundColor(.mainGrey)

                Spacer().frame(height: size * 0.02)

                Text("Счастливая случайность")
                    .font(.custom("Poppins-Regular", size: size * 0.038))
                    .foregroundColor(.mainBlack.opacity(0.8))

                Spacer().frame(height: size * 0.02)

                HStack(spacing: 0) {
                    Text("A ")
                        .font(.custom("Poppins-Regular", size: size * 0.032))
                        .foregroundColor(.mainBlack.opacity(0.6))
                    Text("serendipity")
                        .font(.custom("Poppins-Bold", size: size * 0.032))
                        .foregroundColor(.orange)
                    Text(" led me...")
                        .font(.custom("Poppins-Regular", size: size * 0.032))
                        .foregroundColor(.mainBlack.opacity(0.6))
                }
            }
            .padding(size * 0.05)
            .frame(width: size * 0.68, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(accent.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.mainGrey.opacity(0.12), lineWidth: 1)
            )
            .offset(x: px * 0.3, y: py * 0.2)
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
            VStack(spacing: size * 0.025) {
                VStack(spacing: size * 0.012) {
                    Text("3 / 10")
                        .font(.custom("Poppins-Medium", size: size * 0.035))
                        .foregroundColor(.mainGrey)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.15))
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * 0.3)
                        }
                    }
                    .frame(height: size * 0.012)
                    .clipShape(Capsule())
                    .padding(.horizontal, size * 0.02)
                }

                Text("Ephemeral")
                    .font(.custom("Poppins-Bold", size: size * 0.07))
                    .foregroundColor(.mainBlack)

                Text("Choose the correct translation")
                    .font(.custom("Poppins-Regular", size: size * 0.03))
                    .foregroundColor(.mainGrey.opacity(0.7))

                Spacer().frame(height: size * 0.005)

                VStack(spacing: size * 0.02) {
                    quizOption(text: "Постоянный", isCorrect: false, isSelected: false, size: size)
                    quizOption(text: "Мимолётный", isCorrect: true, isSelected: true, size: size)
                    quizOption(text: "Огромный", isCorrect: false, isSelected: false, size: size)
                    quizOption(text: "Внезапный", isCorrect: false, isSelected: false, size: size)
                }
            }
            .padding(size * 0.045)
            .frame(width: size * 0.72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
    }

    private func quizOption(text: String, isCorrect: Bool, isSelected: Bool, size: CGFloat) -> some View {
        HStack {
            Text(text)
                .font(.custom("Poppins-Medium", size: size * 0.037))
                .foregroundColor(isSelected ? darkerShade(of: accent, by: 0.4) : .mainBlack.opacity(0.7))
            Spacer()
            if isSelected && isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.04))
                    .foregroundColor(darkerShade(of: accent, by: 0.3))
            }
        }
        .padding(.vertical, size * 0.025)
        .padding(.horizontal, size * 0.035)
        .background(
            RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                .fill(isSelected ? accent.opacity(0.3) : Color.mainGrey.opacity(0.08))
        )
    }
}

private struct CustomizeIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private var palette: [Color] {[
        themeStore.accentBlue,
        themeStore.accentGreen,
        themeStore.accentPurple,
        themeStore.accentGold,
        themeStore.accentPink
    ]}

    var body: some View {
        ZStack {
            VStack(spacing: size * 0.025) {
                VStack(spacing: size * 0.012) {
                    Circle()
                        .fill(Color.mainGrey.opacity(0.15))
                        .frame(width: size * 0.1, height: size * 0.1)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.045, weight: .medium))
                                .foregroundColor(.mainBlack.opacity(0.5))
                        )

                    Text("User")
                        .font(.custom("Poppins-Bold", size: size * 0.038))
                        .foregroundColor(.mainBlack)
                }

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: size * 0.014) {
                        Text("Theme")
                            .font(.custom("Poppins-Medium", size: size * 0.034))
                            .foregroundColor(.mainBlack)

                        HStack(spacing: size * 0.02) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(palette[i])
                                    .frame(width: size * 0.05, height: size * 0.05)
                                    .overlay(
                                        Circle()
                                            .stroke(i == 1 ? Color.mainBlack : Color.clear, lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, size * 0.022)
                    .padding(.horizontal, size * 0.03)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cardBackground)
                )

                VStack(spacing: 0) {
                    settingsRow(icon: "moon.fill", color: accent, title: "Appearance", value: "Light", size: size)
                    settingsRow(icon: "textformat.size", color: themeStore.accentGreen, title: "Language", value: "English", size: size)
                    settingsRow(icon: "bell.badge.fill", color: themeStore.accentPink, title: "Notifications", value: nil, size: size)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: size * 0.01) {
                    HStack {
                        Text("Level 5")
                            .font(.custom("Poppins-Bold", size: size * 0.033))
                            .foregroundColor(.mainBlack)
                        Spacer()
                        Text("120 XP")
                            .font(.custom("Poppins-Medium", size: size * 0.028))
                            .foregroundColor(.mainGrey)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.15))
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * 0.65)
                        }
                    }
                    .frame(height: size * 0.016)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, size * 0.01)
            }
            .padding(size * 0.035)
            .frame(width: size * 0.72)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.appBackground)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            )
            .offset(x: px * 0.25, y: py * 0.18)
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, value: String?, size: CGFloat) -> some View {
        HStack(spacing: size * 0.022) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size * 0.045, height: size * 0.045)
                Image(systemName: icon)
                    .font(.system(size: size * 0.022, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.custom("Poppins-Regular", size: size * 0.033))
                .foregroundColor(.mainBlack)

            Spacer()

            if let value {
                Text(value)
                    .font(.custom("Poppins-Regular", size: size * 0.028))
                    .foregroundColor(.mainGrey)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: size * 0.022, weight: .semibold))
                .foregroundColor(.mainGrey.opacity(0.5))
        }
        .padding(.vertical, size * 0.018)
        .padding(.horizontal, size * 0.025)
        .background(Color.cardBackground)
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
