import SwiftUI

private enum FlagScreen: Hashable {
    case wellDone
    case wordsAdded
    case studyExtras
    case proInvite
    case onboarding(OnboardingModalPreview)
    case alert(CustomAlertPreviewCase)
    case milestone(MilestonePreview)
}

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
        case .suggestedWords: return "wand.and.sparkles"
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

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Feature Flags")
                        .sheetTitle()

                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            MenuSymbol(
                                systemName: "sparkle",
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

                    flagGroup {
                        flagLink(.wellDone, icon: "sparkles", title: LocalizedStringKey(DuoChaosCopy.finishSplash(percentage: 100)))
                    }

                    Text("Onboarding modals")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("First words, Home/Practice tour, suggested words.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        ForEach(OnboardingModalPreview.allCases) { item in
                            flagLink(.onboarding(item), icon: item.icon, title: item.title)
                        }
                    }

                    Text("Words added")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Page after adding words from a scan or a word pack.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        flagLink(.wordsAdded, icon: "checkmark.circle", title: "3 words added")
                    }

                    Text("Study extras")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("After a few words, if stories, challenges, or packs are still off. Hidden when every extra is already on.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        flagLink(.studyExtras, icon: "sparkles", title: "Nice work")
                    }

                    Text("PRO invite")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Shown every few days when PRO is off. Hidden for people who already have it.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        flagLink(.proInvite, icon: "sparkle", title: "Want the cap off?")
                    }

                    Text("Celebrations")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Word count, daily goal, and badge pages.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        ForEach(MilestonePreview.allCases.filter { FeatureGates.streakEnabled || !$0.isStreak }) { item in
                            flagLink(.milestone(item), icon: "sparkles", title: item.title)
                        }
                    }

                    Text("Alerts")
                        .font(themeStore.bold(18))
                        .foregroundStyle(themeStore.mainText)
                        .padding(.top, 4)

                    Text("Confirmations and errors, opened as pages.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)

                    flagGroup {
                        ForEach(CustomAlertPreviewCase.allCases) { item in
                            flagLink(.alert(item), icon: "rectangle.portrait", title: item.title)
                        }
                    }
                }
                .padding(.bottom, 20)
                .padding(.horizontal, DesignSpacing.screenInset)
            }
            .background(themeStore.appBg.ignoresSafeArea())
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .navigationDestination(for: FlagScreen.self) { screen in
            FlagScreenPage(screen: screen)
                .environmentObject(themeStore)
                .environmentObject(store)
                .environmentObject(languageStore)
        }
    }

    private func flagGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
    }

    private func flagLink(_ screen: FlagScreen, icon: String, title: LocalizedStringKey) -> some View {
        NavigationLink(value: screen) {
            HStack(spacing: 14) {
                MenuSymbol(systemName: icon)
                Text(title)
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

private struct FlagScreenPage: View {
    @Environment(\.dismiss) private var dismiss
    let screen: FlagScreen

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .wellDone:
            QuizCompletionView(
                correct: 8,
                total: 10,
                bestStreak: 4,
                onClose: { dismiss() },
                onRestart: { dismiss() }
            )
        case .wordsAdded:
            WordsAddedPage(count: 3) {
                dismiss()
            }
        case .studyExtras:
            StudyExtrasPromptPage(showsEveryExtra: true) {
                dismiss()
            }
        case .proInvite:
            ProInvitePage(
                onSeePro: { dismiss() },
                onLater: { dismiss() }
            )
        case .onboarding(let item):
            switch item {
            case .firstWords:
                FirstWordsView { dismiss() }
            case .homeTour:
                CoachMarkView(steps: CoachMarkCatalog.homeSteps) { dismiss() }
            case .suggestedWords:
                SuggestedWordsIntroView { dismiss() }
            }
        case .alert(let item):
            item.makeView { dismiss() }
        case .milestone(let item):
            MilestoneCelebrationView(
                milestone: item.milestone,
                wordsCount: item.wordsCount,
                daysSinceStart: item.daysSinceStart
            ) {
                dismiss()
            }
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
