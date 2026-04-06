import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppStorageKeys.appAppearance) private var storedAppearance: String = AppAppearance.system.rawValue
    @AppStorage(AppStorageKeys.ttsVoice) private var ttsVoice: String = "coral"
    @AppStorage(AppStorageKeys.ttsRate) private var ttsRate: Double = 1.0
    @AppStorage(AppStorageKeys.userName) private var storedUserName: String = ""
    @AppStorage(AppStorageKeys.firstUseDate) private var firstUseDate: String = ""
    @AppStorage(AppStorageKeys.seasonalEffectsEnabled) private var seasonalEffectsEnabled: Bool = false
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppStorageKeys.hasUsedTrial) private var hasUsedTrial: Bool = false
    @AppStorage(AppStorageKeys.trialStartDate) private var trialStartDate: String = ""
    @State private var avatarImage: UIImage?
    @State private var showAvatarPicker = false
    @State private var showAppearanceSheet = false
    @State private var showPersonalDetailsSheet = false
    
    @State private var showFontSizeSheet = false
    @State private var path = NavigationPath()
    @State private var showOnboarding = false
    #if DEBUG
    @State private var devTapCount = 0
    @State private var showFeatureFlags = false
    #endif


    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
    }

    private var appearanceTitle: String {
        appearance.title
    }

    private var displayName: String {
        storedUserName.isEmpty ? "User" : storedUserName
    }

    private var trialDaysRemaining: Int? {
        guard hasUsedTrial, !trialStartDate.isEmpty,
              let start = DateFormatting.dayFormatter.date(from: trialStartDate) else { return nil }
        let daysPassed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let remaining = 7 - daysPassed
        return remaining > 0 ? remaining : nil
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
                                    .overlay(Circle().stroke(themeStore.mainText.opacity(0.1), lineWidth: 1))
                                    
                            } else {
                                Circle()
                                    .fill(themeStore.secondaryText.opacity(0.15))
                                    .frame(width: 92, height: 92)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40, weight: .medium))
                                            .foregroundColor(themeStore.mainText.opacity(0.7))
                                    )
                                    
                            }


                        }
                        .onTapGesture { Haptics.lightImpact(); showAvatarPicker = true }
                        .accessibilityLabel(Text("Profile photo"))
                        .accessibilityHint(Text("Tap to change your photo"))

                        Text(displayName)
                            .font(themeStore.bold(22))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            #if DEBUG
                            .onTapGesture(count: 5) {
                                showFeatureFlags.toggle()
                                Haptics.lightImpact()
                            }
                            #endif

                        Text("\(usageDurationString()) with Droword")
                            .font(themeStore.regular(14))
                            .foregroundColor(themeStore.secondaryText)
                    }
                    .padding(.top, 32)

                    premiumBanner
                        .padding(.horizontal, 20)

                    VStack(spacing: 20) {
                        groupedSettingsSection([
                            SettingItem(icon: "person.circle", color: themeStore.iconGreen, title: "Personal details"),
                        ]) { item in
                            if item.title == "Personal details" { showPersonalDetailsSheet = true }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "moon.fill", color: themeStore.monoDark, title: "Appearance", value: appearanceTitle),
                            SettingItem(icon: "textformat.size.larger", color: themeStore.accentGold, title: "Font Size", value: themeStore.fontScaleLabel),
                            SettingItem(icon: "textformat.size", color: themeStore.iconGreen, title: "Language Pair", value: languageStore.learningLanguage),
                            SettingItem(icon: "globe", color: themeStore.accentBlue, title: "App Language"),
                            SettingItem(icon: "bell.badge.fill", color: themeStore.iconPink, title: "Notifications"),
                            SettingItem(icon: "mic.fill", color: themeStore.iconBlue, title: "Voice & Speech"),
                            SettingItem(icon: "trophy.fill", color: themeStore.iconGold, title: "Achievements")
                        ]) { item in
                            if item.title == "Language Pair" { path.append(SettingsDestination.language) }
                            if item.title == "App Language" { openAppLanguageSettings() }
                            if item.title == "Appearance" { showAppearanceSheet = true }
                            if item.title == "Font Size" { showFontSizeSheet = true }
                            if item.title == "Notifications" { path.append(SettingsDestination.notifications) }
                            if item.title == "Voice & Speech" { path.append(SettingsDestination.voiceAndSpeech) }
                            if item.title == "Achievements" { path.append(SettingsDestination.achievements) }
                        }

                        #if DEBUG
                        if showFeatureFlags {
                            groupedSettingsSection([
                                SettingItem(icon: "flag.checkered", color: themeStore.mainText, title: "Feature Flags", value: nil)
                            ]) { item in
                                path.append(SettingsDestination.featureFlags)
                            }
                        }
                        #endif

                        groupedSettingsSection([
                            SettingItem(icon: "paintpalette.fill", color: themeStore.iconPurple, title: "Theme", value: themeStore.title, showProBadge: !isPremium),
                            SettingItem(icon: "sparkles", color: themeStore.iconPink, title: "Seasonal effects", value: seasonalEffectsEnabled ? "On" : "Off", showProBadge: !isPremium)
                        ]) { item in
                            if item.title == "Theme" { path.append(SettingsDestination.theme) }
                            if item.title == "Seasonal effects" { path.append(SettingsDestination.seasonalEffects) }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "book.closed.fill", color: themeStore.iconBlue, title: "Dictionary")
                        ]) { _ in
                            path.append(SettingsDestination.dictionary)
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "play.circle.fill", color: themeStore.accentBlue, title: "App Tour"),
                            SettingItem(icon: "sparkles.rectangle.stack.fill", color: themeStore.accentGold, title: "What's New")
                        ]) { item in
                            if item.title == "App Tour" { showOnboarding = true }
                            if item.title == "What's New" { path.append(SettingsDestination.whatsNew) }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "hand.raised.fill", color: themeStore.isMonochrome ? themeStore.monoDark : Color.gray, title: "Privacy Policy")
                        ]) { _ in
                            path.append(SettingsDestination.privacyPolicy)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 40)
                .iPadContentWidth(600)
            }
            .background(themeStore.appBg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                    .accessibilityLabel(Text("Close settings"))
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .language:
                    LanguageSelectionView()
                        .environmentObject(languageStore)
                case .voiceAndSpeech:
                    VoiceAndSpeechSettingsView()
                case .notifications:
                    NotificationSettingsView()
                        .environmentObject(store)
                case .dictionary:
                    DictionarySettingsView()
                        .environmentObject(store)
                        .environmentObject(languageStore)
                case .featureFlags:
                    FeatureFlagsView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .achievements:
                    AchievementsView()
                case .theme:
                    ThemePickerView()
                case .seasonalEffects:
                    SeasonalEffectsSettingsView()
                case .premium:
                    PremiumView()
                case .whatsNew:
                    WhatsNewView()
                default:
                    EmptyView()
                }
            }
        }
        .tint(themeStore.mainAccentColor)
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
            .presentationDetents([.medium])
            .preferredColorScheme(appearance.colorScheme)
        }
        .sheet(isPresented: $showPersonalDetailsSheet) {
            PersonalDetailsView()
                .environmentObject(themeStore)
                .presentationDetents([.medium])
                .preferredColorScheme(appearance.colorScheme)
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerView()
                .environmentObject(themeStore)
                .presentationDetents([.medium])
                .preferredColorScheme(appearance.colorScheme)
        }
        .sheet(isPresented: $showFontSizeSheet) {
            FontSizePickerView()
                .environmentObject(themeStore)
                .presentationDetents([.medium])
                .preferredColorScheme(appearance.colorScheme)
        }
        
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingReplayView()
                .environmentObject(themeStore)
        }
        .onAppear {
            avatarImage = loadAvatarFromDisk()
        }
    }

    private var premiumBanner: some View {
        Button {
            Haptics.selection()
            path.append(SettingsDestination.premium)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(themeStore.accentBlue)

                VStack(alignment: .leading, spacing: 2) {
                    if let days = trialDaysRemaining, isPremium {
                        Text("PRO Trial")
                            .font(themeStore.bold(16))
                            .foregroundColor(themeStore.mainText)
                        Text("\(days) days remaining", comment: "PRO trial days remaining in settings")
                            .font(themeStore.regular(12))
                            .foregroundColor(.orange)
                    } else {
                        Text(isPremium ? LocalizedStringKey("PRO Active") : LocalizedStringKey("Get Droword PRO"))
                            .font(themeStore.bold(16))
                            .foregroundColor(themeStore.mainText)
                        Text(isPremium ? LocalizedStringKey("Unlimited access") : LocalizedStringKey("Unlock unlimited AI features"))
                            .font(themeStore.regular(12))
                            .foregroundColor(themeStore.secondaryText)
                    }
                }

                Spacer()

                if !isPremium {
                    Text("Upgrade")
                        .font(themeStore.bold(13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(themeStore.accentBlue))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(themeStore.accentBlue)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.accentBlueSoft)
            )
        }
        .buttonStyle(Duo3DButtonStyle())
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

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(item.title)
                                .font(themeStore.regular(16))
                                .foregroundColor(.primary)

                            if item.showProBadge {
                                Text("PRO")
                                    .font(themeStore.bold(9))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(themeStore.accentBlue))
                            }
                        }

                        Spacer()

                        if let value = item.value {
                            Text(value)
                                .font(themeStore.regular(14))
                                .foregroundColor(themeStore.secondaryText)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeStore.accentBlue)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(themeStore.cardBg)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func openAppLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func usageDurationString() -> String {
        let df = DateFormatting.dayFormatter
        guard let start = df.date(from: firstUseDate), let end = df.date(from: df.string(from: Date())) else {
            return String(localized: "\(0) days")
        }
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: start, to: end)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)

        if years >= 1 {
            if months > 0 {
                return String(localized: "\(years) years \(months) months")
            } else {
                return String(localized: "\(years) years")
            }
        } else if months >= 1 {
            return String(localized: "\(months) months")
        } else {
            return String(localized: "\(days + 1) days")
        }
    }

    private func saveAvatarToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let url = avatarFileURL()
        do {
            try data.write(to: url)
            NotificationCenter.default.post(name: .avatarDidChange, object: nil)
        } catch {
            #if DEBUG
            print("⚠️ Failed to save avatar:", error.localizedDescription)
            #endif
        }
    }

    private func loadAvatarFromDisk() -> UIImage? {
        let url = avatarFileURL()
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        let targetSize = CGSize(width: 184, height: 184)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func deleteAvatarFromDisk() {
        let url = avatarFileURL()
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                NotificationCenter.default.post(name: .avatarDidChange, object: nil)
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to delete avatar:", error.localizedDescription)
            #endif
        }
    }

    private func avatarFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("user_avatar.jpg")
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
