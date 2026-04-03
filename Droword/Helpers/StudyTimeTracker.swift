import Foundation
import Combine

@MainActor
final class StudyTimeTracker: ObservableObject {
    static let shared = StudyTimeTracker()

    @Published private(set) var todaySeconds: Int = 0
    @Published private(set) var weekSeconds: Int = 0

    private let sessionsKey = "StudyTimeTracker.sessions"
    private var sessionStart: Date?
    private var tickTimer: Timer?
    private var cachedSessions: [Session]?

    private struct Session: Codable {
        let date: Date
        let seconds: Int
    }

    private init() {
        cachedSessions = loadSessionsFromDisk()
        recalculate()
    }

    func startSession() {
        guard sessionStart == nil else { return }
        sessionStart = Date()

        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recalculate()
            }
        }
    }

    func endSession() {
        guard let start = sessionStart else { return }
        tickTimer?.invalidate()
        tickTimer = nil

        let elapsed = Int(Date().timeIntervalSince(start))
        guard elapsed >= 5 else {
            sessionStart = nil
            return
        }
        saveSession(seconds: elapsed)
        sessionStart = nil
        recalculate()
    }

    func pauseSession() {
        endSession()
    }

    func resumeSession() {
        startSession()
        recalculate()
    }

    var todayFormatted: String {
        let active = activeSeconds()
        return Self.format(seconds: todaySeconds + active)
    }

    var weekFormatted: String {
        let active = activeSeconds()
        return Self.format(seconds: weekSeconds + active)
    }

    static func format(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(localized: "\(hours)h \(minutes)m", comment: "Study time format: hours and minutes")
        }
        return String(localized: "\(max(minutes, 0))m", comment: "Study time format: minutes only")
    }


    func minutesPerDay(last days: Int) -> [(date: Date, minutes: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let sessions = loadSessions()

        let grouped = Dictionary(grouping: sessions) {
            cal.startOfDay(for: $0.date)
        }

        return (0..<days).reversed().compactMap { daysAgo in
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let total = grouped[date]?.reduce(0) { $0 + $1.seconds } ?? 0
            return (date: date, minutes: total / 60)
        }
    }

    func minutesForDateRange(from startDate: Date, to endDate: Date) -> [Date: Int] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        let sessions = loadSessions()

        let filtered = sessions.filter {
            let day = cal.startOfDay(for: $0.date)
            return day >= start && day <= end
        }

        var result: [Date: Int] = [:]
        for session in filtered {
            let day = cal.startOfDay(for: session.date)
            result[day, default: 0] += session.seconds / 60
        }
        return result
    }

    var totalAllTimeMinutes: Int {
        loadSessions().reduce(0) { $0 + $1.seconds } / 60
    }

    var averageDailyMinutes: Int {
        let sessions = loadSessions()
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
        let totalSecs = sessions.reduce(0) { $0 + $1.seconds }
        return totalSecs / max(1, days.count) / 60
    }

    private func activeSeconds() -> Int {
        guard let start = sessionStart else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }

    private func recalculate() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let sessions = loadSessions()

        todaySeconds = sessions
            .filter { cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.seconds }

        if let weekAgo = cal.date(byAdding: .day, value: -7, to: today) {
            weekSeconds = sessions
                .filter { $0.date >= weekAgo }
                .reduce(0) { $0 + $1.seconds }
        }
    }

    private func saveSession(seconds: Int) {
        var sessions = loadSessions()
        sessions.append(Session(date: Date(), seconds: seconds))

        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        sessions = sessions.filter { $0.date >= cutoff }

        cachedSessions = sessions
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadSessions() -> [Session] {
        if let cached = cachedSessions { return cached }
        let loaded = loadSessionsFromDisk()
        cachedSessions = loaded
        return loaded
    }

    private func loadSessionsFromDisk() -> [Session] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return decoded
    }
}
