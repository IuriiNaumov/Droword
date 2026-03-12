import SwiftUI
import PhotosUI
import UserNotifications

enum SettingsDestination: Hashable {
    case personalDetails
    case language
    case appearance
    case theme
    case voiceAndSpeech
    case notifications
    case featureFlags
}

struct SettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage("ttsVoice") private var ttsVoice: String = "coral"
    @AppStorage("ttsRate") private var ttsRate: Double = 1.0
    @AppStorage("userName") private var storedUserName: String = ""
    @AppStorage("featureFlagShowOnboarding") private var featureFlagShowOnboarding: Bool = false

    @State private var avatarImage: UIImage?
    @State private var showAvatarPicker = false
    @State private var path = NavigationPath()
    @State private var csvFileURL: URL?

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    private var appearanceTitle: String {
        appearance.title
    }

    private var displayName: String {
        storedUserName.isEmpty ? "User" : storedUserName
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        ZStack {
                            if let avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.mainBlack.opacity(0.1), lineWidth: 1))
                                    
                            } else {
                                Circle()
                                    .fill(Color.mainGrey.opacity(0.15))
                                    .frame(width: 92, height: 92)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40, weight: .medium))
                                            .foregroundColor(Color.mainBlack.opacity(0.7))
                                    )
                                    
                            }

                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.mainBlack.opacity(0.6))
                                        .clipShape(Circle())
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .frame(width: 92, height: 92)

                            VStack {
                                Spacer()
                                HStack {
                                    Button {
                                        deleteAvatarFromDisk()
                                        avatarImage = nil
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.mainBlack.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .opacity(avatarImage == nil ? 0.0 : 1.0)
                                    Spacer()
                                }
                            }
                            .frame(width: 92, height: 92)
                            .offset(x: -4, y: 4)
                        }
                        .onTapGesture { Haptics.lightImpact(); showAvatarPicker = true }

                        Text(displayName)
                            .font(.custom("Poppins-Bold", size: 22))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 20) {
                        groupedSettingsSection([
                            SettingItem(icon: "person.circle", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentGreen, title: "Personal details"),
                        ]) { item in
                            if item.title == "Personal details" { path.append(SettingsDestination.personalDetails) }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "moon.fill", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentGold, title: "Appearance", value: appearanceTitle),
                            SettingItem(icon: "paintpalette.fill", color: themeStore.isMonochrome ? themeStore.monoDark : .mainBlack, title: "Theme", value: themeStore.title),
                            SettingItem(icon: "textformat.size", color: themeStore.isMonochrome ? themeStore.monoDark : .yellow, title: "Language", value: languageStore.learningLanguage),
                            SettingItem(icon: "bell.badge.fill", color: themeStore.isMonochrome ? themeStore.monoDark : .pink, title: "Notifications"),
                            SettingItem(icon: "mic.fill", color: themeStore.isMonochrome ? themeStore.monoDark : .blue, title: "Voice & Speech")
                        ]) { item in
                            if item.title == "Language" { path.append(SettingsDestination.language) }
                            if item.title == "Appearance" { path.append(SettingsDestination.appearance) }
                            if item.title == "Theme" { path.append(SettingsDestination.theme) }
                            if item.title == "Notifications" { path.append(SettingsDestination.notifications) }
                            if item.title == "Voice & Speech" { path.append(SettingsDestination.voiceAndSpeech) }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "flag.checkered", color: Color.mainBlack, title: "Feature Flags", value: nil)
                        ]) { item in
                            path.append(SettingsDestination.featureFlags)
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "square.and.arrow.up", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentBlue, title: "Export Dictionary")
                        ]) { _ in
                            exportCSV()
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .personalDetails:
                    PersonalDetailsView()
                case .language:
                    LanguageSelectionView()
                        .environmentObject(languageStore)
                case .appearance:
                    AppearancePickerView()
                case .theme:
                    ThemePickerView()
                        .environmentObject(themeStore)
                case .voiceAndSpeech:
                    VoiceAndSpeechSettingsView()
                case .notifications:
                    NotificationSettingsView()
                case .featureFlags:
                    FeatureFlagsView()
                }
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView(currentImage: avatarImage) { newImage in
                if let newImage {
                    avatarImage = newImage
                    saveAvatarToDisk(newImage)
                } else {
                    avatarImage = nil
                    deleteAvatarFromDisk()
                }
            }
        }
        .onChange(of: csvFileURL) { _, newURL in
            guard let url = newURL else { return }
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                var topVC = root
                while let presented = topVC.presentedViewController { topVC = presented }
                if let popover = av.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(av, animated: true)
            }
            csvFileURL = nil
        }
        .onAppear {
            avatarImage = loadAvatarFromDisk()
        }
    }

    private func exportCSV() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var csv = "Word,Translation,Type,Tag,Comment,Example,Date Added\n"
        for w in store.words {
            let fields: [String] = [
                csvEscape(w.word),
                csvEscape(w.translation ?? ""),
                csvEscape(w.type),
                csvEscape(w.tag ?? ""),
                csvEscape(w.comment ?? ""),
                csvEscape(w.example ?? ""),
                df.string(from: w.dateAdded)
            ]
            csv += fields.joined(separator: ",") + "\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Droword_Dictionary.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            csvFileURL = fileURL
        } catch {
            print("Failed to write CSV:", error.localizedDescription)
        }
    }

    private func csvEscape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        if needsQuoting {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private func groupedSettingsSection(
        _ items: [SettingItem],
        onTap: ((SettingItem) -> Void)? = nil
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    Haptics.selection()
                    onTap?(item)
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(item.color)
                        }

                        Text(item.title)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        if let value = item.value {
                            Text(value)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.mainGrey)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.mainGrey.opacity(0.6))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(Color.cardBackground)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func saveAvatarToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let url = avatarFileURL()
        do {
            try data.write(to: url)
            NotificationCenter.default.post(name: .avatarDidChange, object: nil)
        } catch {
            print("⚠️ Failed to save avatar:", error.localizedDescription)
        }
    }

    private func loadAvatarFromDisk() -> UIImage? {
        let url = avatarFileURL()
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    private func deleteAvatarFromDisk() {
        let url = avatarFileURL()
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                NotificationCenter.default.post(name: .avatarDidChange, object: nil)
            }
        } catch {
            print("⚠️ Failed to delete avatar:", error.localizedDescription)
        }
    }

    private func avatarFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("user_avatar.jpg")
    }

}

private struct SettingsBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

struct VoiceAndSpeechSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ttsVoice") private var ttsVoice: String = "coral"
    @AppStorage("ttsRate") private var ttsRate: Double = 1.0

    private let speedOptions: [Double] = [0.75, 0.9, 1.0, 1.25, 1.5]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Voice & Speech")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Voice")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                VoicePickerView(
                    selectedKey: $ttsVoice,
                    options: [
                        VoiceOption(key: "coral", title: "Coral", description: "soft, neutral"),
                        VoiceOption(key: "alloy", title: "Alloy", description: "friendly, warm"),
                        VoiceOption(key: "verse", title: "Verse", description: "energetic, expressive"),
                        VoiceOption(key: "sage", title: "Sage", description: "calm, confident")
                    ]
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Speed")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(speedOptions, id: \.self) { option in
                            RadioButtonRow(
                                title: String(format: "%.2fx", option),
                                isSelected: ttsRate == option
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) { ttsRate = option }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
    }
}

private struct RadioButtonRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.mainGrey.opacity(0.4), lineWidth: 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentBlack)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(title)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FeatureFlagsView: View {
    @AppStorage("featureFlagShowOnboarding") private var featureFlagShowOnboarding: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Show onboarding")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle("", isOn: $featureFlagShowOnboarding)
                        .labelsHidden()
                        .tint(Color.accentBlack)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.cardBackground))
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct NotificationSettingsView: View {
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
                            Text("Morning & evening practice nudges")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $dailyReminders)
                            .labelsHidden()
                            .tint(Color.accentBlack)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardBackground))

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
                            .tint(Color.accentBlack)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardBackground))
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .onChange(of: dailyReminders) { _, enabled in
            if enabled {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        NotificationManager.shared.scheduleTwiceDaily()
                    }
                }
            } else {
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [
                    "daily.reminder.morning",
                    "daily.reminder.evening"
                ])
            }
        }
    }
}

struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    var value: String? = nil
}

#Preview {
    SettingsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
}

#Preview("Light") {
    SettingsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .environmentObject(ThemeStore())
        .preferredColorScheme(.dark)
}

