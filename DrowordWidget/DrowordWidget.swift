import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
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
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .widgetAccentable()
            }

            Spacer(minLength: 8)

            Text("Add a word")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .widgetAccentable()

            Text("Tap to start")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 3)
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
                .widgetURL(URL(string: "droword://add"))
        }
        .configurationDisplayName("Add Word")
        .description("Quickly add a new word to Droword")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    DrowordWidget()
} timeline: {
    SimpleEntry(date: .now)
}
