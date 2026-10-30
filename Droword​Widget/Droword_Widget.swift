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
                featuredWord: nil,
                featuredTranslation: nil,
                lessonDone: false,
                lessonScore: nil
            )
        }

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

private enum WidgetChrome {
    static let accent = Color(red: 0.416, green: 0.227, blue: 0.769)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)

    static var softBg: some View {
        LinearGradient(
            colors: [
                Color(red: 0.963, green: 0.966, blue: 0.979),
                Color(red: 0.94, green: 0.945, blue: 0.97)
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

    static func cardFill(colorScheme: ColorScheme, renderingMode: WidgetRenderingMode) -> Color {
        if renderingMode == .accented {
            return Color.primary.opacity(0.14)
        }
        if colorScheme == .dark {
            return Color(red: 0.16, green: 0.15, blue: 0.22)
        }
        return .white
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

struct DrowordWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    private var isAccented: Bool { renderingMode == .accented }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetMark(
                systemName: markIcon,
                tint: markTint,
                size: 36
            )

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
        return "bolt"
    }

    private var markTint: Color {
        if isAccented { return .primary }
        if entry.lessonDone { return WidgetChrome.success }
        return WidgetChrome.accent
    }

    private var headline: String {
        if entry.totalWords == 0 { return "Add a word" }
        if entry.lessonDone { return "Done for today" }
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

struct DrowordMediumWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var isAccented: Bool { renderingMode == .accented }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                if entry.dueCount > 0 {
                    Text("\(entry.dueCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(isAccented ? Color.primary : WidgetChrome.accent)
                        .widgetAccentable()
                        .contentTransition(.numericText())
                    Text(entry.dueCount == 1 ? "word due" : "words due")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    WidgetMark(
                        systemName: entry.lessonDone ? "checkmark" : "bolt",
                        tint: entry.lessonDone ? WidgetChrome.success : WidgetChrome.accent,
                        size: 40
                    )
                    Text(entry.lessonDone ? "Done for today" : "Today's lesson")
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
            Image(systemName: entry.lessonDone ? "checkmark" : (entry.totalWords == 0 ? "plus" : "bolt"))
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
                    Image(systemName: entry.totalWords > 0 ? "bolt" : "plus")
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
        if entry.lessonDone { return "Done for today" }
        return "Today's lesson"
    }

    private var subtitle: String {
        if entry.dueCount > 0 {
            return "\(entry.dueCount) due"
        }
        return "Droword"
    }
}

struct DrowordAdaptiveWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
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
        .configurationDisplayName(Text("Today's lesson"))
        .description(Text("Lesson status and a word of the day"))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct AddWordQuickEntry: TimelineEntry {
    let date: Date
}

struct AddWordQuickProvider: TimelineProvider {
    func placeholder(in context: Context) -> AddWordQuickEntry {
        AddWordQuickEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (AddWordQuickEntry) -> Void) {
        completion(AddWordQuickEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AddWordQuickEntry>) -> Void) {
        completion(Timeline(entries: [AddWordQuickEntry(date: Date())], policy: .never))
    }
}

struct AddWordQuickWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: family == .accessoryCircular ? 22 : 48, weight: .bold, design: .rounded))
            .foregroundStyle(family == .accessoryCircular ? .primary : WidgetChrome.accent)
            .widgetAccentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                if family == .accessoryCircular {
                    AccessoryWidgetBackground()
                } else if renderingMode == .accented {
                    Color.clear
                } else if colorScheme == .dark {
                    WidgetChrome.darkBg
                } else {
                    WidgetChrome.softBg
                }
            }
    }
}

struct AddWordQuickWidget: Widget {
    let kind: String = "AddWordQuickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AddWordQuickProvider()) { _ in
            AddWordQuickWidgetView()
                .widgetURL(URL(string: "droword://add"))
        }
        .configurationDisplayName(Text("Add a new word"))
        .description(Text("Opens add word"))
        .supportedFamilies([.systemSmall, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct RecentWordsEntry: TimelineEntry {
    let date: Date
    let words: [(word: String, translation: String?)]
}

struct RecentWordsProvider: TimelineProvider {
    private static let appGroupID = "group.com.droword.shared"
    private static let storageKey = "WordsStore.words"

    func placeholder(in context: Context) -> RecentWordsEntry {
        RecentWordsEntry(date: Date(), words: [
            ("bonjour", "hello"),
            ("merci", "thanks"),
            ("salut", "hi")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentWordsEntry) -> Void) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentWordsEntry>) -> Void) {
        let entry = buildEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func buildEntry() -> RecentWordsEntry {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([WidgetWord].self, from: data) else {
            return RecentWordsEntry(date: Date(), words: [])
        }
        let recent = decoded
            .sorted { $0.dateAdded > $1.dateAdded }
            .prefix(3)
            .map { (word: $0.word, translation: $0.translation) }
        return RecentWordsEntry(date: Date(), words: Array(recent))
    }
}

struct RecentWordsWidgetView: View {
    var entry: RecentWordsEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetFamily) private var family

    private var isMedium: Bool { family == .systemMedium }

    private var cardFill: Color {
        WidgetChrome.cardFill(colorScheme: colorScheme, renderingMode: renderingMode)
    }

    var body: some View {
        Group {
            if entry.words.isEmpty {
                emptyState
            } else if isMedium {
                mediumCards
            } else {
                smallCards
            }
        }
        .padding(isMedium ? 14 : 12)
        .containerBackground(for: .widget) {
            if renderingMode == .accented {
                Color.clear
            } else if colorScheme == .dark {
                WidgetChrome.darkBg
            } else {
                WidgetChrome.softBg
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetChrome.accent)
                .widgetAccentable()
            Text("No words yet")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text("Tap to open dictionary")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var smallCards: some View {
        VStack(spacing: 6) {
            ForEach(Array(entry.words.enumerated()), id: \.offset) { _, item in
                wordCard(item, compact: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var mediumCards: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(entry.words.enumerated()), id: \.offset) { _, item in
                wordCard(item, compact: false)
            }
            if entry.words.count < 3 {
                ForEach(0..<(3 - entry.words.count), id: \.self) { _ in
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func wordCard(
        _ item: (word: String, translation: String?),
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text(item.word)
                .font(.system(size: compact ? 14 : 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(compact ? 1 : 2)
                .minimumScaleFactor(0.8)
                .widgetAccentable()

            if let translation = item.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: compact ? 11 : 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(compact ? 1 : 3)
                    .minimumScaleFactor(0.85)
            } else {
                Spacer(minLength: 0)
            }

            if !compact {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity, alignment: .topLeading)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardFill)
        )
    }
}

struct RecentWordsWidget: Widget {
    let kind: String = "RecentWordsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentWordsProvider()) { entry in
            RecentWordsWidgetView(entry: entry)
                .widgetURL(URL(string: "droword://dictionary"))
        }
        .configurationDisplayName("Recent words")
        .description("Last three words as dictionary cards")
        .supportedFamilies([.systemSmall, .systemMedium])
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
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность",
                lessonDone: false, lessonScore: nil)
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный",
                lessonDone: true, lessonScore: "7/8")
    SimpleEntry(date: .now, dueCount: 0, totalWords: 0,
                featuredWord: nil, featuredTranslation: nil,
                lessonDone: false, lessonScore: nil)
}

#Preview(as: .systemMedium) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42,
                featuredWord: "serendipity", featuredTranslation: "счастливая случайность",
                lessonDone: false, lessonScore: nil)
    SimpleEntry(date: .now, dueCount: 0, totalWords: 42,
                featuredWord: "ephemeral", featuredTranslation: "мимолётный",
                lessonDone: true, lessonScore: "7/8")
}

#Preview(as: .accessoryCircular) {
    AddWordQuickWidget()
} timeline: {
    AddWordQuickEntry(date: .now)
}

#Preview(as: .accessoryRectangular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 5, totalWords: 42,
                featuredWord: nil, featuredTranslation: nil,
                lessonDone: false, lessonScore: nil)
}

#Preview("Recent small", as: .systemSmall) {
    RecentWordsWidget()
} timeline: {
    RecentWordsEntry(date: .now, words: [
        ("bonjour", "hello"),
        ("merci", "thanks"),
        ("salut", "hi")
    ])
    RecentWordsEntry(date: .now, words: [])
}

#Preview("Recent medium", as: .systemMedium) {
    RecentWordsWidget()
} timeline: {
    RecentWordsEntry(date: .now, words: [
        ("bonjour", "hello"),
        ("merci", "thanks"),
        ("serendipity", "счастливая случайность")
    ])
}
