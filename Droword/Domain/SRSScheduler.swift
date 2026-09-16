import Foundation

struct SchedulingState: Equatable {
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var lapses: Int
}

struct SchedulingResult: Equatable {
    var state: SchedulingState
    var dueDate: Date

    var reinsertAfterCards: Int?
}

enum SRSScheduler {
    static func updatedEaseFactor(current: Double, q: Double) -> Double {
        var ef = max(1.3, current)
        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        return min(3.0, max(1.3, ef))
    }

    enum ReviewGrade {
        case hard, good, easy

        var q: Double {
            switch self {
            case .hard: return 3
            case .good: return 4
            case .easy: return 5
            }
        }

        var learningSample: Double {
            switch self {
            case .hard: return 0.3
            case .good: return 0.7
            case .easy: return 1.0
            }
        }
    }

    static func scheduleReview(
        state: SchedulingState,
        grade: ReviewGrade,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> SchedulingResult {
        var next = state
        next.easeFactor = updatedEaseFactor(current: state.easeFactor, q: grade.q)

        if grade == .hard {
            let due = calendar.date(byAdding: .minute, value: 10, to: now) ?? now
            return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: 2)
        }

        next.repetitions += 1
        if next.repetitions == 1 {
            next.intervalDays = grade == .easy ? 2 : 1
        } else if next.repetitions == 2 {
            next.intervalDays = grade == .easy ? 8 : 6
        } else {
            let multiplier = grade == .easy ? next.easeFactor * 1.3 : next.easeFactor
            next.intervalDays = max(1, Int(round(Double(state.intervalDays) * multiplier)))
        }
        let due = calendar.date(byAdding: .day, value: next.intervalDays, to: now) ?? now
        return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: nil)
    }

    static func previewReviewIntervalDays(state: SchedulingState, grade: ReviewGrade) -> Int {
        guard grade != .hard else { return 0 }
        let ef = updatedEaseFactor(current: state.easeFactor, q: grade.q)
        let reps = state.repetitions + 1
        if reps == 1 { return grade == .easy ? 2 : 1 }
        if reps == 2 { return grade == .easy ? 8 : 6 }
        let multiplier = grade == .easy ? ef * 1.3 : ef
        return max(1, Int(round(Double(state.intervalDays) * multiplier)))
    }

    static func scheduleQuiz(
        state: SchedulingState,
        correct: Bool,
        almostCorrect: Bool = false,
        strong: Bool = false,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> SchedulingResult {
        let q: Double
        if !correct {
            q = 1
        } else if almostCorrect {
            q = 3
        } else if strong {
            q = 5
        } else {
            q = 4
        }

        var next = state
        next.easeFactor = updatedEaseFactor(current: state.easeFactor, q: q)

        if q < 3 {
            next.lapses += 1
            next.repetitions = 0
            next.intervalDays = 0
            let due = calendar.date(byAdding: .minute, value: 10, to: now) ?? now
            return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: nil)
        }

        next.repetitions += 1
        if next.repetitions == 1 {
            if strong {
                next.intervalDays = 1
                let due = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: nil)
            } else {
                next.intervalDays = 0
                let due = calendar.date(byAdding: .hour, value: 8, to: now) ?? now
                return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: nil)
            }
        }

        if next.repetitions == 2 {
            next.intervalDays = 6
        } else {
            next.intervalDays = max(1, Int(round(Double(state.intervalDays) * next.easeFactor)))
        }
        let due = calendar.date(byAdding: .day, value: next.intervalDays, to: now) ?? now
        return SchedulingResult(state: next, dueDate: due, reinsertAfterCards: nil)
    }

    static func quizLearningSample(correct: Bool, almostCorrect: Bool) -> Double {
        if !correct { return 0.0 }
        if almostCorrect { return 0.5 }
        return 1.0
    }
}

enum LearningScore {
    static func blend(previous: Double, sample: Double, alpha: Double = 0.06) -> Double {
        max(0.0, min(1.0, previous * (1 - alpha) + sample * alpha))
    }
}
