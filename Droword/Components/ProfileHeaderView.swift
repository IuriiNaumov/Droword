import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject private var store: WordsStore
    @State private var showSettings = false
    @State private var avatarImage: UIImage?
    @State private var displayProgress: Double = 0.0
    private let cuteTags: [String] = [
        "keep it up",
        "proud of you",
        "nice progress",
        "you got this",
        "so consistent",
        "shining today",
        "looking sharp",
        "on a roll",
        "love your vibe",
        "crushing it"
    ]
    @AppStorage("selectedCuteTag") private var storedCuteTag: String = "cutie"
    @AppStorage("selectedCuteTagDate") private var storedCuteTagDate: String = ""
    @AppStorage("userName") private var storedUserName: String = ""

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

    private var displayName: String {
        storedUserName.isEmpty ? "Cool guy" : storedUserName
    }

    private let levelBackground = Color(hex: "#FFE6AA")
    private let levelText = Color(hex: "#9C6B00")

    private let xpBackground = Color(hex: "#DEF1D0")
    private let xpText = Color(hex: "#3E8A64")

    // Daily-changing palette for the cute tag (bg, text)
    private let cuteTagPalettes: [(bg: Color, text: Color)] = [
        (Color(hex: "#FFE6AA"), Color(hex: "#9C6B00")), // level colors
        (Color(hex: "#DEF1D0"), Color(hex: "#3E8A64")), // xp colors
        (Color(hex: "#DDEBFF"), Color(hex: "#2458B5")),
        (Color(hex: "#FFDDE7"), Color(hex: "#B51957")),
        (Color(hex: "#EDE3FF"), Color(hex: "#6B39B3")),
        (Color(hex: "#DFF7FF"), Color(hex: "#0E6C85"))
    ]

    @State private var cuteTagBackground: Color = Color(hex: "#FFE6AA")
    @State private var cuteTagTextColor: Color = Color(hex: "#9C6B00")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 6) {
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
                    .overlay(alignment: .topTrailing) {
                        Text(storedCuteTag)
                            .font(.custom("Poppins-Bold", size: 10))
                            .foregroundColor(cuteTagTextColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .truncationMode(.tail)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(cuteTagBackground)
                            )
                            .offset(x: 6, y: -6)
                    }
                    .contentShape(Circle())
                    .onTapGesture { showSettings = true }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
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

            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.dateFormat = "yyyy-MM-dd"
            let today = df.string(from: Date())

            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            let colorIndex = dayOfYear % cuteTagPalettes.count
            cuteTagBackground = cuteTagPalettes[colorIndex].bg
            cuteTagTextColor = cuteTagPalettes[colorIndex].text

            if storedCuteTagDate != today {
                let index = dayOfYear % cuteTags.count
                storedCuteTag = cuteTags[index]
                storedCuteTagDate = today
            }
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

private struct CuteTagBubbleShape: Shape {
    var cornerRadius: CGFloat = 10
    var notchWidth: CGFloat = 12
    var notchHeight: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        let nw = min(notchWidth, rect.width / 3)
        let nh = min(notchHeight, rect.height / 2)
        var p = Path()

        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - nw / 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY - nh))
        p.addLine(to: CGPoint(x: rect.midX + nw / 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        p.closeSubpath()
        return p
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

