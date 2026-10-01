import SwiftUI

struct CustomAlertView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryButton: AlertButton
    var secondaryButton: AlertButton? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var iconIn = false
    @State private var copyIn = false
    @State private var actionsIn = false
    @State private var ring = false
    @State private var litSparkles = 0

    struct AlertButton {
        let title: LocalizedStringKey
        let style: Style
        let action: () -> Void

        enum Style {
            case primary
            case destructive
            case cancel
        }
    }

    private enum Mood {
        case destructive
        case success
        case notice
    }

    private var mood: Mood {
        if primaryButton.style == .destructive { return .destructive }
        if ModalIconKind.from(systemName: icon) == .success { return .success }
        return .notice
    }

    private var pageColor: Color {
        switch mood {
        case .destructive: return themeStore.errorStrong
        case .success: return themeStore.successStrong
        case .notice: return themeStore.mainAccentColor
        }
    }

    var body: some View {
        ZStack {
            pageColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    if mood == .success {
                        alertSparkles
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.95), lineWidth: 2)
                            .frame(width: 92, height: 92)
                            .scaleEffect(ring ? 1.65 : 0.72)
                            .opacity(ring ? 0 : 0.9)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(iconIn ? 1 : 0.4)
                        .opacity(iconIn ? 1 : 0)
                }
                .frame(height: 120)
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(title)
                        .font(themeStore.display(34))
                        .foregroundStyle(.white)
                        .tracking(-0.5)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(themeStore.regular(17))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .offset(y: copyIn ? 0 : 18)
                .opacity(copyIn ? 1 : 0)

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    pageButton(primaryButton, filled: true)
                    if let secondary = secondaryButton {
                        pageButton(secondary, filled: secondary.style != .cancel)
                    }
                }
                .offset(y: actionsIn ? 0 : 28)
                .opacity(actionsIn ? 1 : 0)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: play)
    }

    private var alertSparkles: some View {
        ZStack {
            ForEach(AlertSparkle.samples) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(sparkle.turn))
                    .scaleEffect(sparkle.id < litSparkles ? 1 : 0.15)
                    .opacity(sparkle.id < litSparkles ? 1 : 0)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: litSparkles)
            }
        }
        .allowsHitTesting(false)
    }

    private func pageButton(_ button: AlertButton, filled: Bool) -> some View {
        Button {
            Haptics.lightImpact()
            button.action()
        } label: {
            Text(button.title)
                .font(themeStore.bold(17))
                .foregroundStyle(filled ? pageColor : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    if filled {
                        RoundedRectangle(cornerRadius: themeStore.controlRadius, style: .continuous)
                            .fill(.white)
                    }
                }
                .overlay {
                    if !filled {
                        RoundedRectangle(cornerRadius: themeStore.controlRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.7), lineWidth: 2)
                    }
                }
        }
        .buttonStyle(Duo3DButtonStyle())
    }

    private func play() {
        switch mood {
        case .destructive:
            Haptics.error()
        case .notice:
            Haptics.warning()
        case .success:
            break
        }

        guard !reduceMotion else {
            iconIn = true
            copyIn = true
            actionsIn = true
            ring = true
            litSparkles = AlertSparkle.samples.count
            if mood == .success { Haptics.success() }
            return
        }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) {
            iconIn = true
            ring = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.84).delay(0.08)) {
            copyIn = true
        }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86).delay(0.16)) {
            actionsIn = true
        }
        if mood == .success {
            revealSparkles()
        }
    }

    private func revealSparkles() {
        let total = AlertSparkle.samples.count
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            for index in 0..<total {
                litSparkles = index + 1
                Haptics.sparkleTick()
                try? await Task.sleep(for: .milliseconds(110))
            }
        }
    }
}

private struct AlertSparkle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let turn: Double

    static let samples: [AlertSparkle] = [
        AlertSparkle(id: 0, x: -78, y: -28, size: 16, turn: -12),
        AlertSparkle(id: 1, x: 82, y: -18, size: 13, turn: 18),
        AlertSparkle(id: 2, x: -54, y: 36, size: 11, turn: 8),
        AlertSparkle(id: 3, x: 60, y: 40, size: 15, turn: -20),
        AlertSparkle(id: 4, x: 6, y: -52, size: 12, turn: 6)
    ]
}

enum CustomAlertPreviewCase: String, CaseIterable, Identifiable {
    case clearDictionary
    case deleteWords
    case offlineAdd
    case duplicateWord
    case importComplete
    case importFailed
    case languageSwitch

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .clearDictionary: return "Clear dictionary alert"
        case .deleteWords: return "Delete words alert"
        case .offlineAdd: return "Offline add alert"
        case .duplicateWord: return "Duplicate word alert"
        case .importComplete: return "Import complete alert"
        case .importFailed: return "Import failed alert"
        case .languageSwitch: return "Language switch alert"
        }
    }

    @ViewBuilder
    func makeView(onDismiss: @escaping () -> Void) -> some View {
        switch self {
        case .clearDictionary:
            CustomAlertView(
                icon: "trash",
                iconColor: Color.accentRed,
                title: "Clear dictionary?",
                message: "All words will be deleted and cannot be recovered.",
                primaryButton: .init(title: "Clear all", style: .destructive, action: onDismiss),
                secondaryButton: .init(title: "Cancel", style: .cancel, action: onDismiss)
            )
        case .deleteWords:
            CustomAlertView(
                icon: "trash",
                iconColor: Color.accentRed,
                title: "Delete 3 words?",
                message: "This action cannot be undone.",
                primaryButton: .init(title: "Delete", style: .destructive, action: onDismiss),
                secondaryButton: .init(title: "Cancel", style: .cancel, action: onDismiss)
            )
        case .offlineAdd:
            CustomAlertView(
                icon: "wifi.slash",
                iconColor: Color.accentGold,
                title: "No internet connection",
                message: "The word will be saved and enriched once you're back online.",
                primaryButton: .init(title: "Add anyway", style: .primary, action: onDismiss),
                secondaryButton: .init(title: "Cancel", style: .cancel, action: onDismiss)
            )
        case .duplicateWord:
            CustomAlertView(
                icon: "doc.on.doc",
                iconColor: Color.accentGold,
                title: "Word already exists",
                message: "«bonjour» is already in your dictionary.",
                primaryButton: .init(title: "Got it", style: .primary, action: onDismiss)
            )
        case .importComplete:
            CustomAlertView(
                icon: "checkmark.circle",
                iconColor: Color.accentBlue,
                title: "Import Complete",
                message: "12 words imported successfully.",
                primaryButton: .init(title: "OK", style: .primary, action: onDismiss)
            )
        case .importFailed:
            CustomAlertView(
                icon: "exclamationmark.triangle",
                iconColor: Color.accentGold,
                title: "Import failed",
                message: "Need a column named \"Word\".",
                primaryButton: .init(title: "OK", style: .primary, action: onDismiss)
            )
        case .languageSwitch:
            CustomAlertView(
                icon: "exclamationmark.triangle",
                iconColor: Color.accentGold,
                title: "Switch learning language?",
                message: "You have 18 words in French. They will stay in your dictionary.",
                primaryButton: .init(title: "Switch", style: .primary, action: onDismiss),
                secondaryButton: .init(title: "Cancel", style: .cancel, action: onDismiss)
            )
        }
    }
}

#Preview("Clear dictionary") {
    CustomAlertPreviewCase.clearDictionary.makeView(onDismiss: {})
        .environmentObject(ThemeStore())
}

#Preview("Offline add") {
    CustomAlertPreviewCase.offlineAdd.makeView(onDismiss: {})
        .environmentObject(ThemeStore())
}
