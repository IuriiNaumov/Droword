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
        return DailyLessonPlan(
            title: done ? String(localized: "See you tomorrow") : lessonTitle(goal: profile.goal),
            subtitle: done
                ? doneSubtitle(snapshot: snapshot)
                : lessonSubtitle(
                    style: profile.style,
                    topics: topicLabels,
                    wordCount: selected.count,
                    dueCount: dueCount
                ),
            words: selected,
            minutes: minutes,
            styleLabel: profile.style.localizedTitle,
            topicLabels: topicLabels,
            canStart: selected.count >= minWords,
            isDone: done,
            correct: snapshot?.correct ?? 0,
            total: snapshot?.total ?? 0,
            tomorrowWords: snapshot?.tomorrowWords ?? []
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

        let weak = eligible
            .filter { word in
                !due.contains(where: { $0.id == word.id })
                    && (word.lapses > 0 || word.repetitions <= 1)
            }
            .sorted { weakness($0) > weakness($1) }

        let topical = eligible
            .filter { word in
                isTopic(word)
                    && !due.contains(where: { $0.id == word.id })
                    && !weak.contains(where: { $0.id == word.id })
            }
            .sorted { $0.dateAdded > $1.dateAdded }

        let rest = eligible
            .filter { word in
                !due.contains(where: { $0.id == word.id })
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
        take(due, upTo: min(4, maxWords))
        take(weak, upTo: maxWords)
        take(topical, upTo: maxWords)
        take(rest, upTo: maxWords)
        return Array(picked.prefix(maxWords))
    }

    private static func lessonTitle(goal: LearningGoal) -> String {
        switch goal {
        case .dailyChat: return String(localized: "Today's chat pack")
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
        parts.append(style.localizedTitle)
        if !topics.isEmpty {
            parts.append(topics.joined(separator: " · "))
        }
        if dueCount > 0 {
            parts.append(String(localized: "\(dueCount) due"))
        }
        return parts.joined(separator: " · ")
    }

    private static func doneSubtitle(snapshot: LessonSnapshot?) -> String {
        guard let snapshot, snapshot.total > 0 else {
            return String(localized: "Lesson closed. Come back tomorrow.")
        }
        var parts = [String(localized: "\(snapshot.correct)/\(snapshot.total) today")]
        if !snapshot.tomorrowWords.isEmpty {
            let preview = snapshot.tomorrowWords.prefix(3).joined(separator: ", ")
            parts.append(String(localized: "Tomorrow: \(preview)"))
        }
        return parts.joined(separator: " · ")
    }
}
