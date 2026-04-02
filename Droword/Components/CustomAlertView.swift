import SwiftUI

struct CustomAlertView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let primaryButton: AlertButton
    var secondaryButton: AlertButton? = nil

    struct AlertButton {
        let title: String
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if let secondary = secondaryButton, secondary.style == .cancel {
                        secondary.action()
                    }
                }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(iconColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.top, 4)

                Text(title)
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(themeStore.mainText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    Button {
                        Haptics.lightImpact()
                        primaryButton.action()
                    } label: {
                        Text(primaryButton.title)
                            .font(.custom("Poppins-Bold", size: 15))
                            .foregroundColor(buttonTextColor(primaryButton.style))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(buttonBgColor(primaryButton.style))
                            )
                    }
                    .buttonStyle(.plain)

                    if let secondary = secondaryButton {
                        Button {
                            Haptics.lightImpact()
                            secondary.action()
                        } label: {
                            Text(secondary.title)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(themeStore.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .padding(.horizontal, 40)

        }
    }

    private func buttonBgColor(_ style: AlertButton.Style) -> Color {
        switch style {
        case .primary:
            return themeStore.mainText
        case .destructive:
            return themeStore.accentRed
        case .cancel:
            return themeStore.secondaryText.opacity(0.12)
        }
    }

    private func buttonTextColor(_ style: AlertButton.Style) -> Color {
        switch style {
        case .primary:
            return themeStore.cardBg
        case .destructive:
            return .white
        case .cancel:
            return themeStore.secondaryText
        }
    }
}
