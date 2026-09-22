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
    @State private var pendingCropImage: UIImage?
    @State private var croppable: CroppableImage?
    @State private var showPersonalDetailsSheet = false
    @State private var path = NavigationPath()
    @State private var showOnboarding = false
    #if DEBUG
    @State private var devTapCount = 0
    @State private var showFeatureFlags = false
    #endif

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .system
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
                VStack(spacing: DesignSpacing.section + 4) {
                    VStack(spacing: 12) {
                        ZStack {
                            if let avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())

                            } else {
                                Circle()
                                    .fill(themeStore.secondaryText.opacity(0.15))
                                    .frame(width: 92, height: 92)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40, weight: .medium))
                                            .foregroundStyle(themeStore.mainText.opacity(0.7))
                                    )

                            }

                        }
                        .onTapGesture { Haptics.menuTap(); showAvatarPicker = true }
                        .accessibilityLabel(Text("Profile photo"))
                        .accessibilityHint(Text("Tap to change your photo"))

                        Text(displayName)
                            .font(themeStore.bold(22))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            #if DEBUG
                            .onTapGesture(count: 5) {
                                showFeatureFlags.toggle()
                                Haptics.menuTap()
                            }
                            #endif

                        Text("\(usageDurationString()) with Droword")
                            .font(themeStore.regular(14))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                    .padding(.top, 32)

                    premiumBanner
                        .padding(.horizontal, 20)

                    VStack(spacing: 20) {
                        groupedSettingsSection([
                            SettingItem(icon: "person", title: "Personal details"),
                        ]) { item in
                            if item.icon == "person" {
                                showPersonalDetailsSheet = true
                            }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "textformat.size", title: "Language Pair", value: languageStore.learningLanguage),
                            SettingItem(icon: "paintbrush", title: "App customization", showProBadge: !isPremium),
                            SettingItem(icon: "bell", title: "Notifications"),
                            SettingItem(icon: "mic", title: "Voice & Speech"),
                            SettingItem(icon: "hand.tap", title: "Haptics"),
                            SettingItem(icon: "trophy", title: "Achievements")
                        ]) { item in
                            if item.title == "Language Pair" { path.append(SettingsDestination.language) }
                            if item.title == "App customization" { path.append(SettingsDestination.appCustomization) }
                            if item.title == "Notifications" { path.append(SettingsDestination.notifications) }
                            if item.title == "Voice & Speech" { path.append(SettingsDestination.voiceAndSpeech) }
                            if item.title == "Haptics" { path.append(SettingsDestination.haptics) }
                            if item.title == "Achievements" { path.append(SettingsDestination.achievements) }
                        }

                        #if DEBUG
                        if showFeatureFlags {
                            groupedSettingsSection([
                                SettingItem(icon: "flag", title: "Feature Flags", value: nil)
                            ]) { item in
                                path.append(SettingsDestination.featureFlags)
                            }
                        }
                        #endif

                        groupedSettingsSection([
                            SettingItem(icon: "globe", title: "App Language")
                        ]) { _ in
                            openAppLanguageSettings()
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "book.closed", title: "Dictionary")
                        ]) { _ in
                            path.append(SettingsDestination.dictionary)
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "play.circle", title: "App Tour"),
                            SettingItem(icon: "sparkles", title: "What's New")
                        ]) { item in
                            if item.title == "App Tour" { showOnboarding = true }
                            if item.title == "What's New" { path.append(SettingsDestination.whatsNew) }
                        }

                        groupedSettingsSection([
                            SettingItem(icon: "hand.raised", title: "Privacy Policy", destination: .privacyPolicy),
                            SettingItem(icon: "doc.text", title: "Terms of Use", destination: .termsOfUse)
                        ]) { item in
                            if let destination = item.destination {
                                path.append(destination)
                            }
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
                    CloseButton()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .language:
                    LanguageSelectionView()
                        .environmentObject(languageStore)
                case .learningPreferences:
                    LearningPreferencesView()
                case .voiceAndSpeech:
                    VoiceAndSpeechSettingsView()
                case .haptics:
                    HapticSettingsView()
                case .notifications:
                    NotificationSettingsView()
                        .environmentObject(store)
                case .dictionary:
                    DictionarySettingsView()
                        .environmentObject(store)
                        .environmentObject(languageStore)
                case .featureFlags:
                    FeatureFlagsView()
                        .environmentObject(store)
                        .environmentObject(languageStore)
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfUse:
                    TermsOfUseView()
                case .achievements:
                    AchievementsView()
                case .theme:
                    ThemePickerView()
                case .appIcon:
                    AppIconPickerView()
                case .fontSize:
                    FontSizePickerView()
                case .appearance:
                    AppearancePickerView()
                case .seasonalEffects:
                    SeasonalEffectsSettingsView()
                case .appCustomization:
                    AppCustomizationView()
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
        .sheet(isPresented: $showAvatarPicker, onDismiss: {
            guard let image = pendingCropImage else { return }
            pendingCropImage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                croppable = CroppableImage(image: image)
            }
        }) {
            AvatarPickerView(
                currentImage: avatarImage,
                onPickedRaw: { image in
                    pendingCropImage = image
                },
                onRemoved: {
                    avatarImage = nil
                    deleteAvatarFromDisk()
                }
            )
            .environmentObject(themeStore)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DesignRadius.dialog)
            .preferredColorScheme(appearance.colorScheme)
        }
        .fullScreenCover(item: $croppable) { item in
            ImageCropperView(
                image: item.image,
                onCrop: { cropped in
                    avatarImage = cropped
                    saveAvatarToDisk(cropped)
                    croppable = nil
                },
                onCancel: {
                    croppable = nil
                }
            )
            .environmentObject(themeStore)
        }
        .sheet(isPresented: $showPersonalDetailsSheet) {
            PersonalDetailsView()
                .environmentObject(themeStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(DesignRadius.dialog)
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
            path.append(SettingsDestination.premium)
        } label: {
            HStack(spacing: 14) {
                MenuSymbol(
                    systemName: "sparkles",
                    color: themeStore.accentBlue,
                    size: 22,
                    weight: .medium
                )

                VStack(alignment: .leading, spacing: 2) {
                    if let days = trialDaysRemaining, isPremium {
                        Text("PRO Trial")
                            .font(themeStore.bold(16))
                            .foregroundStyle(themeStore.mainText)
                        Text("\(days) days remaining", comment: "PRO trial days remaining in settings")
                            .font(themeStore.regular(12))
                            .foregroundStyle(themeStore.accentGold)
                    } else {
                        Text(isPremium ? LocalizedStringKey("PRO Active") : LocalizedStringKey("Get Droword PRO"))
                            .font(themeStore.bold(16))
                            .foregroundStyle(themeStore.mainText)
                        Text(isPremium ? LocalizedStringKey("Unlimited access") : LocalizedStringKey("Unlock unlimited AI features"))
                            .font(themeStore.regular(12))
                            .foregroundStyle(themeStore.secondaryText)
                    }
                }

                Spacer()

                if !isPremium {
                    Text("Upgrade")
                        .font(themeStore.bold(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(themeStore.accentBlue))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(themeStore.accentBlue)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.accentBlueSoft)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    private func groupedSettingsSection(
        _ items: [SettingItem],
        onTap: ((SettingItem) -> Void)? = nil
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    Haptics.menuTap()
                    onTap?(item)
                } label: {
                    HStack(spacing: 14) {
                        MenuSymbol(systemName: item.icon)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(item.title)
                                .font(themeStore.regular(17))
                                .foregroundStyle(themeStore.mainText)

                            if item.showProBadge {
                                ProPillBadge()
                                    .environmentObject(themeStore)
                            }
                        }

                        Spacer()

                        if let value = item.value {
                            Text(value)
                                .font(themeStore.regular(15))
                                .foregroundStyle(themeStore.secondaryText)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeStore.secondaryText.opacity(0.45))
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.99))

                if index < items.count - 1 {
                    Rectangle()
                        .fill(themeStore.dividerColor.opacity(0.4))
                        .frame(height: 1)
                        .padding(.leading, 60)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 28))
        .padding(.horizontal, 16)
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
                let y = String(localized: "\(years) years")
                let m = String(localized: "\(months) months")
                return "\(y) \(m)"
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
