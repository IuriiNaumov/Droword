import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @State private var avatarImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?

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
                                .overlay(
                                    Circle().stroke(Color.mainBlack.opacity(0.1), lineWidth: 3)
                                )
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
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.mainBlack.opacity(0.6))
                                    .clipShape(Circle())
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .frame(width: 92, height: 92)
                    }
                    .onTapGesture { showPhotoPicker = true }

                    Text("Yura")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.mainBlack)
                }
                .padding(.top, 32)

                VStack(spacing: 20) {
                    groupedSettingsSection([
                        SettingItem(icon: "person.circle", color: .green, title: "Personal details"),
                        SettingItem(icon: "lock.fill", color: .green, title: "Security"),
                        SettingItem(icon: "creditcard.fill", color: .blue, title: "Destination accounts")
                    ])

                    groupedSettingsSection([
                        SettingItem(icon: "moon.fill", color: .gold, title: "Appearance", value: "System"),
                        SettingItem(icon: "textformat.size", color: .yellow, title: "Language", value: "English"),
                        SettingItem(icon: "bell.badge.fill", color: .pink, title: "Notifications")
                    ])
                }

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
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

    private func groupedSettingsSection(_ items: [SettingItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]

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
                .background(Color.settingsBackground)
            }
        }.cornerRadius(18)
        .padding(.horizontal)
    }

    private func saveAvatarToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let url = avatarFileURL()
        try? data.write(to: url)
    }

    private func loadAvatarFromDisk() -> UIImage? {
        let url = avatarFileURL()
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    private func avatarFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("user_avatar.jpg")
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
        .preferredColorScheme(.light)
}
