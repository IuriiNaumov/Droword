import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject private var store: WordsStore
    @State private var showSettings = false
    @State private var avatarImage: UIImage?
    @State private var displayProgress: Double = 0.0

    private let xpPerWord = 10
    private let maxLevel = 50

    private var totalWords: Int { store.totalWordsAdded }
    private var totalXP: Int { totalWords * xpPerWord }

    private var level: Int {
        var currentLevel = 1
        var wordsAccumulated = 0
        while currentLevel < maxLevel {
            let wordsNeeded = 3 + (currentLevel - 1) * 2
            if totalWords < wordsAccumulated + wordsNeeded { break }
            wordsAccumulated += wordsNeeded
            currentLevel += 1
        }
        return currentLevel
    }

    private var wordsForCurrentLevel: Int {
        3 + (level - 1) * 2
    }

    private var wordsBeforeCurrentLevel: Int {
        (1..<level).reduce(0) { $0 + (3 + ($1 - 1) * 2) }
    }

    private var wordsProgressInLevel: Int {
        max(0, totalWords - wordsBeforeCurrentLevel)
    }

    private var progressRatio: Double {
        guard wordsForCurrentLevel > 0 else { return 0 }
        return min(Double(wordsProgressInLevel) / Double(wordsForCurrentLevel), 1.0)
    }

    private var wordsToNextLevel: Int {
        max(0, wordsForCurrentLevel - wordsProgressInLevel)
    }

    private let levelBackground = Color(hex: "#FFE6AA")
    private let levelText = Color(hex: "#9C6B00")

    private let xpBackground = Color(hex: "#DEF1D0")
    private let xpText = Color(hex: "#3E8A64")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(levelBackground, lineWidth: 3))
                    } else {
                        Circle()
                            .fill(levelBackground.opacity(0.25))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(.mainBlack)
                            )
                    }
                }
                .contentShape(Circle())
                .onTapGesture { showSettings = true }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Yura")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.mainBlack)

                    HStack(spacing: 10) {
                        Label("Lv \(level)", systemImage: "star.fill")
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundColor(levelText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(levelBackground))

                        Label("\(totalXP) XP", systemImage: "bolt.fill")
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundColor(xpText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(xpBackground))
                    }
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.divider)
                        .frame(height: 16)

                    Capsule()
                        .fill(Color.progressBar)
                        .frame(width: CGFloat(displayProgress) * 240, height: 16)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: displayProgress)
                }

                Text("\(totalXP) XP – \(wordsToNextLevel * xpPerWord) XP to level up")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.mainGrey)
                    .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
        .onAppear {
            avatarImage = loadAvatarFromDisk()
            displayProgress = progressRatio
        }
        .onChange(of: progressRatio) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayProgress = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .avatarDidChange)) { _ in
            avatarImage = loadAvatarFromDisk()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
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

extension Color {
    init(hexRGB: UInt) {
        let r = Double((hexRGB >> 16) & 0xFF) / 255
        let g = Double((hexRGB >> 8) & 0xFF) / 255
        let b = Double(hexRGB & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Notification.Name {
    static let avatarDidChange = Notification.Name("avatarDidChange")
}

#Preview {
    ProfileHeaderView().environmentObject(WordsStore())
}
