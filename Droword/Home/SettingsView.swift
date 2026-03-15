import SwiftUI
import PhotosUI
import UserNotifications
import UniformTypeIdentifiers

enum SettingsDestination: Hashable {
    case personalDetails
    case language
    case appearance
    case theme
    case voiceAndSpeech
    case notifications
    case dictionary
    case featureFlags
    case privacyPolicy
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
    @State private var devTapCount = 0
    @State private var showFeatureFlags = false


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
                            .onTapGesture(count: 5) {
                                showFeatureFlags.toggle()
                                Haptics.lightImpact()
                            }
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

                        if showFeatureFlags {
                            groupedSettingsSection([
                                SettingItem(icon: "flag.checkered", color: Color.mainBlack, title: "Feature Flags", value: nil)
                            ]) { item in
                                path.append(SettingsDestination.featureFlags)
                            }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "book.closed.fill", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentBlue, title: "Dictionary")
                        ]) { _ in
                            path.append(SettingsDestination.dictionary)
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "hand.raised.fill", color: themeStore.isMonochrome ? themeStore.monoDark : .gray, title: "Privacy Policy")
                        ]) { _ in
                            path.append(SettingsDestination.privacyPolicy)
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
                case .dictionary:
                    DictionarySettingsView()
                        .environmentObject(store)
                        .environmentObject(languageStore)
                case .featureFlags:
                    FeatureFlagsView()
                case .privacyPolicy:
                    PrivacyPolicyView()
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
        .onAppear {
            avatarImage = loadAvatarFromDisk()
        }
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

struct DictionarySettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var csvFileURL: URL?
    @State private var showImportPicker = false
    @State private var importedCount: Int?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dictionary")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 0) {
                    settingsRow(icon: "square.and.arrow.up", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentBlue, title: "Export Dictionary") {
                        exportCSV()
                    }
                    settingsRow(icon: "square.and.arrow.down", color: themeStore.isMonochrome ? themeStore.monoDark : themeStore.accentGreen, title: "Import Dictionary") {
                        showImportPicker = true
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 0) {
                    settingsRow(icon: "trash.fill", color: .red, title: "Clear All Words") {
                        store.clear()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Words in dictionary: \(store.words.count)")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.mainGrey)
                    Text("Total words added: \(store.totalWordsAdded)")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.mainGrey)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
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
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importCSV(from: url)
            }
        }
        .alert("Import Complete", isPresented: .init(
            get: { importedCount != nil },
            set: { if !$0 { importedCount = nil } }
        )) {
            Button("OK") { importedCount = nil }
        } message: {
            if let count = importedCount {
                Text("\(count) word\(count == 1 ? "" : "s") imported successfully.")
            }
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
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
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(title == "Clear All Words" ? .red : .primary)

                Spacer()

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

    private func exportCSV() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var csv = "Word,Translation,Type,Tag,Comment,Example,Explanation,Breakdown,Transcription,From Language,To Language,Date Added\n"
        for w in store.words {
            let fields: [String] = [
                csvEscape(w.word),
                csvEscape(w.translation ?? ""),
                csvEscape(w.type),
                csvEscape(w.tag ?? ""),
                csvEscape(w.comment ?? ""),
                csvEscape(w.example ?? ""),
                csvEscape(w.explanation ?? ""),
                csvEscape(w.breakdown ?? ""),
                csvEscape(w.transcription ?? ""),
                csvEscape(w.fromLanguage),
                csvEscape(w.toLanguage),
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

    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let rows = parseCSVRows(content)
        guard rows.count > 1 else { return }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        let colWord = header.firstIndex(of: "word")
        let colTranslation = header.firstIndex(of: "translation")
        let colType = header.firstIndex(of: "type")
        let colTag = header.firstIndex(of: "tag")
        let colComment = header.firstIndex(of: "comment")
        let colExample = header.firstIndex(of: "example")
        let colExplanation = header.firstIndex(of: "explanation")
        let colBreakdown = header.firstIndex(of: "breakdown")
        let colTranscription = header.firstIndex(of: "transcription")
        let colFromLang = header.firstIndex(of: "from language")
        let colToLang = header.firstIndex(of: "to language")
        let colDate = header.firstIndex(of: "date added")

        guard let colWord else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let existingWords = Set(store.words.map { $0.word.lowercased() })
        var count = 0

        func field(at col: Int?, in row: [String]) -> String? {
            guard let col, col < row.count else { return nil }
            let value = row[col].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }

        for row in rows.dropFirst() {
            guard row.count > colWord else { continue }
            let wordText = row[colWord].trimmingCharacters(in: .whitespaces)
            guard !wordText.isEmpty else { continue }
            guard !existingWords.contains(wordText.lowercased()) else { continue }

            let date: Date = {
                if let ci = colDate, ci < row.count {
                    return df.date(from: row[ci].trimmingCharacters(in: .whitespaces)) ?? Date()
                }
                return Date()
            }()

            let newWord = StoredWord(
                word: wordText,
                type: field(at: colType, in: row) ?? "word",
                translation: field(at: colTranslation, in: row),
                example: field(at: colExample, in: row),
                explanation: field(at: colExplanation, in: row),
                breakdown: field(at: colBreakdown, in: row),
                transcription: field(at: colTranscription, in: row),
                comment: field(at: colComment, in: row),
                tag: field(at: colTag, in: row),
                dateAdded: date,
                fromLanguage: field(at: colFromLang, in: row) ?? languageStore.nativeLanguage,
                toLanguage: field(at: colToLang, in: row) ?? languageStore.learningLanguage
            )
            store.add(newWord)
            count += 1
        }

        importedCount = count
    }

    private func parseCSVRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let ch = text[i]

            if inQuotes {
                if ch == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex && text[next] == "\"" {
                        currentField.append("\"")
                        i = text.index(after: next)
                    } else {
                        inQuotes = false
                        i = text.index(after: i)
                    }
                } else {
                    currentField.append(ch)
                    i = text.index(after: i)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                    i = text.index(after: i)
                } else if ch == "," {
                    currentRow.append(currentField)
                    currentField = ""
                    i = text.index(after: i)
                } else if ch == "\r" || ch == "\n" {
                    if ch == "\r" {
                        let next = text.index(after: i)
                        if next < text.endIndex && text[next] == "\n" {
                            i = text.index(after: next)
                        } else {
                            i = text.index(after: i)
                        }
                    } else {
                        i = text.index(after: i)
                    }
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(ch)
                    i = text.index(after: i)
                }
            }
        }

        currentRow.append(currentField)
        if !currentRow.allSatisfy({ $0.isEmpty }) {
            rows.append(currentRow)
        }

        return rows
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

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                Group {
                    policySection(
                        title: "Data Storage",
                        body: "All your data — words, progress, settings and preferences — is stored locally on your device. Droword does not collect, transmit or store any personal data on external servers."
                    )

                    policySection(
                        title: "AI Translation",
                        body: "When you add or translate a word, the text is sent to a third-party AI service (Anthropic Claude) to generate translations, explanations and examples. No personal information is included in these requests."
                    )

                    policySection(
                        title: "Text-to-Speech",
                        body: "Audio pronunciation is generated using the OpenAI Text-to-Speech API. Only the word or phrase text is sent — no personal data is transmitted."
                    )

                    policySection(
                        title: "Photos & Camera",
                        body: "If you choose to set a profile photo, the image is stored only on your device. Droword does not upload your photos anywhere."
                    )

                    policySection(
                        title: "Notifications",
                        body: "Droword may send local notifications to remind you to practice. These are scheduled entirely on your device and do not involve any external service."
                    )

                    policySection(
                        title: "Analytics & Tracking",
                        body: "Droword does not use any analytics, tracking or advertising SDKs. Your usage data stays on your device."
                    )

                    policySection(
                        title: "Data Deletion",
                        body: "You can delete all your data at any time from Settings → Dictionary → Clear All Words. Removing the app from your device deletes all stored data permanently."
                    )

                    policySection(
                        title: "Contact",
                        body: "If you have questions about this privacy policy, please reach out via the App Store support link."
                    )
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
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Poppins-Medium", size: 17))
                .foregroundColor(.primary)
            Text(body)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardBackground))
    }
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

