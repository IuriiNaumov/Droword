import SwiftUI

/// Home CTA that opens the "learn new words" flow. New words wait here until the
/// user has been introduced to them; only then do they enter spaced review.
struct LearnNewWordsCard: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    let count: Int
    var onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeStore.iconCircleFill(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeStore.accentBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Learn new words")
                        .font(themeStore.bold(16))
                        .foregroundStyle(themeStore.mainText)
                    Text("\(count) new words ready")
                        .font(themeStore.regular(13))
                        .foregroundStyle(themeStore.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.accentBlue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 16))
            .cardDepth(cornerRadius: 16)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Learn new words"))
        .accessibilityHint(Text("\(count) new words ready to learn"))
    }
}

/// A short, swipeable "introduction" phase for brand-new words: the user sees the
/// word, hears it, then reveals its meaning and an example before it graduates
/// into spaced-repetition review. First exposure should be teaching, not testing.
struct LearnNewWordsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false

    /// Words to introduce this session (capped so a session stays short).
    private let batch: [StoredWord]
    /// Called with the ids the user actually got introduced to.
    private let onComplete: ([UUID]) -> Void

    @State private var index: Int = 0
    @State private var revealed: Bool = false
    @State private var isPlaying: Bool = false
    @State private var learnedIDs: [UUID] = []
    @State private var showPremiumWall = false
    @State private var finished = false

    init(words: [StoredWord], onComplete: @escaping ([UUID]) -> Void) {
        // Cap this session to the remaining daily new-word allowance (and never
        // more than 10 at once) so the user isn't overloaded and future reviews
        // stay manageable.
        let cap = max(0, min(DailyLimitsManager.newWordsRemainingToday, 10))
        self.batch = Array(words.prefix(cap))
        self.onComplete = onComplete
    }

    private var current: StoredWord? {
        guard index >= 0 && index < batch.count else { return nil }
        return batch[index]
    }

    private var isLast: Bool { index >= batch.count - 1 }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            if finished || batch.isEmpty {
                completionView
            } else {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 0)
                    if let word = current {
                        card(for: word)
                            .id(word.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    Spacer(minLength: 0)
                    bottomButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.lightImpact()
                finish()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))

            ProgressView(value: Double(index + 1), total: Double(max(1, batch.count)))
                .tint(themeStore.mainAccentColor)

            Text("\(index + 1)/\(batch.count)")
                .font(themeStore.medium(14))
                .foregroundStyle(themeStore.secondaryText)
                .monospacedDigit()
        }
        .padding(.top, 12)
    }

    // MARK: - Card

    private func card(for word: StoredWord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tag = word.tag, !tag.isEmpty {
                Text(LocalizedStringKey(tag))
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.colorForTag(tag))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(themeStore.colorForTag(tag), lineWidth: 1)
                    )
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(word.word)
                    .font(themeStore.bold(30))
                    .foregroundStyle(themeStore.mainText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    Haptics.selection()
                    playAudio(word.word)
                } label: {
                    SoundWavesView(isPlaying: isPlaying)
                        .frame(width: 28, height: 28)
                        .tint(themeStore.mainText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Play pronunciation"))
            }

            if let tr = word.transcription, !tr.isEmpty {
                Text(tr)
                    .font(themeStore.regular(16))
                    .foregroundStyle(themeStore.secondaryText)
            }

            if revealed {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().overlay(themeStore.secondaryText.opacity(0.2))

                    Text(word.translation ?? "")
                        .font(themeStore.bold(22))
                        .foregroundStyle(themeStore.mainText)

                    if let comment = word.comment, !comment.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(themeStore.accentGold)
                                .padding(.top, 2)
                            Text(comment)
                                .font(themeStore.regular(15))
                                .foregroundStyle(themeStore.secondaryText)
                        }
                    }

                    if let example = word.example,
                       !example.isEmpty,
                       example != "Add an example later" {
                        Text(HighlightedExample.make(example: example, word: word.word))
                            .font(themeStore.regular(17))
                            .foregroundStyle(themeStore.mainText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !word.collocations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Common phrases")
                                .font(themeStore.medium(13))
                                .foregroundStyle(themeStore.secondaryText)
                            Text(word.collocations.joined(separator: "  ·  "))
                                .font(themeStore.regular(15))
                                .foregroundStyle(themeStore.mainText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: 24))
        .cardDepth(cornerRadius: 24)
    }

    // MARK: - Bottom button

    private var bottomButton: some View {
        Button {
            Haptics.lightImpact()
            if revealed {
                advance()
            } else {
                withAnimation(.easeInOut(duration: 0.22)) { revealed = true }
            }
        } label: {
            Text(revealed ? (isLast ? "Finish" : "Got it") : "Reveal meaning")
                .font(themeStore.bold(17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeStore.mainAccentColor)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(themeStore.accentGreen.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(themeStore.accentGreen)
            }
            Text("Nice work!")
                .font(themeStore.bold(26))
                .foregroundStyle(themeStore.mainText)
            Text("\(learnedIDs.count) new words are now in your review rotation.")
                .font(themeStore.regular(16))
                .foregroundStyle(themeStore.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Haptics.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(themeStore.bold(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeStore.mainAccentColor)
                    )
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    // MARK: - Logic

    private func advance() {
        if let word = current, !learnedIDs.contains(word.id) {
            learnedIDs.append(word.id)
        }
        if isLast {
            onComplete(learnedIDs)
            withAnimation(.easeOut(duration: 0.25)) { finished = true }
            Haptics.success()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                index += 1
                revealed = false
            }
        }
    }

    private func finish() {
        // Persist whatever the user already learned before closing early.
        onComplete(learnedIDs)
        dismiss()
    }

    private func playAudio(_ word: String) {
        TTSPlayer.play(
            word: word,
            isPremium: isPremium,
            onNeedsPremium: { showPremiumWall = true },
            onPlayingChanged: { isPlaying = $0 }
        )
    }
}
