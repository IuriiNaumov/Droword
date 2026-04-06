import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppStorageKeys.notifGlobalEnabled) private var globalEnabled: Bool = true
    @AppStorage(AppStorageKeys.notifDailyReminderEnabled) private var dailyReminderEnabled: Bool = true
    @AppStorage(AppStorageKeys.notifDailyReminderHour) private var dailyReminderHour: Int = 12
    @AppStorage(AppStorageKeys.notifDailyReminderMinute) private var dailyReminderMinute: Int = 0
    @AppStorage(AppStorageKeys.notifVocabEnabled) private var vocabEnabled: Bool = false
    @AppStorage(AppStorageKeys.notifVocabShowTranscription) private var vocabShowTranscription: Bool = true
    @AppStorage(AppStorageKeys.notifVocabShowTranslation) private var vocabShowTranslation: Bool = true
    @AppStorage(AppStorageKeys.notifVocabIncludeMastered) private var vocabIncludeMastered: Bool = false
    @AppStorage(AppStorageKeys.notifVocabFrequency) private var vocabFrequency: Int = 3
    @AppStorage(AppStorageKeys.notifVocabStartHour) private var vocabStartHour: Int = 9
    @AppStorage(AppStorageKeys.notifVocabStartMinute) private var vocabStartMinute: Int = 0
    @AppStorage(AppStorageKeys.notifVocabEndHour) private var vocabEndHour: Int = 18
    @AppStorage(AppStorageKeys.notifVocabEndMinute) private var vocabEndMinute: Int = 0
    @AppStorage(AppStorageKeys.notifStreakMilestones) private var streakMilestones: Bool = true

    @State private var rescheduleTask: Task<Void, Never>?

    private var dailyReminderDate: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: DateComponents(hour: dailyReminderHour, minute: dailyReminderMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                dailyReminderHour = comps.hour ?? 12
                dailyReminderMinute = comps.minute ?? 0
            }
        )
    }

    private var vocabStartDate: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: DateComponents(hour: vocabStartHour, minute: vocabStartMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                vocabStartHour = comps.hour ?? 9
                vocabStartMinute = comps.minute ?? 0
            }
        )
    }

    private var vocabEndDate: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: DateComponents(hour: vocabEndHour, minute: vocabEndMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                vocabEndHour = comps.hour ?? 18
                vocabEndMinute = comps.minute ?? 0
            }
        )
    }

    private var endBeforeStart: Bool {
        let startMins = vocabStartHour * 60 + vocabStartMinute
        let endMins = vocabEndHour * 60 + vocabEndMinute
        return endMins <= startMins
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Notifications")
                    .sheetTitle()

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "bell.fill",
                        color: themeStore.iconPink,
                        title: "Enable notifications",
                        isOn: $globalEnabled
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if globalEnabled {
                    sectionHeader("Daily reminder")

                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "sun.max.fill",
                            color: .orange,
                            title: "Daily motivation",
                            isOn: $dailyReminderEnabled
                        )

                        if dailyReminderEnabled {
                            Divider().padding(.leading, 68)

                            timePickerRow(
                                icon: "clock.fill",
                                color: themeStore.iconBlue,
                                title: "Reminder time",
                                date: dailyReminderDate
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.easeInOut(duration: 0.25), value: dailyReminderEnabled)

                    sectionHeader("Vocabulary")

                    if vocabEnabled {
                        notificationPreview
                    }

                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "character.book.closed.fill",
                            color: themeStore.iconGreen,
                            title: "Word notifications",
                            isOn: $vocabEnabled
                        )

                        if vocabEnabled {
                            Divider().padding(.leading, 68)

                            toggleRow(
                                icon: "textformat.abc",
                                color: themeStore.iconPurple,
                                title: "Show transcription",
                                isOn: $vocabShowTranscription
                            )

                            Divider().padding(.leading, 68)

                            toggleRow(
                                icon: "text.bubble.fill",
                                color: themeStore.iconBlue,
                                title: "Show translation",
                                isOn: $vocabShowTranslation
                            )

                            Divider().padding(.leading, 68)

                            toggleRow(
                                icon: "checkmark.seal.fill",
                                color: themeStore.iconGold,
                                title: "Include mastered",
                                isOn: $vocabIncludeMastered
                            )

                            Divider().padding(.leading, 68)

                            frequencyRow(value: $vocabFrequency)

                            Divider().padding(.leading, 68)

                            timePickerRow(
                                icon: "sunrise.fill",
                                color: .orange,
                                title: "From",
                                date: vocabStartDate
                            )

                            Divider().padding(.leading, 68)

                            timePickerRow(
                                icon: "sunset.fill",
                                color: themeStore.iconPurple,
                                title: "Until",
                                date: vocabEndDate
                            )

                            if endBeforeStart {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                    Text("End time must be after start time")
                                        .font(themeStore.regular(12))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                            }

                            if store.words.isEmpty {
                                Text("Add words to receive vocabulary notifications")
                                    .font(themeStore.regular(12))
                                    .foregroundColor(themeStore.secondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 6)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.easeInOut(duration: 0.25), value: vocabEnabled)

                    sectionHeader("Other")

                    VStack(spacing: 0) {
                        toggleRow(
                            icon: "flame.fill",
                            color: .orange,
                            title: "Streak milestones",
                            isOn: $streakMilestones
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Get notified when you reach 7, 30, 100 and 365 day streaks.")
                        .font(themeStore.regular(12))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .animation(.easeInOut(duration: 0.25), value: globalEnabled)
        .onChange(of: globalEnabled) { _, _ in triggerReschedule() }
        .onChange(of: dailyReminderEnabled) { _, _ in triggerReschedule() }
        .onChange(of: dailyReminderHour) { _, _ in triggerReschedule() }
        .onChange(of: dailyReminderMinute) { _, _ in triggerReschedule() }
        .onChange(of: vocabEnabled) { _, _ in triggerReschedule() }
        .onChange(of: vocabShowTranscription) { _, _ in triggerReschedule() }
        .onChange(of: vocabShowTranslation) { _, _ in triggerReschedule() }
        .onChange(of: vocabIncludeMastered) { _, _ in triggerReschedule() }
        .onChange(of: vocabFrequency) { _, _ in triggerReschedule() }
        .onChange(of: vocabStartHour) { _, _ in triggerReschedule() }
        .onChange(of: vocabStartMinute) { _, _ in triggerReschedule() }
        .onChange(of: vocabEndHour) { _, _ in triggerReschedule() }
        .onChange(of: vocabEndMinute) { _, _ in triggerReschedule() }
        .onChange(of: streakMilestones) { _, _ in triggerReschedule() }
        .onChange(of: globalEnabled) { _, enabled in
            if enabled {
                NotificationManager.shared.requestAuthorization { _ in }
            }
        }
    }

    private func triggerReschedule() {
        rescheduleTask?.cancel()
        rescheduleTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            let prefs = NotificationPreferences.fromDefaults()
            let lastActiveDay = UserDefaults.standard.string(forKey: AppStorageKeys.lastActiveDay) ?? ""
            let lastActive = DateFormatting.dayFormatter.date(from: lastActiveDay)

            NotificationManager.shared.rescheduleAll(
                prefs: prefs,
                allWords: store.words,
                lastActiveDate: lastActive
            )
        }
    }

    private var sampleWord: (word: String, transcription: String?, translation: String?) {
        if let word = store.words.first {
            return (word.word, word.transcription, word.translation)
        }
        return ("Hello", "/həˈloʊ/", "Привет")
    }

    private var previewBody: String {
        var parts: [String] = []
        if vocabShowTranscription, let t = sampleWord.transcription, !t.isEmpty {
            parts.append(t)
        }
        if vocabShowTranslation, let t = sampleWord.translation, !t.isEmpty {
            parts.append(t)
        }
        if parts.isEmpty {
            return "Do you remember what this means?"
        }
        return parts.joined(separator: " — ")
    }

    private var notificationPreview: some View {
        HStack(spacing: 12) {
            if let icon = appIconImage() {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("DROWORD")
                        .font(themeStore.bold(12))
                        .foregroundColor(themeStore.secondaryText)
                    Spacer()
                    Text("now")
                        .font(themeStore.regular(12))
                        .foregroundColor(themeStore.secondaryText)
                }

                Text(sampleWord.word)
                    .font(themeStore.bold(15))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(previewBody)
                    .font(themeStore.regular(14))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(themeStore.secondaryText.opacity(0.1), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: vocabShowTranscription)
        .animation(.easeInOut(duration: 0.2), value: vocabShowTranslation)
    }

    private func appIconImage() -> UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }

    private func toggleRow(icon: String, color: Color, title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(themeStore.regular(16))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(themeStore.mainAccentColor)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(themeStore.cardBg)
    }

    private func timePickerRow(icon: String, color: Color, title: LocalizedStringKey, date: Binding<Date>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(themeStore.regular(16))
                .foregroundColor(.primary)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(themeStore.mainAccentColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(themeStore.cardBg)
    }

    private func frequencyRow(value: Binding<Int>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeStore.iconBlue.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "number")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeStore.iconBlue)
            }
            Text("Per day")
                .font(themeStore.regular(16))
                .foregroundColor(.primary)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: 1...10)
                .font(themeStore.medium(16))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(themeStore.cardBg)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(themeStore.bold(18))
            .foregroundColor(.primary)
    }
}
