import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.isPremium) private var isPremium: Bool = false
    @State private var selectedPalette: ThemeStore.Palette = .colorful
    @State private var showPremiumWall = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Background")
                .sheetTitle()

            // Carousel
            TabView(selection: $selectedPalette) {
                ForEach(availablePalettes) { palette in
                    themePreviewPage(palette: palette)
                        .tag(palette)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedPalette)

            // Bottom: theme name + button
            VStack(spacing: 12) {
                let pc = ThemeStore.previewColors(for: selectedPalette)

                VStack(spacing: 4) {
                    Text(selectedPalette.title)
                        .font(themeStore.bold(20))
                        .foregroundColor(themeStore.mainText)

                    Text(selectedPalette.subtitle)
                        .font(themeStore.regular(14))
                        .foregroundColor(themeStore.secondaryText)
                }

                Button {
                    guard isPremium else {
                        showPremiumWall = true
                        return
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        themeStore.set(selectedPalette)
                    }
                    Haptics.selection()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        if themeStore.palette == selectedPalette {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("Current theme")
                        } else if !isPremium {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("PRO")
                        } else {
                            Text("Set theme")
                        }
                    }
                    .duo3DStyle(themeStore.palette == selectedPalette
                                ? themeStore.secondaryText.opacity(0.4)
                                : pc.mainAccentColor,
                                isDisabled: themeStore.palette == selectedPalette)
                }
                .buttonStyle(Duo3DButtonStyle(isDuolingo: themeStore.isDuolingo))
                .disabled(themeStore.palette == selectedPalette)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .tint(themeStore.accentPurple)
        .onAppear {
            selectedPalette = themeStore.palette
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(themeStore.accentPurple)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(themeStore.accentPurple.opacity(0.25))
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
                .tint(themeStore.mainAccentColor)
        }
    }

    // MARK: - Theme Preview Page

    private func themePreviewPage(palette: ThemeStore.Palette) -> some View {
        let c = ThemeStore.previewColors(for: palette)

        return VStack(spacing: 0) {
            // Phone frame
            VStack(spacing: 12) {
                // Profile area
                HStack(spacing: 10) {
                    Circle()
                        .fill(c.mainAccentColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(c.mainAccentColor)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(c.mainText.opacity(0.7))
                            .frame(width: 80, height: 10)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(c.secondaryText.opacity(0.4))
                            .frame(width: 50, height: 7)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Stats row
                HStack(spacing: 8) {
                    miniStatCard("42", title: "Total", c: c)
                    miniStatCard("3", title: "Today", c: c)
                    miniStatCard("15m", title: "Time", c: c)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                // Word card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Travel")
                        .font(c.medium(11))
                        .foregroundColor(c.accentBlue)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(c.accentBlue, lineWidth: 1)
                        )

                    Text("Serendipity")
                        .font(c.bold(18))
                        .foregroundColor(c.mainText)

                    Text("/ˌsɛr.ənˈdɪp.ɪ.ti/")
                        .font(c.regular(11))
                        .foregroundColor(c.mainText.opacity(0.7))

                    Text("Noun")
                        .font(c.regular(11))
                        .foregroundColor(c.mainText.opacity(0.7))

                    Divider()
                        .background(c.secondaryText.opacity(0.2))

                    Text("Счастливая случайность")
                        .font(c.regular(12))
                        .foregroundColor(c.mainText)

                    Text("Finding that book was pure serendipity.")
                        .font(c.regular(12))
                        .foregroundColor(c.mainText)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(c.isGlass ? c.appBg.opacity(0.5) : c.cardBg)
                )
                .padding(.horizontal, 16)

                // Second card placeholder
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(c.mainText.opacity(0.15))
                        .frame(width: 60, height: 8)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(c.mainText.opacity(0.5))
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(c.mainText.opacity(0.12))
                        .frame(width: 90, height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(c.isGlass ? c.appBg.opacity(0.5) : c.cardBg)
                )
                .padding(.horizontal, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(c.appBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(c.secondaryText.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Mini Stat Card

    private func miniStatCard(_ value: String, title: String, c: ThemeStore.PreviewColors) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(c.bold(16))
                .foregroundColor(c.mainText)
            Text(title)
                .font(c.medium(10))
                .foregroundColor(c.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(c.isGlass ? c.appBg.opacity(0.5) : c.cardBg)
        )
    }

    // MARK: - Helpers

    private var availablePalettes: [ThemeStore.Palette] {
        ThemeStore.Palette.allCases.filter { palette in
            if palette.requiresIOS26 {
                if #available(iOS 26, *) { return true }
                return false
            }
            return true
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
            .environmentObject(ThemeStore())
    }
}
