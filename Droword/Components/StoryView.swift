import SwiftUI

/// Home entry point for reading mode.
struct ReadingStoryCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    var onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeStore.iconCircleFill(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeStore.accentPink)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)
                    Text("A quick story from your words")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentPink)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
            .cardDepth(cornerRadius: 16)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Reading practice"))
    }
}

/// Reading mode: generates a short story in the learning language from words the
/// user is currently studying, with a tappable translation. Words in context
/// stick far better than isolated flashcards (comprehensible input).
struct StoryView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var story: StoryResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showTranslation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Reading")
                        .sheetTitle()

                    if isLoading {
                        loadingView
                    } else if let story {
                        storyContent(story)
                    } else if let errorMessage {
                        errorView(errorMessage)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .iPadContentWidth(600)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsBackButton()
                        .environmentObject(themeStore)
                }
            }
        }
        .task {
            if story == nil { await load() }
        }
    }

    // MARK: - Content

    private func storyContent(_ story: StoryResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(story.title)
                .font(themeStore.bold(24))
                .foregroundStyle(themeStore.mainText)

            Text(story.story)
                .font(themeStore.regular(19))
                .foregroundStyle(themeStore.mainText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if showTranslation {
                Text(story.translation)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showTranslation = true }
                    Haptics.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "character.book.closed")
                        Text("Show translation")
                    }
                    .font(themeStore.medium(15))
                    .foregroundStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(.plain)
            }

            if !story.usedWords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Words in this story")
                        .font(themeStore.medium(13))
                        .foregroundStyle(themeStore.secondaryText)
                    FlowLayout(spacing: 8) {
                        ForEach(story.usedWords, id: \.self) { w in
                            Text(w)
                                .font(themeStore.medium(14))
                                .foregroundStyle(themeStore.mainAccentColor)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule().fill(themeStore.mainAccentColor.opacity(0.12))
                                )
                        }
                    }
                }
                .padding(.top, 4)
            }

            Button {
                Haptics.lightImpact()
                Task { await load() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("New story")
                }
                .font(themeStore.bold(17))
                .foregroundStyle(themeStore.mainAccentColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.mainAccentColor.opacity(0.12))
                )
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.top, 8)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            LoadingStagesView(
                dotSize: 14,
                bounceHeight: 10,
                spacing: 10,
                color: themeStore.mainAccentColor
            )
            .frame(height: 34)

            Text("Writing a story from your words…")
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(themeStore.secondaryText)
            Text(message)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                Task { await load() }
            } label: {
                Text("Try again")
                    .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Logic

    /// Picks a handful of words to build the story from, preferring ones the user
    /// is actively learning (introduced, translated), newest first.
    private func pickWords() -> [String] {
        let usable = store.words.filter { $0.translation?.isEmpty == false }
        let learning = usable.filter { $0.introduced }
        let pool = (learning.isEmpty ? usable : learning)
            .sorted { $0.dateAdded > $1.dateAdded }
        return Array(pool.prefix(8).map { $0.word }).shuffled()
    }

    private func load() async {
        let words = pickWords()
        guard words.count >= 3 else {
            errorMessage = String(localized: "Add a few more words first, then I can write you a story.")
            return
        }
        errorMessage = nil
        showTranslation = false
        withAnimation { isLoading = true }
        do {
            let result = try await generateStory(words: words, languageStore: languageStore)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                story = result
                isLoading = false
            }
        } catch {
            withAnimation { isLoading = false }
            errorMessage = String(localized: "Couldn't create a story right now. Please try again.")
        }
    }
}
