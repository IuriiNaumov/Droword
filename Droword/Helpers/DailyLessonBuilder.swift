import Foundation

struct DailyLessonPlan: Equatable {
    let title: String
    let subtitle: String
    let words: [StoredWord]
    let minutes: Int
    let styleLabel: String
    let topicLabels: [String]
    let canStart: Bool
    let isDone: Bool
    let correct: Int
    let total: Int
    let tomorrowWords: [String]
    let nextReviewCount: Int
    let nextReviewDate: Date?

    var itemCount: Int { words.count }
}

enum DailyLessonBuilder {
    static let minWords = 4
    static let maxWords = 8

    static func plan(
        words: [StoredWord],
        profile: LearningProfileStore,
        learningLanguage: String,
        now: Date = Date()
    ) -> DailyLessonPlan {
        let selected = pickWords(
            from: words,
            profile: profile,
            learningLanguage: learningLanguage,
            now: now
        )
        let dueCount = selected.filter {
            WordDue.isDue(introduced: $0.introduced, dueDate: $0.dueDate, now: now)
        }.count
        let minutes: Int = {
            if selected.count <= 4 { return 3 }
            if selected.count <= 6 { return 4 }
            return 5
        }()
        let topicLabels = profile.topics.isEmpty
            ? []
            : Array(profile.topics.prefix(3).map(\.localizedTitle))

        let snapshot = StudyActivityStore.shared.lastLesson
        let done = StudyActivityStore.shared.isLessonDone(on: now)
        let next = nextReviewInfo(in: words, now: now)

        let eligibleCount = words.filter {
            $0.fromLanguage == learningLanguage
                && $0.translation != nil
                && !($0.translation ?? "").isEmpty
        }.count

        return DailyLessonPlan(
            title: title(
                done: done,
                canStart: selected.count >= minWords,
                dueCount: dueCount,
                eligibleCount: eligibleCount,
                goal: profile.goal
            ),
            subtitle: subtitle(
                done: done,
                canStart: selected.count >= minWords,
                eligibleCount: eligibleCount,
                snapshot: snapshot,
                style: profile.style,
                topics: topicLabels,
                wordCount: selected.count,
                dueCount: dueCount,
                nextReviewCount: next.count,
                nextReviewDate: next.date
            ),
            words: selected,
            minutes: minutes,
            styleLabel: profile.style.localizedTitle,
            topicLabels: topicLabels,
            canStart: selected.count >= minWords,
            isDone: done,
            correct: snapshot?.correct ?? 0,
            total: snapshot?.total ?? 0,
            tomorrowWords: snapshot?.tomorrowWords ?? [],
            nextReviewCount: next.count,
            nextReviewDate: next.date
        )
    }

    static func pickWords(
        from words: [StoredWord],
        profile: LearningProfileStore,
        learningLanguage: String,
        now: Date = Date()
    ) -> [StoredWord] {
        let eligible = words.filter {
            $0.fromLanguage == learningLanguage
                && $0.translation != nil
                && !($0.translation ?? "").isEmpty
                && $0.word.components(separatedBy: .whitespaces).count <= 3
        }

        let preferred = Set(profile.preferredTagNames.map { $0.lowercased() })
        func isTopic(_ word: StoredWord) -> Bool {
            guard !preferred.isEmpty, let tag = word.tag?.lowercased() else { return false }
            return preferred.contains(tag)
        }
        func weakness(_ word: StoredWord) -> Int {
            word.lapses * 3 + max(0, 3 - word.repetitions)
        }

        let due = eligible
            .filter { WordDue.isDue(introduced: $0.introduced, dueDate: $0.dueDate, now: now) }
            .sorted { weakness($0) > weakness($1) }

        let pendingNew = eligible
            .filter { !$0.introduced }
            .sorted { $0.dateAdded < $1.dateAdded }

        let weak = eligible
            .filter { word in
                word.introduced
                    && !due.contains(where: { $0.id == word.id })
                    && (word.lapses > 0 || word.repetitions <= 1)
            }
            .sorted { weakness($0) > weakness($1) }

        let topical = eligible
            .filter { word in
                word.introduced
                    && isTopic(word)
                    && !due.contains(where: { $0.id == word.id })
                    && !weak.contains(where: { $0.id == word.id })
            }
            .sorted { $0.dateAdded > $1.dateAdded }

        let rest = eligible
            .filter { word in
                word.introduced
                    && !due.contains(where: { $0.id == word.id })
                    && !weak.contains(where: { $0.id == word.id })
                    && !topical.contains(where: { $0.id == word.id })
            }
            .sorted { $0.dateAdded > $1.dateAdded }

        var picked: [StoredWord] = []
        func take(_ source: [StoredWord], upTo limit: Int) {
            for word in source where picked.count < limit {
                if !picked.contains(where: { $0.id == word.id }) {
                    picked.append(word)
                }
            }
        }

        let carryoverIDs = Set(StudyActivityStore.shared.lessonCarryoverIDs())
        let carryover = eligible.filter { carryoverIDs.contains($0.id) }
        take(carryover, upTo: maxWords)
        take(due, upTo: maxWords)
        let newSlots = DailyLimitsManager.newWordsRemainingToday
        if newSlots > 0 {
            take(pendingNew, upTo: min(picked.count + newSlots, maxWords))
        }
        take(weak, upTo: maxWords)
        take(topical, upTo: maxWords)
        take(rest, upTo: maxWords)
        return Array(picked.prefix(maxWords))
    }

    private static func title(
        done: Bool,
        canStart: Bool,
        dueCount: Int,
        eligibleCount: Int,
        goal: LearningGoal
    ) -> String {
        if done { return String(localized: "Lesson done") }
        if !canStart {
            return eligibleCount == 0
                ? String(localized: "Start your dictionary")
                : String(localized: "Almost ready")
        }
        if dueCount > 0 { return String(localized: "Today's lesson") }
        return lessonTitle(goal: goal)
    }

    private static func subtitle(
        done: Bool,
        canStart: Bool,
        eligibleCount: Int,
        snapshot: LessonSnapshot?,
        style: LearningStyle,
        topics: [String],
        wordCount: Int,
        dueCount: Int,
        nextReviewCount: Int,
        nextReviewDate: Date?
    ) -> String {
        if done {
            return doneSubtitle(
                snapshot: snapshot,
                nextReviewCount: nextReviewCount,
                nextReviewDate: nextReviewDate
            )
        }
        if !canStart {
            let need = max(0, minWords - eligibleCount)
            if eligibleCount == 0 {
                return String(localized: "Add a few words — then your first lesson unlocks here.")
            }
            return String(localized: "Add \(need) more words to unlock today's lesson.")
        }
        return lessonSubtitle(
            style: style,
            topics: topics,
            wordCount: wordCount,
            dueCount: dueCount
        )
    }

    private static func lessonTitle(goal: LearningGoal) -> String {
        switch goal {
        case .dailyChat: return String(localized: "Today's lesson")
        case .travel: return String(localized: "Travel day")
        case .work: return String(localized: "Work vocab run")
        case .exam: return String(localized: "Exam drill")
        case .school: return String(localized: "Class boost")
        case .fun: return String(localized: "Fun round")
        }
    }

    private static func lessonSubtitle(
        style: LearningStyle,
        topics: [String],
        wordCount: Int,
        dueCount: Int
    ) -> String {
        var parts: [String] = []
        if wordCount > 0 {
            parts.append(String(localized: "\(wordCount) words"))
        }
        if dueCount > 0 {
            parts.append(String(localized: "\(dueCount) due"))
        }
        parts.append(style.localizedTitle)
        if !topics.isEmpty {
            parts.append(topics.joined(separator: " · "))
        }
        return parts.joined(separator: " · ")
    }

    private static func doneSubtitle(
        snapshot: LessonSnapshot?,
        nextReviewCount: Int,
        nextReviewDate: Date?
    ) -> String {
        var parts: [String] = []
        if let snapshot, snapshot.total > 0 {
            parts.append(String(localized: "\(snapshot.correct)/\(snapshot.total) today"))
        }
        if let date = nextReviewDate, nextReviewCount > 0 {
            parts.append(String(localized: "Next review in \(timeUntil(date))"))
        } else if let snapshot, !snapshot.tomorrowWords.isEmpty {
            let preview = snapshot.tomorrowWords.prefix(3).map(\.displayCapitalized).joined(separator: ", ")
            parts.append(String(localized: "Tomorrow: \(preview)"))
        }
        return parts.joined(separator: " · ")
    }

    static func nextReviewInfo(in words: [StoredWord], now: Date = Date()) -> (count: Int, date: Date?) {
        let upcoming = words.compactMap { w -> Date? in
            guard WordDue.isUpcoming(introduced: w.introduced, dueDate: w.dueDate, now: now) else { return nil }
            return w.dueDate
        }.sorted()
        guard let earliest = upcoming.first else { return (0, nil) }
        let windowEnd = earliest.addingTimeInterval(3600)
        let count = upcoming.filter { $0 <= windowEnd }.count
        return (count, earliest)
    }

    private static func timeUntil(_ date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(Date()))
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return String(localized: "\(max(1, minutes)) min")
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(localized: "\(hours) h")
        }
        let days = hours / 24
        return String(localized: "\(days) d")
    }
}
