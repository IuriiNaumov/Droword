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

// Mini sakura for widget
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

// Mini sun for widget
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

// Mini snowflake for widget
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

// Mini leaf for widget
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
                    seasonalDecoration(season: season, size: 32)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -4, y: -4)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    seasonalDecoration(season: season, size: 24)
                        .rotationEffect(.degrees(25))
                        .offset(x: 4, y: 4)
                }
            }

            // Main content
            VStack(spacing: 10) {
                ZStack {
                    // Glow
                    Circle()
                        .fill(season.accentColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                        .blur(radius: 4)

                    // Button circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [season.accentColor, season.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: season.accentColor.opacity(0.4), radius: 6, y: 3)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Add Word")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(.label), Color(.label).opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Droword")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
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
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Add Word")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Droword")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.6)
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
            DrowordRectangularWidgetView()
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
        .configurationDisplayName("Add Word")
        .description("Quickly add a new word to Droword")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .accessoryCircular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .accessoryRectangular) {
    Droword_Widget()
} timeline: {
    SimpleEntry(date: .now)
}
