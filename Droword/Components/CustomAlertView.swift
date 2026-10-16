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
    @State private var iconScale: CGFloat = 0.72
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

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

    private var pageColor: Color { iconColor }

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                SoftCoverHero(
                    systemName: icon,
                    color: pageColor,
                    iconScale: iconScale
                )

                VStack(spacing: 8) {
                    Text(title)
                        .font(themeStore.display(32))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(themeStore.regular(16))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 18)
                .opacity(textOpacity)

                Spacer(minLength: 24)

                VStack(spacing: DesignSpacing.buttonGap) {
                    Button {
                        Haptics.lightImpact()
                        primaryButton.action()
                    } label: {
                        Text(primaryButton.title)
                            .duo3DStyle(pageColor)
                    }
                    .buttonStyle(Duo3DButtonStyle())

                    if let secondary = secondaryButton {
                    Button {
                        Haptics.softTap()
                        secondary.action()
                    } label: {
                        Text(secondary.title)
                            .duo3DSecondaryStyle()
                    }
                    .buttonStyle(Duo3DButtonStyle())
                    }
                }
                .opacity(buttonOpacity)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, DesignSpacing.screenInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: play)
    }

    private func play() {
        switch mood {
        case .destructive:
            Haptics.error()
        case .notice:
            Haptics.warning()
        case .success:
            Haptics.success()
        }

        guard !reduceMotion else {
            iconScale = 1
            textOpacity = 1
            buttonOpacity = 1
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            iconScale = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.28)) {
            buttonOpacity = 1
        }
    }
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
                iconColor: Color.accentBlue,
                title: "Word already exists",
                message: "«bonjour» is already in your dictionary.",
                primaryButton: .init(title: "Got it", style: .primary, action: onDismiss)
            )
        case .importComplete:
            CustomAlertView(
                icon: "checkmark.circle",
                iconColor: Color.accentGreen,
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
                icon: "arrow.left.arrow.right",
                iconColor: Color.accentPurple,
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
