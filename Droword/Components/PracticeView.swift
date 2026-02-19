import SwiftUI
import AVFoundation

struct WordCard: Identifiable {
    let id = UUID()
    let word: String
    let partOfSpeech: String
    let example: String
    let translation: String
    let transcription: String?    // Added transcription property
    let tag: String?
    let fromLanguage: String?
    let toLanguage: String?
    let comment: String?
}

struct PracticeView: View {
    @EnvironmentObject private var store: WordsStore

    @State private var currentIndex: Int = 0
    @State private var easeFactors: [UUID: Double] = [:]
    @State private var intervals: [UUID: Int] = [:]
    @State private var repetitions: [UUID: Int] = [:]
    @State private var lastIntervalDays: [UUID: Int] = [:]
    @State private var learningQueue: [WordCard] = []
    @State private var showCompletion = false

    private var cards: [WordCard] {
        store.words.map { word in
            WordCard(
                word: word.word,
                partOfSpeech: word.type.isEmpty ? "word" : word.type,
                example: word.example ?? "Add an example later",
                translation: word.translation ?? "No translation yet",
                transcription: word.transcription, // Added transcription here
                tag: word.tag,
                fromLanguage: word.fromLanguage,
                toLanguage: word.toLanguage,
                comment: word.comment
            )
        }
    }

    private func prepareSession() {
        learningQueue = cards
        currentIndex = 0
        showCompletion = false
        for c in learningQueue {
            if easeFactors[c.id] == nil { easeFactors[c.id] = 2.5 }
            if intervals[c.id] == nil { intervals[c.id] = 0 }
            if repetitions[c.id] == nil { repetitions[c.id] = 0 }
            if lastIntervalDays[c.id] == nil { lastIntervalDays[c.id] = 0 }
        }
    }

    private enum Rating { case again, hard, good, easy }

    private func scheduleNext(for card: WordCard, rating: Rating) {
        var ef = easeFactors[card.id] ?? 2.5
        var reps = repetitions[card.id] ?? 0
        var ivl = intervals[card.id] ?? 0

        let q: Double
        switch rating {
        case .again: q = 1
        case .hard:  q = 3
        case .good:  q = 4
        case .easy:  q = 5
        }

        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = max(1.3, ef)

        if q < 3 {
            reps = 0
            ivl = 0
            reinsert(card, after: 2)
        } else {
            reps += 1
            if reps == 1 {
                ivl = 1
            } else if reps == 2 {
                ivl = 6
            } else {
                ivl = Int(round(Double(ivl) * ef))
                ivl = max(1, ivl)
            }
        }

        easeFactors[card.id] = ef
        repetitions[card.id] = reps
        intervals[card.id] = ivl
        lastIntervalDays[card.id] = ivl

        showNextCard()
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

            if learningQueue.isEmpty {
                emptyState
            } else {
                VStack(spacing: 24) {
                    header
                    Spacer()

                    ZStack {
                        if currentIndex < learningQueue.count && !showCompletion {
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
                        } else {
                            completionScreen
                        }
                    }

                    Spacer()
                }
            }
        }
        .onAppear {
            prepareSession()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Review")
                .font(.custom("Poppins-Bold", size: 38))

            Text("No words to practice yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)

            Text("Add some words to your dictionary and they will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Review")
                .font(.custom("Poppins-Bold", size: 38))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var completionScreen: some View {
        VStack(spacing: 12) {
            Text("Session complete ✨")
                .font(.title2.bold())
            Text("You’ve reviewed all scheduled words for now.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func showNextCard() {
        currentIndex += 1
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
                .background(bg)
                .foregroundColor(textColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct WordCardPracticeView: View {
    let card: WordCard

    let onAgain: () -> Void
    let onHard: () -> Void
    let onGood: () -> Void
    let onEasy: () -> Void

    @State private var isPlaying = false
    @State private var showTranslation = false

    private var backgroundColor: Color {
        if let tag = card.tag {
            switch tag {
            case "Chat":   return Color(.accentBlue)
            case "Travel": return Color(.accentGreen)
            case "Street": return Color(.accentPink)
            case "Movies": return Color(.accentPurple)
            case "Golden": return Color(.accentGold)
            default:
                if let custom = TagStore.shared.tags.first(where: { $0.name.caseInsensitiveCompare(tag) == .orderedSame }),
                   let color = Color(fromHexString: custom.colorHex) {
                    return color
                }
            }
        }
        return Color(.defaultCard)
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tag = card.tag, !tag.isEmpty {
                Text(tag)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(darkerShade(of: backgroundColor, by: 0.4))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(darkerShade(of: backgroundColor, by: 0.1), lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                    )
                    .padding(.bottom, 2)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.word)
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.mainBlack)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    if let tr = card.transcription, !tr.isEmpty {
                        Text(tr)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.mainGrey)
                    }
                }
                Spacer()
                Button(action: { Haptics.selection(); playAudio() }) {
                    SoundWavesView(isPlaying: isPlaying)
                        .frame(width: 24, height: 24)
                        .tint(.black)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }

            Text(card.partOfSpeech.capitalized)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.mainGrey)

            if let comment = card.comment, !comment.isEmpty {
                Text(comment)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.mainBlack.opacity(0.8))
                    .padding(.horizontal, 2)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(highlightedExample(example: card.example, target: card.word))
                        .font(.custom("Poppins-Regular", size: 16))
                }

                if !card.translation.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        if showTranslation {
                            Text(card.translation)
                                .font(.custom("Poppins-Regular", size: 16))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            let first = card.translation.prefix(1)
                            Text("\(first)•••")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.mainBlack.opacity(0.5))
                        }
                        Spacer()
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showTranslation.toggle() } }) {
                            Text(showTranslation ? "Hide" : "Show")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.mainBlack.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Try to recall the translation without looking.")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.mainBlack.opacity(0.45))
                }
            }

            Text("Helpful: rate how hard it felt to schedule the next review.")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.mainBlack.opacity(0.45))
                .padding(.top, 50)

            HStack(spacing: 12) {
                RatingButton(title: "Again", bg: Color.iDontKnowButton, fg: nil) { onAgain() }
                RatingButton(title: "Hard", bg: Color(red: 1.0, green: 0.902, blue: 0.655), fg: nil) { onHard() }
                RatingButton(title: "Good", bg: Color.iKnowButton, fg: nil) { onGood() }
                RatingButton(
                    title: "Easy",
                    bg: Color(red: 0.718, green: 0.894, blue: 0.780),
                    fg: Color(red: 0.373, green: 0.561, blue: 0.420)
                ) { onEasy() }
            }
        }
        .padding()
        .frame(maxWidth: 520)
        .background(backgroundColor)
        .cornerRadius(16)
    }

    private func playAudio() {
        Task {
            isPlaying = true
            await AudioManager.shared.play(word: card.word)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { isPlaying = false }
        }
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
}

