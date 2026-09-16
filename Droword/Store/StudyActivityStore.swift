import Foundation
import Combine
import WidgetKit

struct StudyMoment: Codable, Equatable, Identifiable {
    var id: String { word + translation }
    let word: String
    let translation: String
    let landed: Bool
}

struct LessonSnapshot: Codable, Equatable {
    let day: String
    let correct: Int
    let total: Int
    let tomorrowWords: [String]
}

final class StudyActivityStore: ObservableObject {
    static let shared = StudyActivityStore()

    @Published private(set) var dayKeys: Set<String> = []
    @Published private(set) var lastMoments: [StudyMoment] = []
    @Published private(set) var lastLesson: LessonSnapshot?

    private let daysKey = "studyActivity.days"
    private let migratedKey = "studyActivity.migratedFromAdds"
    private let answersKey = "studyActivity.lastAnswers"
    private let momentsKey = "studyActivity.lastMoments"
    private let carryoverKey = "studyActivity.lessonCarryover"
    private let lessonKey = "studyActivity.lastLesson"

    private var lastAnswers: [String: Bool] = [:]

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: daysKey) ?? []
        dayKeys = Set(stored)
        if let data = UserDefaults.standard.data(forKey: answersKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            lastAnswers = decoded
        }
        if let data = UserDefaults.standard.data(forKey: momentsKey),
           let decoded = try? JSONDecoder().decode([StudyMoment].self, from: data) {
            lastMoments = decoded
        }
        if let data = UserDefaults.standard.data(forKey: lessonKey),
           let decoded = try? JSONDecoder().decode(LessonSnapshot.self, from: data) {
            lastLesson = decoded
        }
    }

    func ensureMigrated(from words: [StoredWord]) {
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }
        let cal = Calendar.current
        let keys = Set(words.map { DateFormatting.dayFormatter.string(from: cal.startOfDay(for: $0.dateAdded)) })
        dayKeys.formUnion(keys)
        persistDays()
        UserDefaults.standard.set(true, forKey: migratedKey)
    }

    func recordStudy(seedingFrom words: [StoredWord] = []) {
        if !words.isEmpty {
            ensureMigrated(from: words)
        }
        let today = DateFormatting.todayString
        if !dayKeys.contains(today) {
            dayKeys.insert(today)
            persistDays()
        }
    }

    func activityDates() -> Set<Date> {
        Set(dayKeys.compactMap { DateFormatting.dayFormatter.date(from: $0) })
    }

    func studied(on date: Date) -> Bool {
        dayKeys.contains(DateFormatting.dayFormatter.string(from: Calendar.current.startOfDay(for: date)))
    }

    @discardableResult
    func captureSession(
        results: [(id: UUID, word: String, translation: String, correct: Bool)],
        seedingFrom words: [StoredWord]
    ) -> [StudyMoment] {
        recordStudy(seedingFrom: words)
        var landed: [StudyMoment] = []
        var missed: [StudyMoment] = []
        for item in results {
            let key = item.id.uuidString
            let previous = lastAnswers[key]
            lastAnswers[key] = item.correct
            if item.correct, previous == false {
                landed.append(StudyMoment(word: item.word, translation: item.translation, landed: true))
            } else if !item.correct {
                missed.append(StudyMoment(word: item.word, translation: item.translation, landed: false))
            }
        }
        lastMoments = Array(landed.prefix(3))
        if lastMoments.isEmpty {
            lastMoments = Array(missed.prefix(2))
        }
        persistAnswers()
        persistMoments()
        return lastMoments
    }

    func isLessonDone(on date: Date = Date()) -> Bool {
        lastLesson?.day == DateFormatting.dayFormatter.string(from: date)
    }

    func markLessonComplete(correct: Int, total: Int, missedWords: [String], seedingFrom words: [StoredWord]) {
        recordStudy(seedingFrom: words)
        lastLesson = LessonSnapshot(
            day: DateFormatting.todayString,
            correct: correct,
            total: total,
            tomorrowWords: missedWords
        )
        if let data = try? JSONEncoder().encode(lastLesson) {
            UserDefaults.standard.set(data, forKey: lessonKey)
        }
        writeToAppGroup()
    }

    func writeToAppGroup() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(lastLesson?.day, forKey: "widget.lessonDay")
        defaults.set(lastLesson?.correct ?? 0, forKey: "widget.lessonCorrect")
        defaults.set(lastLesson?.total ?? 0, forKey: "widget.lessonTotal")
        defaults.set(lastLesson?.tomorrowWords ?? [], forKey: "widget.lessonTomorrow")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func rememberLessonMisses(_ ids: [UUID]) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: carryoverKey)
    }

    func lessonCarryoverIDs() -> [UUID] {
        let raw = UserDefaults.standard.stringArray(forKey: carryoverKey) ?? []
        return raw.compactMap(UUID.init(uuidString:))
    }

    private func persistDays() {
        UserDefaults.standard.set(Array(dayKeys), forKey: daysKey)
    }

    private func persistAnswers() {
        if let data = try? JSONEncoder().encode(lastAnswers) {
            UserDefaults.standard.set(data, forKey: answersKey)
        }
    }

    private func persistMoments() {
        if let data = try? JSONEncoder().encode(lastMoments) {
            UserDefaults.standard.set(data, forKey: momentsKey)
        }
    }
}
