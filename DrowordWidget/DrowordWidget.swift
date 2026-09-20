import WidgetKit
import SwiftUI

private let appGroupID = "group.com.droword.shared"

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dueCount: Int
    let sampleWord: String?
    let wordOfDay: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dueCount: 3, sampleWord: "bonjour", wordOfDay: "merci")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let data = defaults?.data(forKey: "WordsStore.words"),
              let words = try? JSONDecoder().decode([WidgetWord].self, from: data),
              !words.isEmpty else {
            return SimpleEntry(date: Date(), dueCount: 0, sampleWord: nil, wordOfDay: nil)
        }

        let now = Date()
        let due = words.filter { word in
            guard let due = word.dueDate else { return false }
            return due <= now
        }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: now) ?? 0
        let wordOfDay = words[dayIndex % words.count].word

        return SimpleEntry(
            date: Date(),
            dueCount: due.count,
            sampleWord: due.first?.word ?? words.sorted(by: { $0.dateAdded > $1.dateAdded }).first?.word,
            wordOfDay: wordOfDay
        )
    }
}

private struct WidgetWord: Codable {
    let word: String
    let translation: String?
    let dueDate: Date?
    let dateAdded: Date
}

struct DrowordWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetRenderingMode) private var renderingMode

    private let accent = Color(red: 0.52, green: 0.40, blue: 0.95)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.dueCount > 0 ? "flame.fill" : "text.book.closed.fill")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .widgetAccentable()
            }

            Spacer(minLength: 8)

            if entry.dueCount > 0 {
                Text(entry.dueCount == 1
                     ? "1 due"
                     : "\(entry.dueCount) due")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .widgetAccentable()

                Text(entry.sampleWord ?? "Tap to review")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.top, 3)
            } else if let wordOfDay = entry.wordOfDay {
                Text("Word of the day")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(wordOfDay)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .widgetAccentable()
                    .lineLimit(1)
                    .padding(.top, 3)
            } else {
                Text("Add a word")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .widgetAccentable()

                Text("Tap to start")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 3)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            if renderingMode == .accented {
                Color.clear
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.95, blue: 1.0),
                        Color(red: 0.93, green: 0.91, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct DrowordWidget: Widget {
    let kind: String = "AddWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DrowordWidgetEntryView(entry: entry)
                .widgetURL(URL(string: entry.dueCount > 0 ? "droword://practice" : "droword://add"))
        }
        .configurationDisplayName("Droword")
        .description("See words due for review or today's word")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    DrowordWidget()
} timeline: {
    SimpleEntry(date: .now, dueCount: 0, sampleWord: nil, wordOfDay: "hola")
    SimpleEntry(date: .now, dueCount: 4, sampleWord: "merci", wordOfDay: "merci")
}
