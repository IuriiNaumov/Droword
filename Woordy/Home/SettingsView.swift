import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore

    @AppStorage("appAppearance") private var storedAppearance: String = AppAppearance.light.rawValue
    @AppStorage("ttsVoice") private var ttsVoice: String = "coral"
    @AppStorage("ttsRate") private var ttsRate: Double = 1.0

    @State private var avatarImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showLanguagePicker = false
    @State private var showAppearancePicker = false
    @State private var showVoiceSheet = false

    private var appearance: AppAppearance {
        AppAppearance(rawValue: storedAppearance) ?? .light
    }

    private var appearanceTitle: String {
        appearance.title
    }

    var body: some View {
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
                                .overlay(Circle().stroke(Color.mainBlack.opacity(0.1), lineWidth: 3))
                                .shadow(color: Color.mainBlack.opacity(0.1), radius: 6, y: 3)
                        } else {
                            Circle()
                                .fill(Color.mainGrey.opacity(0.15))
                                .frame(width: 92, height: 92)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(Color.mainBlack.opacity(0.7))
                                )
                                .shadow(color: Color.mainBlack.opacity(0.1), radius: 5, y: 2)
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
                    .onTapGesture { showPhotoPicker = true }

                    Text("Yura")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.mainBlack)
                }
                .padding(.top, 32)

                VStack(spacing: 20) {
                    groupedSettingsSection([
                        SettingItem(icon: "person.circle", color: Color("MainGreen"), title: "Personal details"),
                    ])

                    groupedSettingsSection([
                        SettingItem(icon: "moon.fill", color: .accentGold, title: "Appearance", value: appearanceTitle),
                        SettingItem(icon: "textformat.size", color: .yellow, title: "Language", value: languageStore.learningLanguage),
                        SettingItem(icon: "bell.badge.fill", color: .pink, title: "Notifications"),
                        SettingItem(icon: "mic.fill", color: .blue, title: "Voice & Speech")
                    ]) { item in
                        if item.title == "Language" { showLanguagePicker = true }
                        if item.title == "Appearance" { showAppearancePicker = true }
                        if item.title == "Voice & Speech" { showVoiceSheet = true }
                    }
                }

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(appearance.colorScheme)
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionView()
                .environmentObject(languageStore)
        }
        .sheet(isPresented: $showAppearancePicker) {
            AppearancePickerView()
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.appBackground)
                .preferredColorScheme(appearance.colorScheme)
                .id(storedAppearance)
        }
        .sheet(isPresented: $showVoiceSheet) {
            VoiceAndSpeechSettingsView()
                .preferredColorScheme(appearance.colorScheme)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .background(Color.appBackground.ignoresSafeArea())
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = uiImage
                    saveAvatarToDisk(uiImage)
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
                            .foregroundColor(.mainBlack)

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
        .cornerRadius(18)
        .padding(.horizontal)
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

    private struct VoiceAndSpeechSettingsView: View {
        @AppStorage("ttsVoice") private var ttsVoice: String = "coral"
        @AppStorage("ttsRate") private var ttsRate: Double = 1.0

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Voice & Speech")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundColor(.mainBlack)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VoicePickerView(
                        selectedKey: $ttsVoice,
                        options: [
                            VoiceOption(key: "coral", title: "Coral", description: "soft, neutral"),
                            VoiceOption(key: "alloy", title: "Alloy", description: "friendly, warm"),
                            VoiceOption(key: "verse", title: "Verse", description: "energetic, expressive"),
                            VoiceOption(key: "sage", title: "Sage", description: "calm, confident")
                        ]
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speed")
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundColor(.mainBlack)
                            Spacer()
                            Text(String(format: "%.2fx", ttsRate))
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.mainGrey)
                        }
                        .padding(.horizontal)

                        Slider(value: $ttsRate, in: 0.75...1.5, step: 0.05)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.appBackground.ignoresSafeArea())
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
}

#Preview("Light") {
    SettingsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .environmentObject(WordsStore())
        .environmentObject(LanguageStore())
        .preferredColorScheme(.dark)
}

