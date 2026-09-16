import WidgetKit
import SwiftUI

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
    let lessonDone: Bool
    let lessonScore: String?
}

struct Provider: TimelineProvider {
    private static let appGroupID = "group.com.droword.shared"
    private static let storageKey = "WordsStore.words"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            dueCount: 3,
            totalWords: 12,
            currentStreak: 5,
            featuredWord: "serendipity",
            featuredTranslation: "счастливая случайность",
            lessonDone: false,
            lessonScore: nil
        )
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
            return SimpleEntry(
                date: Date(),
                dueCount: 0,
                totalWords: 0,
                currentStreak: 0,
                featuredWord: nil,
                featuredTranslation: nil,
                lessonDone: false,
                lessonScore: nil
            )
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

        let today = {
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: Date())
        }()
        let lessonDone = (defaults.string(forKey: "widget.lessonDay") ?? "") == today
        let lessonTotal = defaults.integer(forKey: "widget.lessonTotal")
        let lessonCorrect = defaults.integer(forKey: "widget.lessonCorrect")
        let lessonScore = lessonDone && lessonTotal > 0 ? "\(lessonCorrect)/\(lessonTotal)" : nil

        return SimpleEntry(
            date: Date(),
            dueCount: dueCount,
            totalWords: words.count,
            currentStreak: streak,
            featuredWord: picked?.word,
            featuredTranslation: picked?.translation,
            lessonDone: lessonDone,
            lessonScore: lessonScore
        )
    }

    private static func readWords(defaults: UserDefaults) -> [WidgetWord] {
        guard let data = defaults.data(forKey: storageKey),
              let words = try? JSONDecoder().decode([WidgetWord].self, from: data) else {
            return []
        }
        return words
    }

    private static func pickWordOfTheDay(dueWords: [WidgetWord], allWords: [WidgetWord]) -> WidgetWord? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        let dueWithTranslation = dueWords.filter { $0.translation != nil && !($0.translation?.isEmpty ?? true) }
        if !dueWithTranslation.isEmpty {
            return dueWithTranslation[dayOfYear % dueWithTranslation.count]
        }

        let withTranslation = allWords.filter { $0.translation != nil && !($0.translation?.isEmpty ?? true) }
        if !withTranslation.isEmpty {
            return withTranslation[dayOfYear % withTranslation.count]
        }

        if !allWords.isEmpty {
            return allWords[dayOfYear % allWords.count]
        }

        return nil
    }
}

// MARK: - Brand tokens (widget-local; theme store isn't available here)

private enum WidgetChrome {
    static let accent = Color(red: 0.52, green: 0.40, blue: 0.95)
    static let streak = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)

    static var softBg: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.95, blue: 1.0),
                Color(red: 0.93, green: 0.91, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkBg: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.09, blue: 0.16),
                Color(red: 0.07, green: 0.06, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct WidgetMark: View {
    let systemName: String
    var tint: Color = WidgetChrome.accent
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tint.opacity(0.16))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .widgetAccentable()
        }
    }
}

private struct StreakPill: View {
    let count: Int
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 3 : 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: compact ? 10 : 11, weight: .bold))
            Text("\(count)")
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .foregroundStyle(WidgetChrome.streak)
        .padding(.horizontal, compact ? 7 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            Capsule(style: .continuous)
                .fill(WidgetChrome.streak.opacity(0.14))
        )
        .widgetAccentable()
    }
}

// MARK: - Small

struct DrowordWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    private var isAccented: Bool { renderingMode == .accented }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                WidgetMark(
                    systemName: markIcon,
                    tint: markTint,
                    size: 36
                )
                Spacer(minLength: 0)
                if entry.currentStreak > 0 {
                    StreakPill(count: entry.currentStreak, compact: true)
                }
            }

            Spacer(minLength: 8)

            Text(headline)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .widgetAccentable()

            Text(subline)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.top, 3)
        }
        .padding(16)
    }

    private var markIcon: String {
        if entry.totalWords == 0 { return "plus" }
        if entry.lessonDone { return "checkmark" }
        return "bolt.fill"
    }

    private var markTint: Color {
        if isAccented { return .primary }
        if entry.lessonDone { return WidgetChrome.success }
        return WidgetChrome.accent
    }

    private var headline: String {
        if entry.totalWords == 0 { return "Add a word" }
        if entry.lessonDone { return "See you tomorrow" }
        return "Today's lesson"
    }

    private var subline: String {
        if entry.totalWords == 0 { return "Tap to start" }
        if entry.lessonDone {
            return entry.lessonScore.map { "\($0) today" } ?? "Lesson done"
        }
        if entry.dueCount > 0 { return "\(entry.dueCount) due" }
        if let word = entry.featuredWord { return word }
        return "Ready when you are"
    }
}

// MARK: - Medium

struct DrowordMediumWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var isAccented: Bool { renderingMode == .accented }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                if entry.currentStreak > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(isAccented ? Color.primary : WidgetChrome.streak)
                            .widgetAccentable()
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(isAccented ? Color.primary : WidgetChrome.streak)
                            .widgetAccentable()
                            .contentTransition(.numericText())
                    }
                    Text(entry.currentStreak == 1 ? "day streak" : "day streak")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    WidgetMark(systemName: "bolt.fill", size: 40)
                    Text("Start a streak")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                statusChip
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.lessonDone ? "WORD OF THE DAY" : "NEXT UP")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                if let word = entry.featuredWord {
                    Text(word)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .widgetAccentable()

                    if let translation = entry.featuredTranslation {
                        Text(translation)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    Text("Add your first word")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .widgetAccentable()
                }

                Spacer(minLength: 0)

                Text("Droword")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    @ViewBuilder
    private var statusChip: some View {
        let label: String = {
            if entry.totalWords == 0 { return "Add a word" }
            if entry.lessonDone { return entry.lessonScore.map { "Done · \($0)" } ?? "Done" }
            if entry.dueCount > 0 { return "\(entry.dueCount) due" }
            return "Open lesson"
        }()
        let tint: Color = {
            if isAccented { return .primary }
            if entry.lessonDone { return WidgetChrome.success }
            return WidgetChrome.accent
        }()

        HStack(spacing: 5) {
            Image(systemName: entry.lessonDone ? "checkmark" : (entry.totalWords == 0 ? "plus" : "bolt.fill"))
                .font(.system(size: 10, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .widgetAccentable()
    }
}

// MARK: - Lock Screen

struct DrowordCircularWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.lessonDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .widgetAccentable()
            } else if entry.dueCount > 0 {
                Text("\(entry.dueCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .widgetAccentable()
            } else {
                Image(systemName: entry.totalWords > 0 ? "bolt.fill" : "plus")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .widgetAccentable()
            }
        }
    }
}

struct DrowordRectangularWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: 30, height: 30)
                if entry.lessonDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                } else if entry.dueCount > 0 {
                    Text("\(entry.dueCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: entry.totalWords > 0 ? "bolt.fill" : "plus")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
            .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .widgetAccentable()
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.75)
            }
            Spacer(minLength: 0)
        }
    }

    private var title: String {
        if entry.totalWords == 0 { return "Add a word" }
        if entry.lessonDone { return "See you tomorrow" }
        return "Today's lesson"
    }

    private var subtitle: String {
        if entry.currentStreak > 0 {
            return "\(entry.currentStreak)-day streak"
        }
        if entry.dueCount > 0 {
            return "\(entry.dueCount) due"
        }
        return "Droword"
    }
}

// MARK: - Adaptive shell

struct DrowordAdaptiveWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            DrowordCircularWidgetView(entry: entry)
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
                    WidgetBackground()
                }
                .widgetURL(URL(string: "droword://open"))
        }
        .configurationDisplayName("Droword")
        .description("Today's lesson, streak, and a word of the day")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

private struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        Group {
            if renderingMode == .accented {
                Color.clear
            } else if colorScheme == .dark {
                WidgetChrome.darkBg
            } else {
                WidgetChrome.softBg
            }
        }
    }
}

#Preview(as: .systemSmall) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 12,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность",
                lessonDone: false, lessonScore: nil)
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42, currentStreak: 3,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный",
                lessonDone: true, lessonScore: "7/8")
    SimpleEntry(date: .now, dueCount: 0, totalWords: 0, currentStreak: 0,
                featuredWord: nil, featuredTranslation: nil,
                lessonDone: false, lessonScore: nil)
}

#Preview(as: .systemMedium) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 12,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность",
                lessonDone: false, lessonScore: nil)
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42, currentStreak: 3,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный",
                lessonDone: true, lessonScore: "7/8")
}

#Preview(as: .accessoryCircular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 3, totalWords: 20, currentStreak: 5,
                featuredWord: nil, featuredTranslation: nil,
                lessonDone: false, lessonScore: nil)
}

#Preview(as: .accessoryRectangular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42, currentStreak: 7,
                featuredWord: nil, featuredTranslation: nil,
                lessonDone: false, lessonScore: nil)
}
