import SwiftUI
import AVFoundation
import UIKit

struct WordCard: Identifiable {
    let id: UUID
    let word: String
    let partOfSpeech: String
    let example: String
    let translation: String
    let explanation: String?
    let breakdown: String?
    let transcription: String?
    let tag: String?
    let fromLanguage: String?
    let toLanguage: String?
    let comment: String?
}

enum PracticeMode: String, CaseIterable {
    case practice = "Practice"
    case review = "Review"
    case listening = "Listening"
}

struct PracticeView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var selectedMode: PracticeMode = .practice
    @State private var currentIndex: Int = 0
    @State private var learningQueue: [WordCard] = []
    @State private var showCompletion = false
    @State private var showListeningPlayer = false
    @State private var showPremiumWall = false
    @AppStorage("isPremium") private var isPremium: Bool = false

    private var hasEnoughWordsForPractice: Bool {
        store.words.filter { $0.translation != nil && !$0.translation!.isEmpty }.count >= 4
    }

    private func dueWords(from words: [StoredWord]) -> [StoredWord] {
        let today = Calendar.current.startOfDay(for: Date())
        return words.filter { w in
            if let due = w.dueDate {
                return due <= today
            } else {
                return true
            }
        }
    }

    private func prepareSession() {
        let due = dueWords(from: store.words)
        learningQueue = due.map { word in
            WordCard(
                id: word.id,
                word: word.word,
                partOfSpeech: word.type.isEmpty ? "word" : word.type,
                example: word.example ?? "Add an example later",
                translation: word.translation ?? "No translation yet",
                explanation: word.explanation,
                breakdown: word.breakdown,
                transcription: word.transcription,
                tag: word.tag,
                fromLanguage: word.fromLanguage,
                toLanguage: word.toLanguage,
                comment: word.comment
            )
        }
        currentIndex = 0
        showCompletion = false
    }

    private enum Rating { case again, hard, good, easy }

    private func scheduleNext(for card: WordCard, rating: Rating) {
        guard let w = store.words.first(where: { $0.id == card.id }) else {
            showNextCard(); return
        }

        var ef = max(1.3, w.easeFactor)
        var reps = w.repetitions
        var ivl = w.intervalDays
        var lapses = w.lapses

        let q: Double
        switch rating {
        case .again: q = 1
        case .hard:  q = 3
        case .good:  q = 4
        case .easy:  q = 5
        }

        let quality: Double
        switch rating {
        case .again: quality = 0.0
        case .hard:  quality = 0.35
        case .good:  quality = 0.7
        case .easy:  quality = 1.0
        }
        let alpha = 0.06
        let prev = languageStore.learningScore
        languageStore.learningScore = max(0.0, min(1.0, prev * (1 - alpha) + quality * alpha))

        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = max(1.3, ef)

        let now = Date()
        let cal = Calendar.current

        if q < 3 {
            lapses += 1
            reps = 0
            ivl = 0
            reinsert(card, after: 2)
            let due = cal.date(byAdding: .minute, value: 10, to: now)
            store.updateScheduling(for: card.id,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
        } else {
            reps += 1
            if reps == 1 {
                ivl = 1
            } else if reps == 2 {
                ivl = 6
            } else {
                ivl = max(1, Int(round(Double(ivl) * ef)))
            }
            let due = cal.date(byAdding: .day, value: ivl, to: now)
            store.updateScheduling(for: card.id,
                                   easeFactor: ef,
                                   intervalDays: ivl,
                                   repetitions: reps,
                                   lapses: lapses,
                                   dueDate: due)
            showNextCard()
        }
    }

    private func reinsert(_ card: WordCard, after positions: Int) {
        guard currentIndex < learningQueue.count else { return }
        learningQueue.remove(at: currentIndex)
        let newIndex = min(currentIndex + positions, learningQueue.count)
        learningQueue.insert(card, at: newIndex)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 8)

                Group {
                    switch selectedMode {
                    case .practice:
                        if !hasEnoughWordsForPractice {
                            practiceEmptyState
                        } else {
                            QuizMixedView(sessionSize: 15, filterTag: nil)
                        }
                    case .review:
                        reviewContent
                    case .listening:
                        listeningEntryView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedMode == .review { prepareSession() }
        }
        .onChange(of: selectedMode) { _ in
            if selectedMode == .review { prepareSession() }
        }
        .fullScreenCover(isPresented: $showListeningPlayer) {
            ListeningPlayerView()
                .environmentObject(store)
                .environmentObject(themeStore)
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private var reviewContent: some View {
        Group {
            if learningQueue.isEmpty {
                emptyState
            } else if currentIndex < learningQueue.count && !showCompletion {
                ScrollView(showsIndicators: false) {
                    VStack {
                        WordCardPracticeView(
                            card: learningQueue[currentIndex],
                            onAgain: { scheduleNext(for: learningQueue[currentIndex], rating: .again) },
                            onHard:  { scheduleNext(for: learningQueue[currentIndex], rating: .hard) },
                            onGood:  { scheduleNext(for: learningQueue[currentIndex], rating: .good) },
                            onEasy:  { scheduleNext(for: learningQueue[currentIndex], rating: .easy) }
                        )
                        .id(learningQueue[currentIndex].id)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8),
                                   value: currentIndex)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                completionScreen
            }
        }
    }

    private var practiceEmptyState: some View {
        PracticeEmptyContent(
            icon: "rectangle.stack.badge.plus",
            title: "Not enough words yet",
            subtitle: "Add at least 4 words with translations to start practicing.",
            tip: "Tip: grab words from movies, chats, or walks — learning feels alive that way."
        )
    }

    private var emptyState: some View {
        PracticeEmptyContent(
            icon: "clock.badge.checkmark",
            title: "Nothing to review yet",
            subtitle: "Add a few words — I'll prepare your first mini‑session. Start small and show up daily. That's how progress sticks.",
            tip: "Tip: grab words from movies, chats, or walks — learning feels alive that way."
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice")
                .font(.custom("Poppins-Bold", size: 38))
                .foregroundColor(.mainBlack)

            modePicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(PracticeMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                    Haptics.selection()
                } label: {
                    Text(mode.rawValue)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(selectedMode == mode ? .white : Color.mainBlack)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedMode == mode ? themeStore.buttonAccent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground)
        )
    }


    private var completionScreen: some View {
        ReviewCompletionContent()
    }

    private var listeningEntryView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 56))
                .foregroundColor(.mainBlack.opacity(0.25))

            VStack(spacing: 8) {
                Text("Audio flashcards")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.mainBlack)

                Text("Listen to words with pauses for active recall. Put on headphones and learn while doing other things.")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                Haptics.mediumImpact()
                if isPremium || DailyLimitsManager.canPlayTTS {
                    showListeningPlayer = true
                } else {
                    showPremiumWall = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Open player")
                        .font(.custom("Poppins-Bold", size: 16))
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(store.words.isEmpty ? Color.mainGrey.opacity(0.3) : themeStore.buttonAccent)
                )
            }
            .buttonStyle(.plain)
            .disabled(store.words.isEmpty)

            if store.words.isEmpty {
                Text("Add some words first")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.mainGrey.opacity(0.7))
                    .padding(.top, 6)
            }

            Spacer()
            Spacer()
        }
    }

    private func showNextCard() {
        currentIndex += 1
    }
}

private struct PracticeEmptyContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let tip: String

    @State private var iconScale: CGFloat = 0.4
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.mainGrey.opacity(0.35))
                .scaleEffect(iconScale)

            Text(title)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)

            Text(subtitle)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            Text(tip)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

private struct ReviewCompletionContent: View {
    @State private var emojiScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()

                Text("🎉")
                    .font(.system(size: 56))
                    .scaleEffect(emojiScale)

                Text("Session complete!")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.mainBlack)
                    .opacity(textOpacity)

                Text("You've reviewed all scheduled words for now.")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.mainGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(textOpacity)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                textOpacity = 1.0
            }
        }
    }
}

private struct RatingButton: View {
    let title: String
    let bg: Color
    let fg: Color?
    let action: () -> Void

    var body: some View {
        let textColor = fg ?? darkerShade(of: bg, by: 0.4)
        return Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 14))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(bg)
                )
                .foregroundColor(textColor)
        }
        .buttonStyle(.plain)
    }
}

struct WordCardPracticeView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore

    let card: WordCard

    let onAgain: () -> Void
    let onHard: () -> Void
    let onGood: () -> Void
    let onEasy: () -> Void

    @State private var isPlaying = false
    @State private var showTranslation = false
    @State private var showPremiumWall = false
    @AppStorage("isPremium") private var isPremium: Bool = false

    private var backgroundColor: Color {
        if let tag = card.tag {
            switch tag {
            case "Chat":   return themeStore.accentBlue
            case "Travel": return themeStore.accentGreen
            case "Street": return themeStore.accentPink
            case "Movies": return themeStore.accentPurple
            case "Golden": return themeStore.accentGold
            default:
                if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }) {
                    return themeStore.resolvedTagColor(custom.colorHex)
                }
            }
        }
        return Color.cardBackground
    }

    private var isDarkBackground: Bool {
        backgroundColor.isDarkColor
    }

    private var primaryTextColor: Color {
        isDarkBackground ? .white : .mainBlack
    }

    private var secondaryTextColor: Color {
        isDarkBackground ? Color.white.opacity(0.85) : .mainBlack.opacity(0.8)
    }

    private var adaptedExample: String {
        let lang = languageStore.learningLanguage
        let level = CEFRLevel(rawValue: languageStore.learningLevel) ?? .A1
        return LevelAdaptation.adaptExample(card.example, targetLanguage: lang, level: level)
    }

    private func highlightedExample(example: String, target: String) -> AttributedString {
        var attr = AttributedString(example)
        let lowerExample = example.lowercased()
        let lowerTarget = target.lowercased()

        guard let range = lowerExample.range(of: lowerTarget) else { return attr }

        let startOK: Bool = {
            if range.lowerBound == lowerExample.startIndex { return true }
            let prev = lowerExample.index(before: range.lowerBound)
            return !lowerExample[prev].isLetter && !lowerExample[prev].isNumber
        }()

        let endOK: Bool = {
            if range.upperBound == lowerExample.endIndex { return true }
            let next = range.upperBound
            return !lowerExample[next].isLetter && !lowerExample[next].isNumber
        }()

        if startOK && endOK,
           let attrStart = AttributedString.Index(range.lowerBound, within: attr),
           let attrEnd = AttributedString.Index(range.upperBound, within: attr) {
            let highlightRange = attrStart..<attrEnd
            attr[highlightRange].foregroundColor = Color(red: 1.0, green: 0.549, blue: 0.259)
            attr[highlightRange].font = .custom("Poppins-SemiBold", size: 18)
        }
        return attr
    }

    private struct TagBadge: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.custom("Poppins-SemiBold", size: 11))
                .foregroundColor(.mainBlack)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tag = card.tag, !tag.isEmpty {
                Text(tag)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(isDarkBackground ? Color.white.opacity(0.9) : darkerShade(of: backgroundColor, by: 0.45))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(backgroundColor.opacity(isDarkBackground ? 0.5 : 0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(darkerShade(of: backgroundColor, by: 0.15), lineWidth: 1.5)
                    )
                    .padding(.bottom, 2)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.word)
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    if let tr = card.transcription, !tr.isEmpty {
                        Text(tr)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(secondaryTextColor)
                    }
                }
                Spacer()
                Button(action: { Haptics.selection(); playAudio() }) {
                    SoundWavesView(isPlaying: isPlaying)
                        .frame(width: 24, height: 24)
                        .tint(primaryTextColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }

            Text(card.partOfSpeech.capitalized)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(secondaryTextColor)

            if let comment = card.comment, !comment.isEmpty {
                Text(comment)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(secondaryTextColor)
                    .padding(.horizontal, 2)
            }

            if !card.translation.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    if showTranslation {
                        Text(card.translation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(primaryTextColor)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        let first = card.translation.prefix(1)
                        Text("\(first)•••")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(isDarkBackground ? Color.white.opacity(0.7) : .mainBlack.opacity(0.5))
                    }
                    Spacer()
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showTranslation.toggle() } }) {
                        Text(showTranslation ? "Hide" : "Show")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(isDarkBackground ? Color.white.opacity(0.85) : .mainBlack.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                Text("Try to recall the translation without looking.")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(isDarkBackground ? Color.white.opacity(0.7) : .mainBlack.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(highlightedExample(example: adaptedExample, target: card.word))
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(primaryTextColor)
                }

                if let explanation = card.explanation, !explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(explanation)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(primaryTextColor)
                    }
                }

                if let breakdown = card.breakdown, !breakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(breakdown)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(primaryTextColor)
                    }
                }
            }

            Text("Helpful: rate how hard it felt to schedule the next review.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(isDarkBackground ? Color.white.opacity(0.7) : .mainBlack.opacity(0.45))
                .padding(.top, 50)

            HStack(spacing: 12) {
                RatingButton(title: "Again", bg: themeStore.accentRed, fg: nil) { onAgain() }
                RatingButton(title: "Hard", bg: themeStore.isMonochrome ? Color("MonoMedium") : Color(red: 1.0, green: 0.902, blue: 0.655), fg: nil) { onHard() }
                RatingButton(title: "Good", bg: themeStore.accentGreen, fg: nil) { onGood() }
                RatingButton(
                    title: "Easy",
                    bg: themeStore.isMonochrome ? Color("MonoLight") : Color(red: 0.718, green: 0.894, blue: 0.780),
                    fg: themeStore.isMonochrome ? nil : Color(red: 0.373, green: 0.561, blue: 0.420)
                ) { onEasy() }
            }
        }
        .padding()
        .frame(maxWidth: 520)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.divider, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func playAudio() {
        guard isPremium || DailyLimitsManager.canPlayTTS else {
            showPremiumWall = true
            return
        }
        if !isPremium {
            DailyLimitsManager.recordTTS()
        }
        Task {
            isPlaying = true
            await AudioManager.shared.play(word: card.word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { isPlaying = false }
        }
    }
}

private extension Color {
    var isDarkColor: Bool {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum < 0.5
    }
}

#Preview {
    let store = WordsStore()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        store.clear()
        store.add(
            StoredWord(
                word: "No puedo creer lo que está pasando aquí",
                type: "adjective",
                translation: "Вкусный",
                example: "Este plato es muy sabroso y delicioso.",
                comment: "Моё любимое слово!",
                tag: "Golden",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "chido",
                type: "adjective",
                translation: "Круто",
                example: "La fiesta estuvo chido y muy divertida.",
                comment: nil,
                tag: "Chat",
                fromLanguage: "es",
                toLanguage: "ru"
            )
        )
        store.add(
            StoredWord(
                word: "食べ物",
                type: "noun",
                translation: "Еда",
                example: "この食べ物はとてもおいしいです。",
                comment: nil,
                tag: "Travel",
                fromLanguage: "ja",
                toLanguage: "ru"
            )
        )
    }
    return PracticeView()
        .environmentObject(store)
        .environmentObject(LanguageStore())
}
