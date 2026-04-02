import Foundation
import SwiftUI
import Combine

enum BadgeCategory: String, CaseIterable {
    case wordCount
    case streak
    case dailyGoal
    case quizMastery
    case suggestedWords

    var title: String {
        switch self {
        case .wordCount:       return "Words"
        case .streak:          return "Streaks"
        case .dailyGoal:       return "Daily Goals"
        case .quizMastery:     return "Quizzes"
        case .suggestedWords:  return "Suggested Words"
        }
    }
}

struct BadgeDefinition: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let category: BadgeCategory
    let requiredCount: Int
}

@MainActor
final class BadgeStore: ObservableObject {
    @Published var quizCompletions: Int {
        didSet { UserDefaults.standard.set(quizCompletions, forKey: "badge.quizCompletions") }
    }
    @Published var dailyGoalCompletions: Int {
        didSet { UserDefaults.standard.set(dailyGoalCompletions, forKey: "badge.dailyGoalCompletions") }
    }
    @Published var suggestedWordsAccepted: Int {
        didSet { UserDefaults.standard.set(suggestedWordsAccepted, forKey: "badge.suggestedWordsAccepted") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.quizCompletions = defaults.integer(forKey: "badge.quizCompletions")
        self.dailyGoalCompletions = defaults.integer(forKey: "badge.dailyGoalCompletions")
        self.suggestedWordsAccepted = defaults.integer(forKey: "badge.suggestedWordsAccepted")
    }

    func recordQuizCompletion() {
        quizCompletions += 1
    }

    func recordDailyGoalCompletion() {
        dailyGoalCompletions += 1
    }

    func recordSuggestedWordAccepted() {
        suggestedWordsAccepted += 1
    }

    func progress(for badge: BadgeDefinition, totalWords: Int, currentStreak: Int) -> Int {
        switch badge.category {
        case .wordCount:    return totalWords
        case .streak:       return currentStreak
        case .dailyGoal:    return dailyGoalCompletions
        case .quizMastery:  return quizCompletions
        case .suggestedWords: return suggestedWordsAccepted
        }
    }

    func isUnlocked(_ badge: BadgeDefinition, totalWords: Int, currentStreak: Int) -> Bool {
        progress(for: badge, totalWords: totalWords, currentStreak: currentStreak) >= badge.requiredCount
    }

    static let allBadges: [BadgeDefinition] = [
        BadgeDefinition(id: "words.10",  emoji: "🌱", title: "Seedling",       description: "Add 10 words",              category: .wordCount, requiredCount: 10),
        BadgeDefinition(id: "words.25",  emoji: "🌿", title: "Sprout",         description: "Add 25 words",              category: .wordCount, requiredCount: 25),
        BadgeDefinition(id: "words.50",  emoji: "🌳", title: "Sapling",        description: "Add 50 words",              category: .wordCount, requiredCount: 50),
        BadgeDefinition(id: "words.100", emoji: "🏆", title: "Centurion",      description: "Add 100 words",             category: .wordCount, requiredCount: 100),
        BadgeDefinition(id: "words.200", emoji: "👑", title: "Royalty",         description: "Add 200 words",             category: .wordCount, requiredCount: 200),
        BadgeDefinition(id: "words.500", emoji: "💎", title: "Diamond",         description: "Add 500 words",             category: .wordCount, requiredCount: 500),

        BadgeDefinition(id: "streak.7",   emoji: "🔥", title: "Week Warrior",   description: "7-day streak",              category: .streak, requiredCount: 7),
        BadgeDefinition(id: "streak.30",  emoji: "⚡", title: "Monthly Master",  description: "30-day streak",             category: .streak, requiredCount: 30),
        BadgeDefinition(id: "streak.100", emoji: "🌟", title: "Unstoppable",    description: "100-day streak",            category: .streak, requiredCount: 100),

        BadgeDefinition(id: "goal.5",  emoji: "🎯", title: "On Target",     description: "Complete 5 daily goals",    category: .dailyGoal, requiredCount: 5),
        BadgeDefinition(id: "goal.10", emoji: "🎯", title: "Sharpshooter",  description: "Complete 10 daily goals",   category: .dailyGoal, requiredCount: 10),
        BadgeDefinition(id: "goal.25", emoji: "🎯", title: "Marksman",      description: "Complete 25 daily goals",   category: .dailyGoal, requiredCount: 25),
        BadgeDefinition(id: "goal.50", emoji: "🎯", title: "Bullseye",      description: "Complete 50 daily goals",   category: .dailyGoal, requiredCount: 50),

        BadgeDefinition(id: "quiz.10",  emoji: "📝", title: "Quiz Rookie",   description: "Complete 10 quizzes",       category: .quizMastery, requiredCount: 10),
        BadgeDefinition(id: "quiz.50",  emoji: "📝", title: "Quiz Pro",      description: "Complete 50 quizzes",       category: .quizMastery, requiredCount: 50),
        BadgeDefinition(id: "quiz.100", emoji: "📝", title: "Quiz Legend",   description: "Complete 100 quizzes",      category: .quizMastery, requiredCount: 100),

        BadgeDefinition(id: "suggested.5",  emoji: "💡", title: "Open Mind",       description: "Accept 5 suggested words",   category: .suggestedWords, requiredCount: 5),
        BadgeDefinition(id: "suggested.20", emoji: "💡", title: "Word Explorer",  description: "Accept 20 suggested words",  category: .suggestedWords, requiredCount: 20),
        BadgeDefinition(id: "suggested.50", emoji: "💡", title: "Vocab Builder",  description: "Accept 50 suggested words",  category: .suggestedWords, requiredCount: 50),
    ]
}
