import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notifDailyReminders") private var dailyReminders: Bool = true
    @AppStorage("notifStreakMilestones") private var streakMilestones: Bool = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Notifications")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily reminders")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.primary)
                            Text("Morning, afternoon & evening reminders")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $dailyReminders)
                            .labelsHidden()
                            .tint(themeStore.mainAccentColor)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(themeStore.cardBg))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak milestones")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.primary)
                            Text("Celebrate 7, 30, 100 day streaks")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $streakMilestones)
                            .labelsHidden()
                            .tint(themeStore.mainAccentColor)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(themeStore.cardBg))
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        
        .onChange(of: dailyReminders) { _, enabled in
            if enabled {
                NotificationManager.shared.requestAuthorization { _ in }
            } else {
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [
                    "daily.slot.morning",
                    "daily.slot.afternoon",
                    "daily.slot.evening"
                ])
            }
        }
    }
}
