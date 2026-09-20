import Foundation

enum TranslationLimits {

    static func maxFreeTranslations(daysSinceInstall: Int) -> Int {
        daysSinceInstall <= 7 ? 10 : 5
    }

    static func maxFreeTranslations(firstUse: Date?, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let firstUse else { return 7 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstUse), to: calendar.startOfDay(for: now)).day ?? 0
        return maxFreeTranslations(daysSinceInstall: days)
    }
}
