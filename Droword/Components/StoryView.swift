import SwiftUI
import UIKit

struct ReadingStoryCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.pages")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(themeStore.mainText)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)
                    Text(DuoChaosCopy.readingSubtitle())
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
                    .frame(width: 28, height: 28)
            }
            .padding(DesignSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Reading practice"))
    }
}

struct StoryView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    @State private var story: StoryResult?
    @State private var isLoading = false
    @State private var loadingLine = DuoChaosCopy.storyWriting()
    @State private var errorMessage: String?
    @State private var showTranslation = false
    @State private var showPremiumWall = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let story {
                    GeometryReader { geo in
                        ScrollView(showsIndicators: false) {
                            storyContent(story)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 24)
                                .iPadContentWidth(600)
                                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                        }
                    }
                } else if let errorMessage {
                    errorView(errorMessage)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
            }
        }
        .task {
            if story == nil { await load() }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func storyContent(_ story: StoryResult) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Text(Self.plainText(story.title, words: story.usedWords))
                .font(themeStore.bold(24))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.center)

            Text(highlightedStory(story.story, words: story.usedWords))
                .font(themeStore.regular(19))
                .foregroundStyle(themeStore.mainText)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if showTranslation {
                Text(Self.plainText(story.translation, words: story.usedWords))
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
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
                VStack(alignment: .center, spacing: 6) {
                    Text("Slipped into the story")
                        .font(themeStore.medium(13))
                        .foregroundStyle(themeStore.secondaryText)
                    FlowLayout(spacing: 8) {
                        ForEach(story.usedWords, id: \.self) { w in
                            Text(w)
                                .font(themeStore.medium(14))
                                .foregroundStyle(Color("AccentGold"))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule().fill(Color("AccentGold").opacity(0.14))
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
                    RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                        .fill(themeStore.mainAccentColor.opacity(0.12))
                )
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.top, 8)

            Button {
                Haptics.softTap()
                dismiss()
            } label: {
                Text("Close")
                    .duo3DStyle(themeStore.secondaryText.opacity(0.55))
            }
            .buttonStyle(Duo3DButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            Text(loadingLine)
                .font(themeStore.regular(15))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .id(loadingLine)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadingLine = DuoChaosCopy.storyWriting()
        }
        .task(id: isLoading) {
            guard isLoading else { return }
            while !Task.isCancelled && isLoading {
                try? await Task.sleep(for: .seconds(2.4))
                guard isLoading else { break }
                withAnimation(.easeInOut(duration: 0.25)) {
                    loadingLine = DuoChaosCopy.storyWriting()
                }
            }
        }
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
                Text(DuoChaosCopy.storyTryAgain())
                    .duo3DStyle(themeStore.mainAccentColor)
            }
            .buttonStyle(Duo3DButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func highlightedStory(_ text: String, words: [String]) -> AttributedString {
        let cleaned = Self.plainText(text, words: words)
        var attributed = AttributedString(cleaned)
        let gold = UIColor(Color("AccentGold"))
        let highlightFont = UIFont(name: "Poppins-Bold", size: 19)
            ?? .systemFont(ofSize: 19, weight: .bold)
        let ns = cleaned as NSString
        for word in words where word.count >= 2 {
            var search = NSRange(location: 0, length: ns.length)
            while true {
                let found = ns.range(of: word, options: [.caseInsensitive, .diacriticInsensitive], range: search)
                if found.location == NSNotFound { break }
                if let stringRange = Range(found, in: cleaned),
                   let attrRange = Range(stringRange, in: attributed) {
                    attributed[attrRange].foregroundColor = gold
                    attributed[attrRange].font = highlightFont
                }
                let next = found.location + max(found.length, 1)
                if next >= ns.length { break }
                search = NSRange(location: next, length: ns.length - next)
            }
        }
        return attributed
    }

    private static func plainText(_ text: String, words: [String]) -> String {
        var result = text
        let wrappers: [(String, String)] = [
            ("***", "***"),
            ("**", "**"),
            ("*", "*"),
            ("__", "__"),
            ("_", "_"),
            ("\"", "\""),
            ("«", "»"),
            ("“", "”"),
            ("‘", "’"),
            ("'", "'"),
            ("`", "`")
        ]
        for word in words where word.count >= 2 {
            for (left, right) in wrappers {
                result = result.replacingOccurrences(
                    of: "\(left)\(word)\(right)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        result = result.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"(?<=\S)\*+"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*+(?=\S)"#, with: "", options: .regularExpression)
        for word in words where word.count >= 2 {
            for mark in ["\"", "«", "»", "“", "”", "`"] {
                result = result.replacingOccurrences(
                    of: "\(mark)\(word)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
                result = result.replacingOccurrences(
                    of: "\(word)\(mark)",
                    with: word,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        return result
    }

    private func load() async {
        let words = StoryWordPicker.candidates(
            from: store.words,
            learningLanguage: languageStore.learningLanguage,
            preferredTags: LearningProfileStore.shared.preferredTagNames
        )
        guard words.count >= 3 else {
            errorMessage = String(localized: "Add a few more words first, then I can write you a story.")
            return
        }
        guard isPremium || DailyLimitsManager.canGenerateStory else {
            showPremiumWall = true
            if story == nil {
                errorMessage = String(localized: "You've used today's free stories. Upgrade to PRO for unlimited.")
            }
            return
        }
        errorMessage = nil
        showTranslation = false
        withAnimation { isLoading = true }
        do {
            let profile = LearningProfileStore.shared
            let result = try await generateStory(
                words: words,
                languageStore: languageStore,
                goal: profile.goal.localizedTitle,
                topics: profile.topics.map(\.localizedTitle)
            )
            if !isPremium {
                DailyLimitsManager.recordStory()
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                story = result
                isLoading = false
            }
        } catch {
            withAnimation { isLoading = false }
            let isOffline = !NetworkMonitor.shared.isConnected
                || (error as? APIError).map { if case .noConnection = $0 { return true }; return false } ?? false
            if isOffline {
                errorMessage = String(localized: "You're offline. Connect to generate a story.")
            } else {
                errorMessage = String(localized: "Couldn't create a story right now. Please try again.")
            }
        }
    }
}

#Preview("Card") {
    ReadingStoryCard(onTap: {})
        .padding()
        .environmentObject(ThemeStore())
}

#Preview("Story") {
    StoryView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}
