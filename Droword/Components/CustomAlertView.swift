import SwiftUI

struct CustomAlertView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryButton: AlertButton
    var secondaryButton: AlertButton? = nil

    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0

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

    var body: some View {
        ZStack {
            themeStore.appBg.opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    if let secondary = secondaryButton, secondary.style == .cancel {
                        secondary.action()
                    }
                }

            VStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .padding(.top, 2)

                VStack(spacing: 8) {
                    Text(title)
                        .font(themeStore.display(22))
                        .foregroundStyle(themeStore.mainText)
                        .tracking(-0.4)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(themeStore.regular(15))
                        .foregroundStyle(themeStore.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    Button {
                        Haptics.lightImpact()
                        primaryButton.action()
                    } label: {
                        Text(primaryButton.title)
                            .duo3DStyle(buttonBgColor(primaryButton.style))
                    }
                    .buttonStyle(Duo3DButtonStyle())

                    if let secondary = secondaryButton {
                        Button {
                            Haptics.lightImpact()
                            secondary.action()
                        } label: {
                            Text(secondary.title)
                                .duo3DStyle(buttonBgColor(secondary.style))
                        }
                        .buttonStyle(Duo3DButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 360)
            .cleanCard(themeStore: themeStore, cornerRadius: DesignRadius.dialog)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                cardScale = 1
                cardOpacity = 1
            }
        }
    }

    private func buttonBgColor(_ style: AlertButton.Style) -> Color {
        switch style {
        case .primary:
            return themeStore.mainAccentColor
        case .destructive:
            return themeStore.accentRed
        case .cancel:
            return themeStore.secondaryText.opacity(0.55)
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
                icon: "trash.fill",
                iconColor: Color.accentRed,
                title: "Clear dictionary?",
                message: "This deletes all 42 words. This can't be undone.",
                primaryButton: .init(title: "Clear all", style: .destructive, action: onDismiss),
                secondaryButton: .init(title: "Cancel", style: .cancel, action: onDismiss)
            )
        case .deleteWords:
            CustomAlertView(
                icon: "trash.fill",
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
                icon: "checkmark.circle.fill",
                iconColor: Color.accentBlue,
                title: "Import Complete",
                message: "12 words imported successfully.",
                primaryButton: .init(title: "OK", style: .primary, action: onDismiss)
            )
        case .importFailed:
            CustomAlertView(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color.accentGold,
                title: "Import failed",
                message: "Need a column named \"Word\".",
                primaryButton: .init(title: "OK", style: .primary, action: onDismiss)
            )
        case .languageSwitch:
            CustomAlertView(
                icon: "exclamationmark.triangle.fill",
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
