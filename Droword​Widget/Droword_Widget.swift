import WidgetKit
import SwiftUI

// MARK: - Data Model

private struct WidgetWord: Codable {
    let word: String
    let translation: String?
    let dueDate: Date?
    let dateAdded: Date

    private enum CodingKeys: String, CodingKey {
        case word, translation, dueDate, dateAdded
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        word = try c.decode(String.self, forKey: .word)
        translation = try c.decodeIfPresent(String.self, forKey: .translation)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        dateAdded = (try? c.decode(Date.self, forKey: .dateAdded)) ?? Date()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dueCount: Int
    let totalWords: Int
    let currentStreak: Int
    let featuredWord: String?
    let featuredTranslation: String?
}

// MARK: - Provider

struct Provider: TimelineProvider {
    private static let appGroupID = "group.com.droword.shared"
    private static let storageKey = "WordsStore.words"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dueCount: 3, totalWords: 12, currentStreak: 5,
                    featuredWord: "serendipity", featuredTranslation: "счастливая случайность")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = buildEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func buildEntry() -> SimpleEntry {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            return SimpleEntry(date: Date(), dueCount: 0, totalWords: 0, currentStreak: 0,
                               featuredWord: nil, featuredTranslation: nil)
        }

        let streak = defaults.integer(forKey: "currentStreak")
        let words = Self.readWords(defaults: defaults)
        let now = Date()
        let dueWords = words.filter { w in
            if let due = w.dueDate { return due <= now }
            return true
        }
        let dueCount = dueWords.count
        let picked = Self.pickWordOfTheDay(dueWords: dueWords, allWords: words)

        return SimpleEntry(date: Date(), dueCount: dueCount, totalWords: words.count,
                           currentStreak: streak,
                           featuredWord: picked?.word,
                           featuredTranslation: picked?.translation)
    }

    private static func readWords(defaults: UserDefaults) -> [WidgetWord] {
        guard let data = defaults.data(forKey: storageKey),
              let words = try? JSONDecoder().decode([WidgetWord].self, from: data) else {
            return []
        }
        return words
    }

    /// Deterministic daily word pick: prefers due words with translations, falls back to recent words
    private static func pickWordOfTheDay(dueWords: [WidgetWord], allWords: [WidgetWord]) -> WidgetWord? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        // Prefer due words that have a translation
        let dueWithTranslation = dueWords.filter { $0.translation != nil && !($0.translation?.isEmpty ?? true) }
        if !dueWithTranslation.isEmpty {
            return dueWithTranslation[dayOfYear % dueWithTranslation.count]
        }

        // Fall back to any word with a translation
        let withTranslation = allWords.filter { $0.translation != nil && !($0.translation?.isEmpty ?? true) }
        if !withTranslation.isEmpty {
            return withTranslation[dayOfYear % withTranslation.count]
        }

        // Fall back to any word
        if !allWords.isEmpty {
            return allWords[dayOfYear % allWords.count]
        }

        return nil
    }
}

// MARK: - Seasonal decorations for widget

private enum WidgetSeason {
    case winter, spring, summer, fall

    static var current: WidgetSeason {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2:  return .winter
        case 3, 4, 5:   return .spring
        case 6, 7, 8:   return .summer
        default:         return .fall
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .spring: return [Color(red: 1.0, green: 0.94, blue: 0.96), Color(red: 0.98, green: 0.88, blue: 0.93)]
        case .summer: return [Color(red: 1.0, green: 0.97, blue: 0.90), Color(red: 1.0, green: 0.93, blue: 0.82)]
        case .fall:   return [Color(red: 1.0, green: 0.96, blue: 0.90), Color(red: 0.96, green: 0.90, blue: 0.82)]
        case .winter: return [Color(red: 0.93, green: 0.96, blue: 1.0), Color(red: 0.88, green: 0.93, blue: 1.0)]
        }
    }

    var accentColor: Color {
        switch self {
        case .spring: return Color(red: 1.0, green: 0.56, blue: 0.82)
        case .summer: return Color(red: 1.0, green: 0.78, blue: 0.28)
        case .fall:   return Color(red: 0.83, green: 0.52, blue: 0.18)
        case .winter: return Color(red: 0.45, green: 0.72, blue: 0.96)
        }
    }
}

private struct MiniSakura: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.56, blue: 0.82).opacity(0.5))
                    .frame(width: size * 0.25, height: size * 0.38)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Color(red: 1.0, green: 0.37, blue: 0.69).opacity(0.5))
                .frame(width: size * 0.18, height: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

private struct MiniSun: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4))
                    .frame(width: size * 0.2, height: size * 0.4)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(Color(red: 0.96, green: 0.64, blue: 0.0).opacity(0.4))
                .frame(width: size * 0.25, height: size * 0.25)
        }
        .frame(width: size, height: size)
    }
}

private struct MiniSnowflake: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color(red: 0.3, green: 0.65, blue: 1.0).opacity(0.35))
                    .frame(width: size * 0.06, height: size * 0.75)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(Color(red: 0.3, green: 0.65, blue: 1.0).opacity(0.3))
                .frame(width: size * 0.15, height: size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

private struct MiniLeaf: View {
    let size: CGFloat
    var body: some View {
        Ellipse()
            .fill(Color(red: 0.83, green: 0.52, blue: 0.18).opacity(0.35))
            .frame(width: size * 0.6, height: size * 0.85)
            .overlay(
                Capsule()
                    .fill(Color(red: 0.55, green: 0.29, blue: 0.12).opacity(0.3))
                    .frame(width: size * 0.04, height: size * 0.65)
            )
            .frame(width: size, height: size)
    }
}

@ViewBuilder
private func seasonalDecoration(season: WidgetSeason, size: CGFloat) -> some View {
    switch season {
    case .spring: MiniSakura(size: size)
    case .summer: MiniSun(size: size)
    case .fall:   MiniLeaf(size: size)
    case .winter: MiniSnowflake(size: size)
    }
}

// MARK: - Home Screen Widget View (systemSmall)

struct DrowordWidgetEntryView: View {
    var entry: Provider.Entry
    private let season = WidgetSeason.current

    var body: some View {
        ZStack {
            // Decorative seasonal elements
            VStack {
                HStack {
                    seasonalDecoration(season: season, size: 28)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -4, y: -4)
                    Spacer()
                    if entry.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Text("🔥")
                                .font(.system(size: 11))
                            Text("\(entry.currentStreak)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.15))
                        )
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    seasonalDecoration(season: season, size: 20)
                        .rotationEffect(.degrees(25))
                        .offset(x: 4, y: 4)
                }
            }

            // Main content
            VStack(spacing: 6) {
                if entry.dueCount > 0 {
                    // Due words mode
                    ZStack {
                        Circle()
                            .fill(season.accentColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .blur(radius: 4)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [season.accentColor, season.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: season.accentColor.opacity(0.4), radius: 6, y: 3)

                        Text("\(entry.dueCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("\(entry.dueCount == 1 ? "word" : "words") to review")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(.label), Color(.label).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Featured word
                    if let word = entry.featuredWord {
                        VStack(spacing: 1) {
                            Text(word)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                            if let tr = entry.featuredTranslation {
                                Text(tr)
                                    .font(.system(size: 9, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else if entry.totalWords > 0 {
                    // All caught up
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .blur(radius: 4)

                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("All caught up!")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)

                    if let word = entry.featuredWord {
                        VStack(spacing: 1) {
                            Text(word)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                            if let tr = entry.featuredTranslation {
                                Text(tr)
                                    .font(.system(size: 9, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    // No words — show Add Word button
                    ZStack {
                        Circle()
                            .fill(season.accentColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .blur(radius: 4)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [season.accentColor, season.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: season.accentColor.opacity(0.4), radius: 6, y: 3)

                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Add Word")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(.label), Color(.label).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("Droword")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
    }
}

// MARK: - Home Screen Widget View (systemMedium)

struct DrowordMediumWidgetView: View {
    var entry: Provider.Entry
    private let season = WidgetSeason.current

    var body: some View {
        ZStack {
            // Seasonal decorations
            VStack {
                HStack {
                    seasonalDecoration(season: season, size: 24)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -2, y: -2)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    seasonalDecoration(season: season, size: 20)
                        .rotationEffect(.degrees(25))
                        .offset(x: 2, y: 2)
                }
            }

            HStack(spacing: 16) {
                // Left column: streak + due count
                VStack(spacing: 10) {
                    // Streak
                    VStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 22))
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
                        Text(entry.currentStreak == 1 ? "day" : "days")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    // Due badge
                    if entry.dueCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(season.accentColor)
                                .frame(width: 8, height: 8)
                            Text("\(entry.dueCount) due")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.label))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(season.accentColor.opacity(0.15))
                        )
                    } else if entry.totalWords > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("All done")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Divider
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(.separator).opacity(0.3))
                    .frame(width: 1, height: 70)

                // Right column: word of the day
                VStack(spacing: 6) {
                    Text("Word of the Day")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    if let word = entry.featuredWord {
                        Text(word)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        if let translation = entry.featuredTranslation {
                            Text(translation)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Add your first word!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Text("Droword")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Lock Screen Circular Widget (accessoryCircular)

struct DrowordCircularWidgetView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold, design: .rounded))
        }
    }
}

// MARK: - Lock Screen Rectangular Widget (accessoryRectangular)

struct DrowordRectangularWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 32, height: 32)
                if entry.dueCount > 0 {
                    Text("\(entry.dueCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: entry.totalWords > 0 ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                if entry.dueCount > 0 {
                    Text("\(entry.dueCount) to review")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                } else if entry.totalWords > 0 {
                    Text("All caught up!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                } else {
                    Text("Add Word")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                if entry.currentStreak > 0 {
                    Text("🔥 \(entry.currentStreak) day streak")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.8)
                } else {
                    Text("Droword")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.6)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Adaptive Widget View (selects layout by family)

struct DrowordAdaptiveWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            DrowordCircularWidgetView()
        case .accessoryRectangular:
            DrowordRectangularWidgetView(entry: entry)
        case .systemMedium:
            DrowordMediumWidgetView(entry: entry)
        default:
            DrowordWidgetEntryView(entry: entry)
        }
    }
}

struct Droword_Widget: Widget {
    let kind: String = "AddWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DrowordAdaptiveWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    let season = WidgetSeason.current
                    LinearGradient(
                        colors: season.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .widgetURL(URL(string: "droword://add"))
        }
        .configurationDisplayName("Droword")
        .description("Track your streak, see words to review, and word of the day")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 12,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность")
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42, currentStreak: 3,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный")
    SimpleEntry(date: .now, dueCount: 0, totalWords: 0, currentStreak: 0,
                featuredWord: nil, featuredTranslation: nil)
}

#Preview(as: .systemMedium) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 12,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность")
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42, currentStreak: 3,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный")
}

#Preview(as: .accessoryCircular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 3, totalWords: 20, currentStreak: 5,
                featuredWord: nil, featuredTranslation: nil)
}

#Preview(as: .accessoryRectangular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 7,
                featuredWord: nil, featuredTranslation: nil)
}
