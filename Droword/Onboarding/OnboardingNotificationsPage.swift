import SwiftUI
import UserNotifications

struct NotificationPreferencesForm: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore

    var showsTitle: Bool = true
    var onboardingStyle: Bool = false
    var requestAuthOnAppear: Bool = true

    @AppStorage(AppStorageKeys.notifGlobalEnabled) private var globalEnabled: Bool = false
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
    @AppStorage(AppStorageKeys.notifEveningChatEnabled) private var eveningChatEnabled: Bool = true
    @AppStorage(AppStorageKeys.notifEveningChatHour) private var eveningChatHour: Int = 21
    @AppStorage(AppStorageKeys.notifEveningChatMinute) private var eveningChatMinute: Int = 0

    @State private var rescheduleTask: Task<Void, Never>?

    private var eveningChatDate: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: DateComponents(hour: eveningChatHour, minute: eveningChatMinute)) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                eveningChatHour = comps.hour ?? 21
                eveningChatMinute = comps.minute ?? 0
            }
        )
    }

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
        VStack(alignment: .leading, spacing: onboardingStyle ? 16 : 24) {
            if showsTitle {
                if onboardingStyle {
                    Text("Stay in the loop")
                        .zoomerTitle(32)
                        .environmentObject(themeStore)
                    Text("Turn on nudges so Droword can pull you back to your words.")
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                } else {
                    Text("Notifications")
                        .sheetTitle()
                }
            }

            VStack(spacing: 0) {
                toggleRow(
                    icon: "bell.fill",
                    title: "Enable notifications",
                    isOn: $globalEnabled
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))

            if globalEnabled {
                sectionHeader("Daily reminder")

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "sun.max.fill",
                        title: "Daily motivation",
                        isOn: $dailyReminderEnabled
                    )

                    if dailyReminderEnabled {
                        Divider().padding(.leading, 68)
                        timePickerRow(
                            icon: "clock.fill",
                            title: "Reminder time",
                            date: dailyReminderDate
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: dailyReminderEnabled)

                sectionHeader("Evening chat")

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "moon.stars.fill",
                        title: "One word at night",
                        isOn: $eveningChatEnabled
                    )

                    if eveningChatEnabled {
                        Divider().padding(.leading, 68)
                        timePickerRow(
                            icon: "clock.fill",
                            title: "Chat time",
                            date: eveningChatDate
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: eveningChatEnabled)

                Text("Tap it. Three lines with that word. Then stop.")
                    .font(themeStore.regular(12))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal, 8)

                sectionHeader("Vocabulary")

                if vocabEnabled {
                    notificationPreview
                }

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "character.book.closed.fill",
                        title: "Word notifications",
                        isOn: $vocabEnabled
                    )

                    if vocabEnabled {
                        Divider().padding(.leading, 68)
                        toggleRow(
                            icon: "textformat.abc",
                            title: "Show transcription",
                            isOn: $vocabShowTranscription
                        )
                        Divider().padding(.leading, 68)
                        toggleRow(
                            icon: "text.bubble.fill",
                            title: "Show translation",
                            isOn: $vocabShowTranslation
                        )
                        Divider().padding(.leading, 68)
                        toggleRow(
                            icon: "checkmark.seal.fill",
                            title: "Include mastered",
                            isOn: $vocabIncludeMastered
                        )
                        Divider().padding(.leading, 68)
                        frequencyRow(value: $vocabFrequency)
                        Divider().padding(.leading, 68)
                        timePickerRow(
                            icon: "sunrise.fill",
                            title: "From",
                            date: vocabStartDate
                        )
                        Divider().padding(.leading, 68)
                        timePickerRow(
                            icon: "sunset.fill",
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
                            .foregroundStyle(themeStore.mainAccentColor)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                        }

                        if store.words.isEmpty {
                            Text("Add words to receive vocabulary notifications")
                                .font(themeStore.regular(12))
                                .foregroundStyle(themeStore.secondaryText)
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: vocabEnabled)

                sectionHeader("Other")

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "flame.fill",
                        title: "Streak milestones",
                        isOn: $streakMilestones
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))

                Text("Get notified when you reach 7, 30, 100 and 365 day streaks.")
                    .font(themeStore.regular(12))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal, 8)

                if onboardingStyle {
                    Text("You can change these anytime in Settings.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: globalEnabled)
        .onChange(of: globalEnabled) { _, enabled in
            triggerReschedule()
            if enabled {
                NotificationManager.shared.requestAuthorization { _ in }
            }
        }
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
        .onChange(of: eveningChatEnabled) { _, _ in triggerReschedule() }
        .onChange(of: eveningChatHour) { _, _ in triggerReschedule() }
        .onChange(of: eveningChatMinute) { _, _ in triggerReschedule() }
        .onAppear {
            if requestAuthOnAppear, globalEnabled {
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

    private static let arigatouTranslations: [String: String] = [
        "English": "Thank you",
        "Español": "Gracias",
        "Русский": "Спасибо",
        "Français": "Merci",
        "Deutsch": "Danke",
        "Italiano": "Grazie",
        "Português": "Obrigado",
        "한국어": "감사합니다",
        "中文": "谢谢",
        "日本語": "Thank you",
        "العربية": "شكراً",
        "हिन्दी": "धन्यवाद",
    ]

    private var sampleWord: (word: String, transcription: String?, translation: String?) {
        if languageStore.nativeLanguage == "日本語" {
            return ("Thank you", "/θæŋk juː/", "ありがとう")
        }
        let translation = Self.arigatouTranslations[languageStore.nativeLanguage] ?? "Thank you"
        return ("ありがとう", "/aɾiɡatoː/", translation)
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
                        .foregroundStyle(themeStore.secondaryText)
                    Spacer()
                    Text("now")
                        .font(themeStore.regular(12))
                        .foregroundStyle(themeStore.secondaryText)
                }

                Text(sampleWord.word)
                    .font(themeStore.bold(15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(previewBody)
                    .font(themeStore.regular(14))
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
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

    private func toggleRow(icon: String, title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            Haptics.menuTap()
        } label: {
            HStack(spacing: 14) {
                MenuSymbol(systemName: icon)
                Text(title)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.mainText)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(themeStore.mainAccentColor)
                    .allowsHitTesting(false)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(themeStore.cardBg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func timePickerRow(icon: String, title: LocalizedStringKey, date: Binding<Date>) -> some View {
        HStack(spacing: 14) {
            MenuSymbol(systemName: icon)
            Text(title)
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(themeStore.mainAccentColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 18)
        .background(themeStore.cardBg)
    }

    private func frequencyRow(value: Binding<Int>) -> some View {
        HStack(spacing: 14) {
            MenuSymbol(systemName: "number")
            Text("Per day")
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.mainText)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: 1...10)
                .font(themeStore.medium(16))
                .foregroundStyle(themeStore.mainText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 18)
        .background(themeStore.cardBg)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(themeStore.bold(18))
            .foregroundStyle(.primary)
    }
}

struct OnboardingNotificationsPage: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stay in the loop")
                            .font(themeStore.bold(28))
                            .foregroundStyle(themeStore.mainText)
                        Text("Turn on nudges so Droword can pull you back to your words.")
                            .font(themeStore.regular(15))
                            .foregroundStyle(themeStore.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)

                    NotificationPreferencesForm(
                        showsTitle: false,
                        onboardingStyle: true,
                        requestAuthOnAppear: false
                    )
                }
                .padding(.top, 54)
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview("Form") {
    NotificationPreferencesForm(onboardingStyle: true, requestAuthOnAppear: false)
        .padding()
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}

#Preview("Onboarding") {
    OnboardingNotificationsPage()
        .environmentObject(ThemeStore())
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
}
