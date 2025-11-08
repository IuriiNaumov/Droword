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

    private var levelColor: Color {
        switch level {
        case 1...5:  return Color(hexRGB: 0xFFDFA4)
        case 6...10: return Color(hexRGB: 0xC6F6D5)
        case 11...20: return Color(hexRGB: 0xB9E3FF)
        case 21...30: return Color(hexRGB: 0xE4D2FF)
        case 31...40: return Color(hexRGB: 0xFFC6C9)
        case 41...50: return Color(hexRGB: 0xFFF1B2)
        default:      return Color(hexRGB: 0xBDF4F2)
        }
    }

    private let goldText = Color(hexRGB: 0xB88A00)
    private let goldBackground = Color(hexRGB: 0xFFF1B2)

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
                            .overlay(Circle().stroke(levelColor, lineWidth: 3))
                    } else {
                        Circle()
                            .fill(levelColor.opacity(0.25))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(Color(.mainBlack))
                            )
                    }
                }
                .contentShape(Circle())
                .onTapGesture { showSettings = true }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Yura")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(Color(.mainBlack))

                    HStack(spacing: 10) {
                        Label("Lv \(level)", systemImage: "star.fill")
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundColor(Color(darkerShade(of: levelColor, by: 0.35)))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(levelColor))

                        Label("\(totalXP) XP", systemImage: "bolt.fill")
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundColor(goldText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(goldBackground))
                    }
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("MainGrey").opacity(0.15))
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
            .onAppear {
                avatarImage = loadAvatarFromDisk()
                displayProgress = progressRatio
            }
            .onChange(of: progressRatio) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayProgress = newValue
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.settingsBackground)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
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

#Preview {
    ProfileHeaderView().environmentObject(WordsStore())
}
