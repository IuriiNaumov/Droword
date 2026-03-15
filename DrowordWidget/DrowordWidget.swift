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

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(red: 0.96, green: 0.95, blue: 0.93))

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.45, green: 0.72, blue: 0.96))
                        .frame(width: 52, height: 52)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Add Word")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
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
    }
}

#Preview(as: .systemSmall) {
    DrowordWidget()
} timeline: {
    SimpleEntry(date: .now)
}
