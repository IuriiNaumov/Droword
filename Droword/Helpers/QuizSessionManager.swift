import SwiftUI
import Combine

final class QuizSessionManager: ObservableObject {

    enum ExerciseType: String, CaseIterable, Codable {
        case multipleChoice
        case typing
        case cloze
        case matching
        case sentenceBuilding
        case listening
        case speaking
    }

    struct QuizItem: Identifiable, Codable {
        let id: UUID
        let word: String
        let translation: String
        let transcription: String?
        let tag: String?
        let example: String?
    }

    struct MatchingPair: Identifiable, Equatable {
        let id: UUID
        let word: String
        let translation: String

        init(id: UUID = UUID(), word: String, translation: String) {
            self.id = id
            self.word = word
            self.translation = translation
        }
    }

    @Published var queue: [QuizItem] = []
    @Published var currentIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var isComplete: Bool = false
    @Published var exerciseTypes: [UUID: ExerciseType] = [:]
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var answerResults: [UUID: Bool] = [:]
    @Published var orderedResults: [Bool] = []
    @Published var directionMap: [UUID: Bool] = [:]
    @Published var answeredCount: Int = 0

    var maxSessionSize = 10

    @Published var originalTotal: Int = 0

    var currentItem: QuizItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var currentExerciseType: ExerciseType? {
        guard let item = currentItem else { return nil }
        return exerciseTypes[item.id]
    }

    var total: Int { queue.count }

    func prepareMixedSession(
        from words: [StoredWord],
        filterTag: String? = nil,
        learningStyle: LearningStyle = .mixed,
        preferredTopics: [String] = []
    ) {
        var filtered = words
            .filter { $0.translation != nil && !$0.translation!.isEmpty }
            .filter { $0.word.components(separatedBy: .whitespaces).count <= 3 }

        if let tag = filterTag, !tag.isEmpty {
            filtered = filtered.filter { $0.tag == tag }
        }

        let preferred = Set(preferredTopics.map { $0.lowercased() })
        func topicBoost(_ word: StoredWord) -> Bool {
            guard !preferred.isEmpty, let tag = word.tag?.lowercased() else { return false }
            return preferred.contains(tag)
        }

        let today = Calendar.current.startOfDay(for: Date())
        let dueAll = filtered.filter { w in
            if let d = w.dueDate { return d <= today } else { return true }
        }
        var due = dueAll.filter(topicBoost).shuffled() + dueAll.filter { !topicBoost($0) }.shuffled()

        let notDueAll = filtered.filter { w in
            if let d = w.dueDate { return d > today } else { return false }
        }
        let notDue = notDueAll.filter(topicBoost).shuffled() + notDueAll.filter { !topicBoost($0) }.shuffled()

        if due.count < maxSessionSize {
            due.append(contentsOf: notDue.prefix(maxSessionSize - due.count))
        }

        let selected = Array(due.prefix(maxSessionSize))

        let items = selected.map { w in
            QuizItem(
                id: w.id,
                word: w.word,
                translation: w.translation ?? "",
                transcription: w.transcription,
                tag: w.tag,
                example: w.example
            )
        }

        let wordReps: [UUID: Int] = Dictionary(
            uniqueKeysWithValues: selected.map { ($0.id, $0.repetitions) }
        )

        queue = items.shuffled()
        currentIndex = 0
        correctCount = 0
        answeredCount = 0
        isComplete = false
        currentStreak = 0
        bestStreak = 0
        answerResults = [:]
        orderedResults = []
        originalTotal = queue.count

        exerciseTypes = [:]

        let matchingCandidateIndex: Int? = queue.count >= 4 ? Int.random(in: 0..<queue.count) : nil

        for (index, item) in queue.enumerated() {
            if index == matchingCandidateIndex {
                exerciseTypes[item.id] = .matching
                continue
            }

            let reps = wordReps[item.id] ?? 0
            let isClozeEligible = item.example != nil
                && !item.example!.isEmpty
                && ClozeMatcher.find(word: item.word, in: item.example!) != nil
            let isSentenceBuildingEligible = Self.isSentenceBuildingEligible(example: item.example)

            exerciseTypes[item.id] = pickExerciseType(
                reps: reps,
                isClozeEligible: isClozeEligible,
                isSentenceBuildingEligible: isSentenceBuildingEligible,
                style: learningStyle
            )
        }

        let swappable = queue.indices.filter { exerciseTypes[queue[$0].id] != .matching }.shuffled()
        if NetworkMonitor.shared.isConnected, queue.count >= 4, let idx = swappable.first {
            if learningStyle == .listening || learningStyle == .speaking || learningStyle == .mixed {
                exerciseTypes[queue[idx].id] = .listening
            }
        }

        if learningStyle == .listening, NetworkMonitor.shared.isConnected {
            let more = queue.indices.filter {
                let t = exerciseTypes[queue[$0].id]
                return t == .multipleChoice || t == .typing
            }.shuffled()
            if let idx = more.first {
                exerciseTypes[queue[idx].id] = .listening
            }
        }

        let directionExcluded: Set<ExerciseType> = [.cloze, .listening, .sentenceBuilding]
        let nonCloze = queue.filter { !directionExcluded.contains(exerciseTypes[$0.id] ?? .multipleChoice) }
        let reverseRatio: Double = {
            switch learningStyle {
            case .speaking: return 0.7
            case .writing: return 0.55
            case .listening, .reading: return 0.35
            case .mixed: return 0.5
            }
        }()
        let halfReversed = Int((Double(nonCloze.count) * reverseRatio).rounded())
        var reversedFlags = Array(repeating: true, count: halfReversed)
            + Array(repeating: false, count: max(0, nonCloze.count - halfReversed))
        reversedFlags.shuffle()
        directionMap = [:]
        for (i, item) in nonCloze.enumerated() {
            directionMap[item.id] = reversedFlags[i]
        }
    }

    func prepareLessonSession(
        from words: [StoredWord],
        learningStyle: LearningStyle = .mixed
    ) {
        let selected = Array(words.prefix(maxSessionSize))
        let items = selected.map { w in
            QuizItem(
                id: w.id,
                word: w.word,
                translation: w.translation ?? "",
                transcription: w.transcription,
                tag: w.tag,
                example: w.example
            )
        }
        let wordReps: [UUID: Int] = Dictionary(
            uniqueKeysWithValues: selected.map { ($0.id, $0.repetitions) }
        )

        queue = items
        currentIndex = 0
        correctCount = 0
        answeredCount = 0
        isComplete = false
        currentStreak = 0
        bestStreak = 0
        answerResults = [:]
        orderedResults = []
        originalTotal = queue.count
        exerciseTypes = [:]
        directionMap = [:]

        for (index, item) in queue.enumerated() {
            let reps = wordReps[item.id] ?? 0
            let isClozeEligible = item.example != nil
                && !item.example!.isEmpty
                && ClozeMatcher.find(word: item.word, in: item.example!) != nil
            let isSentenceBuildingEligible = Self.isSentenceBuildingEligible(example: item.example)

            if index == 0 || reps == 0 {
                exerciseTypes[item.id] = .multipleChoice
            } else {
                exerciseTypes[item.id] = pickExerciseType(
                    reps: reps,
                    isClozeEligible: isClozeEligible,
                    isSentenceBuildingEligible: isSentenceBuildingEligible,
                    style: learningStyle
                )
            }
        }

        if queue.count >= 4 {
            let matchIndex = min(queue.count - 1, max(2, queue.count / 2))
            let matchItem = queue[matchIndex]
            if (wordReps[matchItem.id] ?? 0) >= 1 {
                exerciseTypes[matchItem.id] = .matching
            }
        }

        let swappable = queue.indices.filter {
            let type = exerciseTypes[queue[$0].id]
            return type != .matching && $0 > 0
        }.shuffled()
        if NetworkMonitor.shared.isConnected, !swappable.isEmpty {
            if learningStyle == .listening || learningStyle == .speaking || learningStyle == .mixed {
                exerciseTypes[queue[swappable[0]].id] = .listening
            }
        }

        let directionExcluded: Set<ExerciseType> = [.cloze, .listening, .sentenceBuilding]
        let nonCloze = queue.filter { !directionExcluded.contains(exerciseTypes[$0.id] ?? .multipleChoice) }
        let reverseRatio: Double = {
            switch learningStyle {
            case .speaking: return 0.55
            case .writing: return 0.45
            case .listening, .reading: return 0.3
            case .mixed: return 0.4
            }
        }()
        let reversedCount = Int((Double(nonCloze.count) * reverseRatio).rounded())
        var reversedFlags = Array(repeating: true, count: reversedCount)
            + Array(repeating: false, count: max(0, nonCloze.count - reversedCount))
        reversedFlags.shuffle()
        for (i, item) in nonCloze.enumerated() {
            directionMap[item.id] = reversedFlags[i]
        }
    }

    private static func isSentenceBuildingEligible(example: String?) -> Bool {
        guard let example, !example.isEmpty else { return false }
        let words = example
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count >= 4
    }

    static func sentenceTokens(from example: String) -> [String] {
        example
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    func sentenceDistractors(
        correctTokens: [String],
        from allWords: [StoredWord],
        count: Int = 3
    ) -> [String] {
        let correctKeys = Set(correctTokens.map { QuizAnswerMatching.normalize($0) })
        var seen = correctKeys
        var pool: [String] = []

        for word in allWords.shuffled() {
            let sources: [String] = {
                var list: [String] = []
                if let example = word.example, !example.isEmpty { list.append(example) }
                list.append(contentsOf: word.examples)
                list.append(word.word)
                return list
            }()

            for source in sources {
                for token in Self.sentenceTokens(from: source) {
                    let key = QuizAnswerMatching.normalize(token)
                    guard !key.isEmpty, seen.insert(key).inserted else { continue }
                    pool.append(token)
                    if pool.count >= count * 4 { break }
                }
                if pool.count >= count * 4 { break }
            }
            if pool.count >= count * 4 { break }
        }

        return Array(pool.shuffled().prefix(count))
    }

    private func pickExerciseType(
        reps: Int,
        isClozeEligible: Bool,
        isSentenceBuildingEligible: Bool = false,
        style: LearningStyle
    ) -> ExerciseType {
        switch style {
        case .listening:
            if reps == 0 { return .multipleChoice }
            return Bool.random() ? .multipleChoice : .matching
        case .reading:
            if reps <= 1 { return .multipleChoice }
            if isClozeEligible { return Bool.random() ? .cloze : .multipleChoice }
            return .multipleChoice
        case .writing:
            if reps == 0 { return Bool.random() ? .multipleChoice : .typing }
            if isClozeEligible { return Bool.random() ? .typing : .cloze }
            return .typing
        case .speaking:
            if reps <= 1 { return .multipleChoice }
            return Bool.random() ? .typing : .multipleChoice
        case .mixed:
            switch reps {
            case 0:
                return .multipleChoice
            case 1:
                return Bool.random() ? .multipleChoice : .typing
            case 2...3:
                if isSentenceBuildingEligible && Bool.random() {
                    return .sentenceBuilding
                }
                if isClozeEligible {
                    return Bool.random() ? .typing : .cloze
                }
                return .typing
            default:
                if isSentenceBuildingEligible && Int.random(in: 0..<10) < 3 {
                    return .sentenceBuilding
                }
                if isClozeEligible {
                    return Int.random(in: 0..<10) < 7 ? .cloze : .typing
                }
                return .typing
            }
        }
    }

    func matchingPairs(for item: QuizItem) -> [MatchingPair] {
        var pairs: [MatchingPair] = [MatchingPair(word: item.word, translation: item.translation)]
        var usedWords = Set([item.word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)])
        var usedTranslations = Set([item.translation.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)])

        let others = queue.filter { $0.id != item.id }.shuffled()

        for other in others {
            let wordKey = other.word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            let translationKey = other.translation.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if usedWords.contains(wordKey) || usedTranslations.contains(translationKey) { continue }
            usedWords.insert(wordKey)
            usedTranslations.insert(translationKey)
            pairs.append(MatchingPair(word: other.word, translation: other.translation))
            if pairs.count == 4 { break }
        }

        if pairs.count < 4 {
            for other in others {
                let wordKey = other.word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                if usedWords.contains(wordKey) { continue }
                usedWords.insert(wordKey)
                pairs.append(MatchingPair(word: other.word, translation: other.translation))
                if pairs.count == 4 { break }
            }
        }

        return pairs.shuffled()
    }

    func distractors(for item: QuizItem, from allWords: [StoredWord], reversed: Bool = false) -> [String] {
        let correctAnswer: String
        let pool: [String]

        if reversed {
            correctAnswer = item.word.lowercased()
            pool = allWords
                .map { $0.word }
                .filter { !$0.isEmpty && $0.lowercased() != correctAnswer }
        } else {
            correctAnswer = item.translation.lowercased()
            pool = allWords
                .compactMap { $0.translation }
                .filter { !$0.isEmpty && $0.lowercased() != correctAnswer }
        }

        var seen = Set<String>()
        var unique: [String] = []
        for item in pool.shuffled() {
            let key = item.lowercased()
            if seen.insert(key).inserted {
                unique.append(item)
            }
        }
        return Array(unique.prefix(3))
    }

    func recordAnswer(correct: Bool) {
        if correct {
            correctCount += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        if let item = currentItem {
            answerResults[item.id] = correct
        }
    }

    func advance() {
        if let item = currentItem, let result = answerResults[item.id] {
            answeredCount += 1
            orderedResults.append(result)
        }
        if currentIndex + 1 >= queue.count {
            isComplete = true
        } else {
            currentIndex += 1
        }
    }

    private static let savedSessionKey = "savedQuizSession"

    private struct SessionSnapshot: Codable {
        let queue: [QuizItem]
        let currentIndex: Int
        let correctCount: Int
        let currentStreak: Int
        let bestStreak: Int
        let answeredCount: Int
        let answerResults: [String: Bool]
        let exerciseTypes: [String: String]
        let directionMap: [String: Bool]
        let orderedResults: [Bool]
        var originalTotal: Int?
    }

    func saveSession() {
        let snapshot = SessionSnapshot(
            queue: queue,
            currentIndex: currentIndex,
            correctCount: correctCount,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            answeredCount: answeredCount,
            answerResults: Dictionary(uniqueKeysWithValues: answerResults.map { ($0.key.uuidString, $0.value) }),
            exerciseTypes: Dictionary(uniqueKeysWithValues: exerciseTypes.map { ($0.key.uuidString, $0.value.rawValue) }),
            directionMap: Dictionary(uniqueKeysWithValues: directionMap.map { ($0.key.uuidString, $0.value) }),
            orderedResults: orderedResults,
            originalTotal: originalTotal
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.savedSessionKey)
        }
    }

    func restoreSession() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.savedSessionKey),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data),
              !snapshot.queue.isEmpty,
              snapshot.currentIndex < snapshot.queue.count else {
            return false
        }

        queue = snapshot.queue
        currentIndex = snapshot.currentIndex
        correctCount = snapshot.correctCount
        currentStreak = snapshot.currentStreak
        bestStreak = snapshot.bestStreak
        answeredCount = snapshot.answeredCount
        isComplete = false
        answerResults = Dictionary(uniqueKeysWithValues: snapshot.answerResults.compactMap { key, val in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, val)
        })
        exerciseTypes = Dictionary(uniqueKeysWithValues: snapshot.exerciseTypes.compactMap { key, val in
            guard let uuid = UUID(uuidString: key),
                  let type = ExerciseType(rawValue: val) else { return nil }
            return (uuid, type)
        })
        directionMap = Dictionary(uniqueKeysWithValues: snapshot.directionMap.compactMap { key, val in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, val)
        })
        orderedResults = snapshot.orderedResults
        originalTotal = snapshot.originalTotal ?? snapshot.queue.count
        return true
    }

    func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: Self.savedSessionKey)
    }

    var hasSavedSession: Bool {
        UserDefaults.standard.data(forKey: Self.savedSessionKey) != nil
    }

    static func applyScheduling(
        for wordID: UUID,
        correct: Bool,
        isAlmostCorrect: Bool = false,
        strong: Bool = false,
        store: WordsStore,
        languageStore: LanguageStore
    ) {
        guard let w = store.words.first(where: { $0.id == wordID }) else { return }

        languageStore.recordLearningSample(
            SRSScheduler.quizLearningSample(correct: correct, almostCorrect: isAlmostCorrect)
        )

        let result = SRSScheduler.scheduleQuiz(
            state: SchedulingState(
                easeFactor: w.easeFactor,
                intervalDays: w.intervalDays,
                repetitions: w.repetitions,
                lapses: w.lapses
            ),
            correct: correct,
            almostCorrect: isAlmostCorrect,
            strong: strong
        )

        store.updateScheduling(
            for: wordID,
            easeFactor: result.state.easeFactor,
            intervalDays: result.state.intervalDays,
            repetitions: result.state.repetitions,
            lapses: result.state.lapses,
            dueDate: result.dueDate
        )
    }
}

enum ClozeMatcher {

    static func find(word: String, in example: String) -> (range: Range<String.Index>, form: String)? {
        let target = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return nil }

        if let r = example.range(of: target, options: [.caseInsensitive, .diacriticInsensitive]) {
            return (r, String(example[r]))
        }

        let fWord = target.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        guard fWord.count >= 4 else { return nil }

        for token in tokens(in: example) {
            let fTok = token.text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            guard fTok.count >= 4 else { continue }
            let shorter = Double(min(fTok.count, fWord.count))
            let longer = Double(max(fTok.count, fWord.count))
            guard shorter / longer >= 0.8 else { continue }
            if fTok.hasPrefix(fWord) || fWord.hasPrefix(fTok) {
                return (token.range, token.text)
            }
        }
        return nil
    }

    private static func tokens(in s: String) -> [(range: Range<String.Index>, text: String)] {
        var result: [(Range<String.Index>, String)] = []
        var i = s.startIndex
        while i < s.endIndex {
            if s[i].isLetter {
                let start = i
                var j = i
                while j < s.endIndex && s[j].isLetter { j = s.index(after: j) }
                result.append((start..<j, String(s[start..<j])))
                i = j
            } else {
                i = s.index(after: i)
            }
        }
        return result
    }
}
