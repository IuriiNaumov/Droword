import SwiftUI

enum OnboardingModalPreview: String, CaseIterable, Identifiable {
    case firstWords
    case homeTour
    case suggestedWords

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .firstWords: return "First words"
        case .homeTour: return "Home & Practice tour"
        case .suggestedWords: return "Suggested Words"
        }
    }

    var icon: String {
        switch self {
        case .firstWords: return "textformat"
        case .homeTour: return "house"
        case .suggestedWords: return "lightbulb"
        }
    }
}

struct FeatureFlagsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore

    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.debugPremiumOverride) private var debugOverride: Bool = false
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false

    @State private var previewCase: CustomAlertPreviewCase?
    @State private var onboardingPreview: OnboardingModalPreview?
    @State private var showWellDone = false

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Feature Flags")
                        .sheetTitle()

                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            MenuSymbol(
                                systemName: "sparkles",
                                color: themeStore.accentBlue,
                                size: 22,
                                weight: .medium
                            )
                            Text("PRO")
                                .font(themeStore.regular(16))
                                .foregroundStyle(themeStore.mainText)
                            Spacer()
                            Toggle("", isOn: $isPremium)
                                .labelsHidden()
                                .tint(themeStore.mainAccentColor)
                                .onChange(of: isPremium) { _, newValue in
                                    debugOverride = newValue
                                }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(themeStore.cardBg)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))

                    VStack(spacing: 0) {
                        Button {
                            hasCompletedOnboarding.toggle()
                            Haptics.menuTap()
                        } label: {
                            HStack(spacing: 14) {
                                MenuSymbol(systemName: "hand.wave")
                                Text("Onboarding")
                                    .font(themeStore.regular(16))
                                    .foregroundStyle(themeStore.mainText)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { !hasCompletedOnboarding },
                                    set: { newValue in
                                        hasCompletedOnboarding = !newValue
                                    }
                                ))
                                .labelsHidden()
                                .tint(themeStore.mainAccentColor)
                                .allowsHitTesting(false)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                            .background(themeStore.cardBg)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))

                    Text("Finish")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Well done screen after practice and today's lesson.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    VStack(spacing: 0) {
                        Button {
                            Haptics.menuTap()
                            showWellDone = true
                        } label: {
                            HStack(spacing: 14) {
                                MenuSymbol(systemName: "sparkles")
                                Text(DuoChaosCopy.finishSplash(percentage: 100))
                                    .font(themeStore.regular(16))
                                    .foregroundStyle(themeStore.mainText)
                                Spacer()
                                DisclosureChevron()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                            .background(themeStore.cardBg)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))

                    Text("Onboarding modals")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("First words, Home/Practice tour, suggested words.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    VStack(spacing: 0) {
                        ForEach(Array(OnboardingModalPreview.allCases.enumerated()), id: \.element.id) { index, item in
                            Button {
                                Haptics.menuTap()
                                onboardingPreview = item
                            } label: {
                                HStack(spacing: 14) {
                                    MenuSymbol(systemName: item.icon)
                                    Text(item.title)
                                        .font(themeStore.regular(16))
                                        .foregroundStyle(themeStore.mainText)
                                    Spacer()
                                    DisclosureChevron()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 18)
                                .background(themeStore.cardBg)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))

                    Text("Modals")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Preview alert styles used across the app.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    VStack(spacing: 0) {
                        ForEach(Array(CustomAlertPreviewCase.allCases.enumerated()), id: \.element.id) { index, item in
                            Button {
                                Haptics.menuTap()
                                previewCase = item
                            } label: {
                                HStack(spacing: 14) {
                                    MenuSymbol(systemName: "rectangle.portrait.on.rectangle.portrait")
                                    Text(item.title)
                                        .font(themeStore.regular(16))
                                        .foregroundStyle(themeStore.mainText)
                                    Spacer()
                                    DisclosureChevron()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 18)
                                .background(themeStore.cardBg)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
                }
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
            }
            .background(themeStore.appBg.ignoresSafeArea())

            if let previewCase {
                previewCase.makeView {
                    withAnimation(.easeOut(duration: 0.18)) {
                        self.previewCase = nil
                    }
                }
                .environmentObject(themeStore)
                .transition(.opacity)
                .zIndex(10)
            }

            if let onboardingPreview {
                Group {
                    switch onboardingPreview {
                    case .firstWords:
                        FirstWordsView {
                            withAnimation(.easeOut(duration: 0.18)) {
                                self.onboardingPreview = nil
                            }
                        }
                        .environmentObject(themeStore)
                        .environmentObject(store)
                        .environmentObject(languageStore)
                    case .homeTour:
                        CoachMarkView(steps: CoachMarkCatalog.homeSteps) {
                            withAnimation(.easeOut(duration: 0.18)) {
                                self.onboardingPreview = nil
                            }
                        }
                        .environmentObject(themeStore)
                    case .suggestedWords:
                        SuggestedWordsIntroView {
                            withAnimation(.easeOut(duration: 0.18)) {
                                self.onboardingPreview = nil
                            }
                        }
                        .environmentObject(themeStore)
                    }
                }
                .transition(.opacity)
                .zIndex(11)
            }
        }
        .animation(.easeOut(duration: 0.2), value: previewCase?.id)
        .animation(.easeOut(duration: 0.2), value: onboardingPreview?.id)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .fullScreenCover(isPresented: $showWellDone) {
            QuizCompletionView(
                correct: 8,
                total: 10,
                bestStreak: 4,
                onClose: { showWellDone = false },
                onRestart: { showWellDone = false }
            )
            .environmentObject(themeStore)
        }
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsView()
    }
    .environmentObject(ThemeStore())
    .environmentObject(WordsStore())
    .environmentObject(LanguageStore())
}
