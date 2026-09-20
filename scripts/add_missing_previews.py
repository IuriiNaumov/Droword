#!/usr/bin/env python3
"""Append #Preview to SwiftUI View files that don't have one yet."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

THEME = ".environmentObject(ThemeStore())"
WORDS = ".environmentObject(WordsStore())"
LANG = ".environmentObject(LanguageStore())"
BADGE = ".environmentObject(BadgeStore())"
SUGG = ".environmentObject(SuggestedWordsStore())"
STUDY = ".environmentObject(StudyTimeTracker.shared)"

SAMPLE_WORD = """StoredWord(
        word: "hola",
        type: "interjection",
        translation: "hello",
        example: "¡Hola! ¿Cómo estás?",
        fromLanguage: "Español",
        toLanguage: "English"
    )"""

QUIZ_ITEM = """QuizSessionManager.QuizItem(
        id: UUID(),
        word: "hola",
        translation: "hello",
        transcription: "ˈola",
        tag: "basics",
        example: "¡Hola!"
    )"""

LESSON_PLAN = """DailyLessonPlan(
        title: "Today's lesson",
        subtitle: "A short set for today",
        words: [],
        minutes: 4,
        styleLabel: "Mixed",
        topicLabels: ["Travel"],
        canStart: true,
        isDone: false,
        correct: 0,
        total: 0,
        tomorrowWords: []
    )"""

PREVIEWS: dict[str, str] = {}

def p(path: str, body: str) -> None:
    PREVIEWS[path] = body.strip() + "\n"

p(
    "Droword/Components/AchievementsView.swift",
    f"""
#Preview {{
    AchievementsView()
        {THEME}
        {WORDS}
        {BADGE}
}}
""",
)

p(
    "Droword/Components/AppIconStyle.swift",
    """
#Preview {
    HStack(spacing: 16) {
        AppIconArtwork(style: .classic, size: 72)
        AppIconArtwork(style: .sun, size: 72)
        AppIconArtwork(style: .night, size: 72)
    }
    .padding()
}
""",
)

p(
    "Droword/Components/AvatarPickerView.swift",
    f"""
#Preview {{
    AvatarPickerView(
        currentImage: nil,
        onPickedRaw: {{ _ in }},
        onRemoved: {{}}
    )
    {THEME}
}}
""",
)

p(
    "Droword/Components/BadgeCardView.swift",
    f"""
#Preview {{
    BadgeCardView(
        badge: BadgeDefinition(
            id: "words.10",
            emoji: "🌱",
            title: "Sprout",
            description: "Add 10 words",
            category: .wordCount,
            requiredCount: 10
        ),
        currentProgress: 4,
        isUnlocked: false
    )
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/BouncingDotsView.swift",
    """
#Preview {
    BouncingDotsView()
        .padding()
}
""",
)

p(
    "Droword/Components/BurningFlameIcon.swift",
    f"""
#Preview {{
    HStack(spacing: 16) {{
        BurningFlameIcon(size: 24)
        StreakFireBadge(count: 7)
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/ChatBubbleView.swift",
    f"""
#Preview {{
    VStack(spacing: 12) {{
        ChatBubbleView(
            message: SceneChatMessage(role: .assistant, text: "Hey! Try using hola."),
            showHint: true,
            onHint: {{ _ in }}
        )
        ChatBubbleView(
            message: SceneChatMessage(role: .user, text: "Hola!"),
            showHint: false,
            onHint: {{ _ in }}
        )
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/ChatSceneChrome.swift",
    f"""
#Preview("Header") {{
    ChatSceneHeaderView(word: "hola", translation: "hello", userTurns: 1)
        .padding()
        {THEME}
}}

#Preview("Typing") {{
    ChatTypingRow()
        .padding()
        {THEME}
}}

private struct ChatComposerBarPreview: View {{
    @State private var draft = "Hola"
    @FocusState private var focused: Bool

    var body: some View {{
        ChatComposerBar(draft: $draft, canSend: true, isFocused: $focused, onSend: {{}})
            {THEME}
    }}
}}

#Preview("Composer") {{
    ChatComposerBarPreview()
}}

#Preview("Done") {{
    ChatDoneBar(usedWord: true, onDone: {{}})
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/ChatSceneView.swift",
    f"""
#Preview {{
    ChatSceneView(
        target: ChatSceneTarget(
            id: UUID(),
            word: "hola",
            translation: "hello",
            example: "¡Hola!"
        )
    )
    {WORDS}
    {LANG}
    {THEME}
}}
""",
)

p(
    "Droword/Components/CloseButtonIcon.swift",
    f"""
#Preview {{
    HStack(spacing: 20) {{
        CloseButtonIcon()
        CloseButton()
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/CoachMarkView.swift",
    f"""
#Preview {{
    CoachMarkView(
        steps: [
            CoachMarkStep(title: "Add words", message: "Tap + to add a word.", icon: "plus.circle.fill"),
            CoachMarkStep(title: "Practice", message: "Review on a schedule.", icon: "bolt.fill")
        ],
        onComplete: {{}}
    )
    {THEME}
}}
""",
)

p(
    "Droword/Components/ConfettiView.swift",
    f"""
#Preview {{
    ZStack {{
        Color.black.opacity(0.05).ignoresSafeArea()
        ConfettiView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Components/CustomAlertView.swift",
    f"""
#Preview {{
    CustomAlertView(
        icon: "trash",
        iconColor: .red,
        title: "Delete word?",
        message: "This cannot be undone.",
        primaryButton: .init(title: "Delete", style: .destructive) {{}},
        secondaryButton: .init(title: "Cancel", style: .cancel) {{}}
    )
    {THEME}
}}
""",
)

p(
    "Droword/Components/DailyChallengeDetailView.swift",
    f"""
#Preview {{
    DailyChallengeDetailView(manager: DailyChallengeManager.shared)
        {THEME}
        {WORDS}
        {LANG}
}}
""",
)

p(
    "Droword/Components/DailyLessonCard.swift",
    f"""
#Preview {{
    DailyLessonCard(plan: {LESSON_PLAN}, onStart: {{}})
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/DailyLessonSessionView.swift",
    f"""
#Preview {{
    DailyLessonSessionView(plan: {LESSON_PLAN})
        {WORDS}
        {LANG}
        {THEME}
        {BADGE}
}}
""",
)

p(
    "Droword/Components/FirstWordsView.swift",
    f"""
#Preview {{
    FirstWordsView(onDismiss: {{}})
        {THEME}
        {LANG}
        {WORDS}
}}
""",
)

p(
    "Droword/Components/FloatingRewardLabel.swift",
    """
#Preview {
    FloatingRewardLabel(text: "+10", color: .orange)
        .frame(width: 120, height: 120)
}
""",
)

p(
    "Droword/Components/FontSizePickerView.swift",
    f"""
#Preview {{
    NavigationStack {{
        FontSizePickerView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Components/HomeStreakStrip.swift",
    f"""
#Preview {{
    HomeStreakStrip(onOpenCalendar: {{}})
        .padding()
        {WORDS}
        {THEME}
}}
""",
)

p(
    "Droword/Components/HomeVisibilityHint.swift",
    f"""
#Preview {{
    NavigationStack {{
        HomeVisibilityHint(message: "Word packs are hidden. Turn them on in settings.")
            .padding()
    }}
    {THEME}
    {WORDS}
    {LANG}
}}
""",
)

p(
    "Droword/Components/InstagramStoriesShareView.swift",
    f"""
#Preview("Word") {{
    InstagramStoriesTemplateView(
        word: {SAMPLE_WORD},
        themeStore: ThemeStore()
    )
}}

#Preview("Streak") {{
    ShareStreakTemplateView(
        streak: 12,
        word: {SAMPLE_WORD},
        themeStore: ThemeStore()
    )
}}
""",
)

p(
    "Droword/Components/Language/LanguageCube.swift",
    f"""
#Preview {{
    LanguageCube(
        language: LanguageCatalog.availableLanguages[0],
        isSelected: true,
        isBlocked: false,
        onTap: {{}}
    )
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/Language/LanguagePreferencesView.swift",
    f"""
#Preview {{
    NavigationStack {{
        LanguagePreferencesView()
    }}
    {LANG}
    {THEME}
}}
""",
)

p(
    "Droword/Components/LearningPreferencesView.swift",
    f"""
#Preview("Form") {{
    LearningPreferencesForm(profile: LearningProfileStore.shared)
        .padding()
        {THEME}
}}

#Preview("Settings") {{
    NavigationStack {{
        LearningPreferencesView()
    }}
    {THEME}
}}

#Preview("Onboarding") {{
    OnboardingPreferencesPage()
        {THEME}
}}
""",
)

p(
    "Droword/Components/LoadingStagesView.swift",
    """
#Preview {
    LoadingStagesView(color: .blue)
        .padding()
        .background(Color.gray.opacity(0.2))
}
""",
)

p(
    "Droword/Components/Louder.swift",
    f"""
#Preview {{
    Loader()
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/MenuSymbol.swift",
    f"""
#Preview {{
    MenuSymbol(systemName: "gearshape")
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/MilestoneCelebrationView.swift",
    f"""
#Preview {{
    MilestoneCelebrationView(milestone: .wordCount(50), onDismiss: {{}})
        {THEME}
}}
""",
)

p(
    "Droword/Components/PerfectLessonBadge.swift",
    f"""
#Preview {{
    PerfectLessonBadge()
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/PracticeEmptyContent.swift",
    f"""
#Preview {{
    PracticeEmptyContent(
        icon: "bolt.fill",
        title: "Nothing due",
        subtitle: "Add a few words and come back.",
        tip: "Four words unlock practice"
    )
    {THEME}
}}
""",
)

p(
    "Droword/Components/PremiumView.swift",
    f"""
#Preview {{
    NavigationStack {{
        PremiumView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Components/ProBadgeIcon.swift",
    f"""
#Preview {{
    HStack(spacing: 16) {{
        ProBadgeIcon()
        ProPlusMark()
        ProPillBadge()
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/QuickReviewSessionView.swift",
    f"""
#Preview {{
    QuickReviewSessionView()
        {WORDS}
        {LANG}
        {THEME}
}}
""",
)

p(
    "Droword/Components/QuickSessionCard.swift",
    f"""
#Preview {{
    QuickSessionCard(dueCount: 6, onStart: {{}})
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizClozeExercise.swift",
    f"""
private struct QuizClozeExercisePreview: View {{
    @State private var typingInput = ""
    @FocusState private var focused: Bool

    var body: some View {{
        QuizClozeExercise(
            item: {QUIZ_ITEM},
            hasAnswered: false,
            isCorrect: false,
            isAlmostCorrect: false,
            clozeRevealed: false,
            shakeOffset: 0,
            hintShown: false,
            hintText: "",
            typingInput: $typingInput,
            isInputFocused: $focused,
            onSubmit: {{}}
        )
        {THEME}
    }}
}}

#Preview {{
    QuizClozeExercisePreview()
}}
""",
)

p(
    "Droword/Components/Quiz/QuizComboBadge.swift",
    f"""
#Preview {{
    QuizComboBadge(streak: 5)
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizCompletionView.swift",
    f"""
#Preview {{
    QuizCompletionView(correct: 8, total: 10, onRestart: {{}})
        {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizFeedbackBadge.swift",
    """
#Preview {
    QuizFeedbackBadge(icon: "checkmark.circle.fill", text: "Nice!", color: .green)
        .padding()
}
""",
)

p(
    "Droword/Components/Quiz/QuizListeningExercise.swift",
    f"""
#Preview {{
    QuizListeningExercise(
        item: {QUIZ_ITEM},
        hasAnswered: false,
        isCorrect: false,
        options: ["hello", "bye", "please", "thanks"],
        selectedOption: nil,
        shakeOffset: 0,
        onSelect: {{ _ in }}
    )
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizMatchingExercise.swift",
    f"""
private struct QuizMatchingExercisePreview: View {{
    @State private var matchingPairs = [
        QuizSessionManager.MatchingPair(word: "hola", translation: "hello"),
        QuizSessionManager.MatchingPair(word: "adiós", translation: "bye")
    ]
    @State private var matchedPairIDs: Set<UUID> = []
    @State private var selectedMatchWordID: UUID?
    @State private var selectedMatchTranslationID: UUID?
    @State private var matchingWrongIDs: (UUID, UUID)?
    @State private var shuffledTranslationIDs: [UUID] = []

    var body: some View {{
        QuizMatchingExercise(
            item: {QUIZ_ITEM},
            hasAnswered: false,
            isCorrect: false,
            wrongAttempts: 0,
            maxAttempts: 3,
            matchingPairs: $matchingPairs,
            matchedPairIDs: $matchedPairIDs,
            selectedMatchWordID: $selectedMatchWordID,
            selectedMatchTranslationID: $selectedMatchTranslationID,
            matchingWrongIDs: $matchingWrongIDs,
            shuffledTranslationIDs: $shuffledTranslationIDs,
            onAllMatched: {{}}
        )
        .padding()
        {THEME}
        .onAppear {{
            if shuffledTranslationIDs.isEmpty {{
                shuffledTranslationIDs = matchingPairs.map(\\.id)
            }}
        }}
    }}
}}

#Preview {{
    QuizMatchingExercisePreview()
}}
""",
)

p(
    "Droword/Components/Quiz/QuizMultipleChoiceExercise.swift",
    f"""
#Preview {{
    QuizMultipleChoiceExercise(
        item: {QUIZ_ITEM},
        hasAnswered: false,
        isCorrect: false,
        isReversed: false,
        options: ["hello", "bye", "please", "thanks"],
        selectedOption: nil,
        shakeOffset: 0,
        onSelect: {{ _ in }}
    )
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizNotEnoughView.swift",
    """
#Preview {
    QuizNotEnoughView()
}
""",
)

p(
    "Droword/Components/Quiz/QuizProgressHeader.swift",
    f"""
#Preview {{
    QuizProgressHeader(
        session: QuizSessionManager(),
        streakScale: 1,
        hasAnswered: false,
        isCorrect: false,
        reward: nil
    )
    {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizSentenceBuildingExercise.swift",
    f"""
private struct QuizSentenceBuildingExercisePreview: View {{
    @State private var sentenceWords = ["Hola", "amigo"]
    @State private var selectedSentenceWords: [String] = []

    var body: some View {{
        QuizSentenceBuildingExercise(
            item: {QUIZ_ITEM},
            hasAnswered: false,
            isCorrect: false,
            shakeOffset: 0,
            sentenceWords: $sentenceWords,
            selectedSentenceWords: $selectedSentenceWords,
            correctSentenceWords: ["Hola", "amigo"]
        )
        .padding()
        {THEME}
    }}
}}

#Preview {{
    QuizSentenceBuildingExercisePreview()
}}
""",
)

p(
    "Droword/Components/Quiz/QuizStreakMilestoneBanner.swift",
    f"""
#Preview {{
    QuizStreakMilestoneBanner(streak: 10)
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/Quiz/QuizTypingExercise.swift",
    f"""
private struct QuizTypingExercisePreview: View {{
    @State private var typingInput = ""
    @FocusState private var focused: Bool

    var body: some View {{
        QuizTypingExercise(
            item: {QUIZ_ITEM},
            hasAnswered: false,
            isCorrect: false,
            isAlmostCorrect: false,
            isReversed: false,
            shakeOffset: 0,
            hintShown: false,
            hintText: "",
            typingInput: $typingInput,
            isInputFocused: $focused,
            onSubmit: {{}}
        )
        {THEME}
    }}
}}

#Preview {{
    QuizTypingExercisePreview()
}}
""",
)

p(
    "Droword/Components/ReviewSectionView.swift",
    f"""
#Preview {{
    ReviewSectionView()
        {WORDS}
        {LANG}
        {THEME}
}}
""",
)

p(
    "Droword/Components/SeasonEffects/LeafView.swift",
    """
#Preview {
    LeafView(size: 40)
        .padding()
}
""",
)

p(
    "Droword/Components/SeasonEffects/SakuraFlower.swift",
    """
#Preview {
    SakuraFlower(size: 40)
        .padding()
}
""",
)

p(
    "Droword/Components/SeasonEffects/SnowflakeView.swift",
    """
#Preview {
    SnowflakeView(size: 40)
        .padding()
}
""",
)

p(
    "Droword/Components/SeasonEffects/SunView.swift",
    """
#Preview {
    SunView(size: 40)
        .padding()
}
""",
)

p(
    "Droword/Components/ShareWordCardView.swift",
    f"""
#Preview {{
    ShareWordCardView(
        word: {SAMPLE_WORD},
        backgroundColor: Color(red: 0.95, green: 0.95, blue: 0.97)
    )
    .padding()
}}
""",
)

p(
    "Droword/Components/StatusBannerView.swift",
    f"""
#Preview {{
    StatusBannerView(
        icon: "wifi.slash",
        title: "You're offline",
        subtitle: "AI features need a connection."
    )
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Components/StoryView.swift",
    f"""
#Preview("Card") {{
    ReadingStoryCard(onTap: {{}})
        .padding()
        {THEME}
}}

#Preview("Story") {{
    StoryView()
        {WORDS}
        {LANG}
        {THEME}
}}
""",
)

p(
    "Droword/Components/TagBadge.swift",
    f"""
#Preview {{
    TagBadge(text: "Travel")
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Components/WhatsNewView.swift",
    f"""
#Preview {{
    WhatsNewView()
        {THEME}
}}
""",
)

p(
    "Droword/Components/WordPacksSectionView.swift",
    f"""
#Preview("Button") {{
    WordPacksButton(availableCount: 3)
        .padding()
        {THEME}
        {LANG}
}}

#Preview("Detail") {{
    NavigationStack {{
        WordPacksDetailView()
    }}
    {THEME}
    {LANG}
    {WORDS}
}}
""",
)

p(
    "Droword/Components/ZoomerUI.swift",
    f"""
#Preview {{
    VStack(spacing: 16) {{
        ZoomerSticker(text: "new")
        ZoomerCountBadge(value: 3)
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Helpers/SoundWavesView.swift",
    f"""
#Preview {{
    SoundWavesView(isPlaying: true)
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Home/DictionarySettingsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        DictionarySettingsView()
    }}
    {WORDS}
    {LANG}
    {THEME}
}}
""",
)

p(
    "Droword/Home/FeatureFlagsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        FeatureFlagsView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Home/HapticSettingsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        HapticSettingsView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Home/HomeNextReviewCard.swift",
    f"""
#Preview {{
    HomeNextReviewCard(count: 5, date: Date().addingTimeInterval(86400), onDismiss: {{}})
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Home/HomeView.swift",
    f"""
#Preview {{
    HomeView()
        {WORDS}
        {LANG}
        {THEME}
        {BADGE}
        {SUGG}
        {STUDY}
}}
""",
)

p(
    "Droword/Home/NotificationSettingsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        NotificationSettingsView()
    }}
    {THEME}
    {WORDS}
    {LANG}
}}
""",
)

p(
    "Droword/Home/PrivacyPolicyView.swift",
    f"""
#Preview {{
    NavigationStack {{
        PrivacyPolicyView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Home/RadioButtonRow.swift",
    f"""
#Preview {{
    VStack {{
        RadioButtonRow(title: "Option A", isSelected: true, action: {{}})
        RadioButtonRow(title: "Option B", isSelected: false, action: {{}})
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Home/SeasonalEffectsSettingsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        SeasonalEffectsSettingsView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Home/SettingsBackButton.swift",
    f"""
#Preview {{
    SettingsBackButton()
        .padding()
        {THEME}
}}
""",
)

p(
    "Droword/Home/TermsOfUseView.swift",
    f"""
#Preview {{
    NavigationStack {{
        TermsOfUseView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Home/VoiceAndSpeechSettingsView.swift",
    f"""
#Preview {{
    NavigationStack {{
        VoiceAndSpeechSettingsView()
    }}
    {THEME}
}}
""",
)

p(
    "Droword/Onboarding/CustomizeIllustration.swift",
    """
#Preview {
    CustomizeIllustration(accent: .orange, size: 220, px: 0, py: 0)
}
""",
)

p(
    "Droword/Onboarding/DictionaryIllustration.swift",
    """
#Preview {
    DictionaryIllustration(accent: .blue, size: 220, px: 0, py: 0)
}
""",
)

p(
    "Droword/Onboarding/DrowordSpotArt.swift",
    f"""
#Preview {{
    VStack(spacing: 24) {{
        SoftBlob(color: .blue, size: 120)
        HaloIcon(symbol: "plus", color: .blue, size: 120)
        EmptyDictionaryArt()
        EmptyPracticeArt()
    }}
    .padding()
    {THEME}
}}
""",
)

p(
    "Droword/Onboarding/OnboardingPageView.swift",
    f"""
#Preview {{
    OnboardingPageView(
        model: OnboardingPageModel(
            title: "Build your dictionary",
            subtitle: "Save words with examples and tags.",
            illustrationStyle: .dictionary,
            accent: .blue
        ),
        animateStage: true,
        dragOffset: .zero,
        containerSize: CGSize(width: 390, height: 844)
    )
    {THEME}
}}
""",
)

p(
    "Droword/Onboarding/OnboardingReplayView.swift",
    f"""
#Preview {{
    OnboardingReplayView()
        {THEME}
}}
""",
)

p(
    "Droword/Onboarding/PracticeIllustration.swift",
    """
#Preview {
    PracticeIllustration(accent: .green, size: 220, px: 0, py: 0)
}
""",
)

p(
    "Droword/Skeleton/SkeletonWordCardView.swift",
    """
#Preview {
    SkeletonWordCardView()
        .padding()
}
""",
)

p(
    "Droword/Skeleton/SuggestedWordSkeletonCard.swift",
    f"""
#Preview {{
    SuggestedWordSkeletonCard()
        .padding()
        {THEME}
}}
""",
)

def main() -> None:
    updated = 0
    skipped = 0
    missing_map = []

    for rel, preview in PREVIEWS.items():
        path = ROOT / rel
        if not path.exists():
            missing_map.append(rel)
            continue
        text = path.read_text(encoding="utf-8")
        if "#Preview" in text or "PreviewProvider" in text:
            skipped += 1
            continue
        if not text.endswith("\n"):
            text += "\n"
        path.write_text(text + "\n" + preview, encoding="utf-8")
        updated += 1
        print(f"updated {rel}")

    print(f"\nupdated={updated} skipped={skipped} missing_paths={len(missing_map)}")
    for rel in missing_map:
        print(f"  missing path: {rel}")
    print(f"defined={len(PREVIEWS)}")

if __name__ == "__main__":
    main()
