import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSettings = false
    @State private var avatarImage: UIImage?
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
    @AppStorage(AppStorageKeys.selectedCuteTag) private var storedCuteTag: String = "cutie"
    @AppStorage(AppStorageKeys.selectedCuteTagDate) private var storedCuteTagDate: String = ""
    @AppStorage(AppStorageKeys.userName) private var storedUserName: String = ""
    @AppStorage(AppStorageKeys.daysUsedCount) private var daysUsedCount: Int = 0
    @AppStorage(AppStorageKeys.lastActiveDay) private var lastActiveDay: String = ""
    @AppStorage(AppStorageKeys.firstUseDate) private var firstUseDate: String = ""
    @AppStorage(AppStorageKeys.currentStreak) private var currentStreak: Int = 0
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    private var displayName: String {
        let name = storedUserName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "Cool guy" }
        return name.components(separatedBy: " ").first ?? name
    }

    private var cuteTagPalettes: [(bg: Color, text: Color)] {[
        (themeStore.accentGold.opacity(0.3), themeStore.mainText),
        (themeStore.accentGreen.opacity(0.3), themeStore.mainText),
        (themeStore.accentBlue.opacity(0.3), themeStore.mainText),
        (themeStore.accentPink.opacity(0.3), themeStore.mainText),
        (themeStore.accentPurple.opacity(0.3), themeStore.mainText),
        (themeStore.accentBlue.opacity(0.25), themeStore.mainText)
    ]}

    @State private var cuteTagBackground: Color = Color("MonoLight").opacity(0.3)
    @State private var cuteTagTextColor: Color = Color("MainBlack")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 6) {
                    ZStack {
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 58, height: 58)
                                .clipped()
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(themeStore.accentBlue.opacity(0.25))
                                .frame(width: 58, height: 58)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(themeStore.mainText)
                                )
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture { showSettings = true }
                    .accessibilityLabel(Text("Profile photo"))
                    .accessibilityHint(Text("Opens settings"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(displayName)
                            .font(themeStore.bold(18))
                            .foregroundColor(themeStore.mainText)

                        if isPremium {
                            Text("PRO")
                                .font(themeStore.bold(10))
                                .foregroundColor(themeStore.accentBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(themeStore.accentBlueSoft)
                                )
                        }
                    }

                    Text("\(usageDurationString()) with Droword")
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)

                }

                Spacer()
            }

        }
        .padding(.horizontal, 36)
        .padding(.top, 40)
        .onAppear {
            let today = DateFormatting.todayString
            if firstUseDate.isEmpty { firstUseDate = today }

            let isPremiumUser = UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
            if isPremiumUser {
                let result = WordsStore.computeCurrentStreakWithFreeze(from: store.words)
                currentStreak = max(result.streak, 1)
                if let freezeDay = result.freezeDate {
                    let freezeStr = DateFormatting.dayFormatter.string(from: freezeDay)
                    let lastFreezeStr = UserDefaults.standard.string(forKey: AppStorageKeys.lastStreakFreezeDate) ?? ""
                    if freezeStr != lastFreezeStr {
                        UserDefaults.standard.set(freezeStr, forKey: AppStorageKeys.lastStreakFreezeDate)
                    }
                }
            } else {
                let computed = WordsStore.computeCurrentStreak(from: store.words)
                currentStreak = max(computed, 1)
            }

            if lastActiveDay != today {
                daysUsedCount += 1
                lastActiveDay = today
                NotificationManager.shared.scheduleStreakMilestone(streak: currentStreak)
            }

            store.syncStreakToAppGroup()

            Task.detached(priority: .userInitiated) {
                let loaded = self.loadAvatarFromDisk()
                await MainActor.run { avatarImage = loaded }
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .avatarDidChange)) { _ in
            Task.detached(priority: .userInitiated) {
                let loaded = self.loadAvatarFromDisk()
                await MainActor.run { avatarImage = loaded }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
                .preferredColorScheme(colorScheme)
        }
    }

    private func usageDurationString() -> String {
        guard let start = DateFormatting.dayFormatter.date(from: firstUseDate), let end = DateFormatting.dayFormatter.date(from: DateFormatting.todayString) else {
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

    private nonisolated func loadAvatarFromDisk() -> UIImage? {
        let url = avatarFileURL()
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    private nonisolated func avatarFileURL() -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("user_avatar.jpg")
        }
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
