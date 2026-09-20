import SwiftUI

struct CustomAlertView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryButton: AlertButton
    var secondaryButton: AlertButton? = nil

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

    private var iconKind: ModalIconKind {
        ModalIconKind.from(systemName: icon)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    if let secondary = secondaryButton, secondary.style == .cancel {
                        secondary.action()
                    }
                }

            VStack(spacing: 18) {
                ModalIconView(kind: iconKind, color: iconColor, size: 92)
                    .padding(.top, 4)

                Text(title)
                    .font(themeStore.bold(20))
                    .foregroundStyle(themeStore.mainText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(themeStore.regular(15))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    Button {
                        Haptics.lightImpact()
                        primaryButton.action()
                    } label: {
                        Text(primaryButton.title)
                            .font(themeStore.bold(16))
                            .foregroundStyle(.white)
                            .duo3DStyle(buttonBgColor(primaryButton.style))
                    }
                    .buttonStyle(Duo3DButtonStyle())

                    if let secondary = secondaryButton {
                        Button {
                            Haptics.lightImpact()
                            secondary.action()
                        } label: {
                            Text(secondary.title)
                                .font(themeStore.medium(15))
                                .foregroundStyle(themeStore.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.dialog, style: .continuous)
                    .fill(themeStore.isGlass ? Color.clear : themeStore.appBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.dialog))
            .padding(.horizontal, 32)
        }
    }

    private func buttonBgColor(_ style: AlertButton.Style) -> Color {
        switch style {
        case .primary:
            return themeStore.mainAccentColor
        case .destructive:
            return themeStore.accentRed
        case .cancel:
            return themeStore.secondaryText.opacity(0.35)
        }
    }
}

#Preview("Clear dictionary") {
    CustomAlertView(
        icon: "trash.fill",
        iconColor: Color.accentRed,
        title: "Clear dictionary?",
        message: "This deletes all 42 words. This can't be undone.",
        primaryButton: .init(title: "Clear all", style: .destructive) {},
        secondaryButton: .init(title: "Cancel", style: .cancel) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Delete words") {
    CustomAlertView(
        icon: "trash.fill",
        iconColor: Color.accentRed,
        title: "Delete 3 words?",
        message: "This action cannot be undone.",
        primaryButton: .init(title: "Delete", style: .destructive) {},
        secondaryButton: .init(title: "Cancel", style: .cancel) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Offline add") {
    CustomAlertView(
        icon: "wifi.slash",
        iconColor: Color.accentGold,
        title: "No internet connection",
        message: "The word will be saved and enriched once you're back online.",
        primaryButton: .init(title: "Add anyway", style: .primary) {},
        secondaryButton: .init(title: "Cancel", style: .cancel) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Duplicate word") {
    CustomAlertView(
        icon: "doc.on.doc",
        iconColor: Color.accentGold,
        title: "Word already exists",
        message: "«bonjour» is already in your dictionary.",
        primaryButton: .init(title: "Got it", style: .primary) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Import complete") {
    CustomAlertView(
        icon: "checkmark.circle.fill",
        iconColor: Color.accentBlue,
        title: "Import Complete",
        message: "12 words imported successfully.",
        primaryButton: .init(title: "OK", style: .primary) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Import failed") {
    CustomAlertView(
        icon: "exclamationmark.triangle.fill",
        iconColor: Color.accentGold,
        title: "Import failed",
        message: "Need a column named \"Word\".",
        primaryButton: .init(title: "OK", style: .primary) {}
    )
    .environmentObject(ThemeStore())
}

#Preview("Language switch") {
    CustomAlertView(
        icon: "exclamationmark.triangle.fill",
        iconColor: Color.accentGold,
        title: "Switch learning language?",
        message: "You have 18 words in French. They will stay in your dictionary.",
        primaryButton: .init(title: "Switch", style: .primary) {},
        secondaryButton: .init(title: "Cancel", style: .cancel) {}
    )
    .environmentObject(ThemeStore())
}
