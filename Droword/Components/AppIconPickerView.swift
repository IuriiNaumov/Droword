import SwiftUI

struct AppIconPickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @AppStorage(AppIconStyle.storageKey) private var storedIconStyle: String = AppIconStyle.classic.rawValue
    @State private var selected: AppIconStyle = .classic
    @State private var showPremiumWall = false
    @State private var toast: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("App icon")
                .sheetTitle()

            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(selected.accentColor.opacity(0.14))
                    .frame(width: 220, height: 220)
                    .blur(radius: 2)

                iconArtwork(selected, size: 128)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            VStack(spacing: 6) {
                Text(selected.title)
                    .font(themeStore.bold(22))
                    .foregroundStyle(themeStore.mainText)

                Text(selected == .classic
                     ? String(localized: "Default home screen icon")
                     : String(localized: "A fresh look for your Home Screen"))
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(AppIconStyle.allCases) { style in
                        Button {
                            Haptics.menuTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selected = style
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    iconArtwork(style, size: 64)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14.3, style: .continuous)
                                                .strokeBorder(
                                                    selected == style ? themeStore.mainAccentColor : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        }

                                    if selected == style {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(themeStore.mainAccentColor)
                                            .background(Circle().fill(themeStore.cardBg).padding(1))
                                            .padding(3)
                                    } else if style.requiresPremium && !isPremium {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                            .padding(3)
                                    }
                                }

                                Text(style.title)
                                    .font(themeStore.medium(12))
                                    .foregroundStyle(selected == style ? themeStore.mainText : themeStore.secondaryText)
                            }
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.95))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
            }
            .padding(.bottom, 20)

            Button {
                applySelected()
            } label: {
                HStack(spacing: 8) {
                    if currentApplied == selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Current icon")
                    } else if selected.requiresPremium && !isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("PRO")
                    } else {
                        Text("Set icon")
                    }
                }
                .duo3DStyle(
                    currentApplied == selected
                        ? themeStore.secondaryText.opacity(0.4)
                        : themeStore.mainAccentColor,
                    isDisabled: currentApplied == selected
                )
            }
            .buttonStyle(Duo3DButtonStyle())
            .disabled(currentApplied == selected)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .overlay(alignment: .top) {
            if let toast {
                BannerToastView(type: .success, message: toast, duration: 2.2)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .onAppear {
            selected = AppIconStyle.resolved(storedIconStyle)
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    private var currentApplied: AppIconStyle {
        AppIconStyle.resolved(storedIconStyle)
    }

    @ViewBuilder
    private func iconArtwork(_ style: AppIconStyle, size: CGFloat) -> some View {
        AppIconArtwork(style: style, size: size)
    }

    private func applySelected() {
        Haptics.menuTap()
        if selected.requiresPremium && !isPremium {
            showPremiumWall = true
            return
        }

        AppIconChanger.apply(selected) { appliedHomeScreen in
            storedIconStyle = selected.rawValue
            if selected != .classic && !appliedHomeScreen {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    toast = String(localized: "Saved — home screen icon coming soon")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { toast = nil }
                }
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
            .environmentObject(ThemeStore())
    }
}
