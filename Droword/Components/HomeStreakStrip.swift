import SwiftUI

struct HomeStreakStrip: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var activity = StudyActivityStore.shared

    var onOpenCalendar: () -> Void

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your week")
                .font(themeStore.bold(16))
                .foregroundStyle(themeStore.mainText)

            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let studied = activity.studied(on: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    VStack(spacing: 6) {
                        Circle()
                            .fill(studied ? themeStore.mainAccentColor : themeStore.dividerColor.opacity(0.7))
                            .frame(width: 12, height: 12)
                            .overlay {
                                if isToday {
                                    Circle()
                                        .stroke(themeStore.mainText.opacity(0.35), lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                }
                            }
                        Text(Self.weekday(day))
                            .font(themeStore.regular(11))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .onTapGesture { onOpenCalendar() }
        .onAppear {
            activity.ensureMigrated(from: store.words)
        }
    }

    private static func weekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}
