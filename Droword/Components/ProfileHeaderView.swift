import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSettings = false
    @State private var avatarImage: UIImage?
    @State private var displayProgress: Double = 0.0
    @State private var showStats = false
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
    @AppStorage("daysUsedCount") private var daysUsedCount: Int = 0
    @AppStorage("lastActiveDay") private var lastActiveDay: String = ""
    @AppStorage("firstUseDate") private var firstUseDate: String = ""
    @AppStorage("currentStreak") private var currentStreak: Int = 0

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

    private var overdueCount: Int {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        return store.words.filter { w in
            if let due = w.dueDate { return due < startOfToday } else { return false }
        }.count
    }

    private var dueTodayCount: Int {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        guard let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: startOfToday) else { return 0 }
        return store.words.filter { w in
            if let due = w.dueDate { return (due >= startOfToday && due < startOfTomorrow) } else { return false }
        }.count
    }

    private var displayName: String {
        storedUserName.isEmpty ? "Cool guy" : storedUserName
    }

    private var levelBackground: Color { themeStore.accentBlue }
    private var levelText: Color { themeStore.accentBlue }

    private var xpBackground: Color { themeStore.accentGold }
    private var xpText: Color { themeStore.accentGold }

    private var cuteTagPalettes: [(bg: Color, text: Color)] {[
        (themeStore.accentGold.opacity(0.3), Color.mainBlack),
        (themeStore.accentGreen.opacity(0.3), Color.mainBlack),
        (themeStore.accentBlue.opacity(0.3), Color.mainBlack),
        (themeStore.accentPink.opacity(0.3), Color.mainBlack),
        (themeStore.accentPurple.opacity(0.3), Color.mainBlack),
        (themeStore.accentBlue.opacity(0.25), Color.mainBlack)
    ]}

    @State private var cuteTagBackground: Color = Color("MonoLight").opacity(0.3)
    @State private var cuteTagTextColor: Color = Color.mainBlack

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 6) {
                    ZStack {
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipped()
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
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.mainBlack)

                    Text("\(usageDurationString()) with Droword")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.mainGrey)

                }

                Spacer()
            }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onAppear {
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.dateFormat = "yyyy-MM-dd"
            let today = df.string(from: Date())
            if firstUseDate.isEmpty { firstUseDate = today }

            if lastActiveDay != today {
                let calendar = Calendar(identifier: .gregorian)
                if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: df.date(from: today) ?? Date()),
                   df.string(from: yesterdayDate) == lastActiveDay {
                    currentStreak = max(1, currentStreak + 1)
                } else {
                    currentStreak = 1
                }
                daysUsedCount += 1
                lastActiveDay = today
                NotificationManager.shared.scheduleStreakMilestone(streak: currentStreak)
            } else if currentStreak == 0 {
                currentStreak = 1
            }

            avatarImage = loadAvatarFromDisk()
            displayProgress = progressRatio

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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                displayProgress = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .avatarDidChange)) { _ in
            avatarImage = loadAvatarFromDisk()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(themeStore)
                .preferredColorScheme(colorScheme)
        }
    }

    private func usageDurationString() -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        guard let start = df.date(from: firstUseDate), let end = df.date(from: df.string(from: Date())) else {
            return "0 days"
        }
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: start, to: end)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)

        func plural(_ value: Int, _ singular: String, _ plural: String) -> String {
            return value == 1 ? "\(value) \(singular)" : "\(value) \(plural)"
        }

        if years >= 1 {
            if months > 0 {
                return "\(plural(years, "year", "years")) \(plural(months, "month", "months"))"
            } else {
                return plural(years, "year", "years")
            }
        } else if months >= 1 {
            return plural(months, "month", "months")
        } else {
            return plural(days + 1, "day", "days")
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
