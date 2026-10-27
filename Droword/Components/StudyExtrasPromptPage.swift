import SwiftUI

enum StudyExtra: String, CaseIterable, Identifiable {
    case reading
    case chat
    case packs
    case challenges

    var id: String { rawValue }

    static var offered: [StudyExtra] {
        var items: [StudyExtra] = [.reading, .packs, .challenges]
        if FeatureGates.homeChatEnabled {
            items.insert(.chat, at: 1)
        }
        return items
    }

    var storageKey: String {
        switch self {
        case .reading: return AppStorageKeys.showHomeReading
        case .chat: return AppStorageKeys.showHomeChat
        case .packs: return AppStorageKeys.showWordPacks
        case .challenges: return AppStorageKeys.showDailyChallenges
        }
    }

    var defaultOn: Bool {
        self != .challenges
    }

    var isOn: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: storageKey) != nil else { return defaultOn }
        return defaults.bool(forKey: storageKey)
    }

    var icon: String {
        switch self {
        case .reading: return "book.pages"
        case .chat: return "bubble.left.and.bubble.right"
        case .packs: return "rectangle.stack"
        case .challenges: return "dumbbell"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .reading: return "Reading"
        case .chat: return "Chat"
        case .packs: return "Word Packs"
        case .challenges: return "Daily Challenges"
        }
    }

    var benefit: LocalizedStringKey {
        switch self {
        case .reading:
            return "Your words come back in a short story, so they stick."
        case .chat:
            return "Say a word in a tiny real scene, not just on a card."
        case .packs:
            return "Ready lists of words when you want to learn a topic."
        case .challenges:
            return "A small goal each day makes it easier to come back."
        }
    }
}

enum StudyExtrasPrompt {
    static let wordThreshold = 5

    static var hasDisabledExtra: Bool {
        StudyExtra.offered.contains { !$0.isOn }
    }
}

struct StudyExtrasPromptPage: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var showsEveryExtra: Bool = false
    let onDismiss: () -> Void

    @AppStorage(AppStorageKeys.showHomeReading) private var showHomeReading: Bool = true
    @AppStorage(AppStorageKeys.showHomeChat) private var showHomeChat: Bool = true
    @AppStorage(AppStorageKeys.showWordPacks) private var showWordPacks: Bool = true
    @AppStorage(AppStorageKeys.showDailyChallenges) private var showDailyChallenges: Bool = false

    @State private var shown: [StudyExtra] = []
    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var rowsVisible = false
    @State private var footerOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var popped: StudyExtra?

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            SoftCoverScrollCentered {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 8) {
                        Text("Nice work")
                            .font(themeStore.display(32))
                            .foregroundStyle(themeStore.mainText)
                            .tracking(-0.4)
                            .multilineTextAlignment(.center)

                        Text("You started learning words. Here is what can help you keep going.")
                            .font(themeStore.regular(16))
                            .foregroundStyle(themeStore.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 18)
                    .opacity(textOpacity)

                    VStack(spacing: 10) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, extra in
                            row(extra)
                                .opacity(rowsVisible ? 1 : 0)
                                .offset(y: rowsVisible ? 0 : 14)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.82)
                                        .delay(reduceMotion ? 0 : 0.22 + Double(index) * 0.08),
                                    value: rowsVisible
                                )
                        }
                    }
                    .padding(.top, 28)

                    Text("You can always turn these off in Settings → Dictionary.")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 18)
                        .opacity(footerOpacity)
                }
            } footer: {
                Button {
                    Haptics.lightImpact()
                    onDismiss()
                } label: {
                    Text("Continue")
                        .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
                .opacity(buttonOpacity)
            }
        }
        .onAppear(perform: play)
    }

    private var hero: some View {
        SoftCoverHero(
            systemName: "sparkles",
            color: themeStore.iconAccent,
            iconScale: iconScale
        )
    }

    private func row(_ extra: StudyExtra) -> some View {
        let on = isOn(extra)
        return Button {
            let next = !on
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                set(extra, next)
                popped = next ? extra : nil
            }
            if next {
                Haptics.success()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.28))
                    guard popped == extra else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        popped = nil
                    }
                }
            } else {
                Haptics.softTap()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: extra.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(themeStore.mainText)
                    .frame(width: 28, height: 28)
                    .scaleEffect(popped == extra ? 1.12 : 1)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(extra.title)
                        .font(themeStore.medium(16))
                        .foregroundStyle(themeStore.mainText)

                    Text(extra.benefit)
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: binding(for: extra))
                    .labelsHidden()
                    .tint(themeStore.mainAccentColor)
                    .allowsHitTesting(false)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .contentShape(RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func play() {
        shown = showsEveryExtra ? StudyExtra.offered : StudyExtra.offered.filter { !$0.isOn }
        Haptics.encourage()
        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            rowsVisible = true
            footerOpacity = 1
            buttonOpacity = 1
            return
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        let afterRows = 0.28 + Double(max(shown.count, 1)) * 0.08
        Task { @MainActor in
            rowsVisible = true
            try? await Task.sleep(for: .seconds(afterRows))
            withAnimation(.easeOut(duration: 0.3)) {
                footerOpacity = 1
                buttonOpacity = 1
            }
        }
    }

    private func isOn(_ extra: StudyExtra) -> Bool {
        switch extra {
        case .reading: return showHomeReading
        case .chat: return showHomeChat
        case .packs: return showWordPacks
        case .challenges: return showDailyChallenges
        }
    }

    private func set(_ extra: StudyExtra, _ value: Bool) {
        switch extra {
        case .reading: showHomeReading = value
        case .chat: showHomeChat = value
        case .packs: showWordPacks = value
        case .challenges: showDailyChallenges = value
        }
    }

    private func binding(for extra: StudyExtra) -> Binding<Bool> {
        switch extra {
        case .reading: return $showHomeReading
        case .chat: return $showHomeChat
        case .packs: return $showWordPacks
        case .challenges: return $showDailyChallenges
        }
    }
}

#Preview {
    StudyExtrasPromptPage(showsEveryExtra: true) {}
        .environmentObject(ThemeStore())
}
