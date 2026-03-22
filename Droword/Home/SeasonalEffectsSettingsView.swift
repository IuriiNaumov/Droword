import SwiftUI

struct SeasonalEffectsSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("seasonalEffectsEnabled") private var seasonalEffectsEnabled: Bool = false
    @AppStorage("seasonalAnimationEnabled") private var seasonalAnimationEnabled: Bool = true
    @AppStorage("isPremium") private var isPremium: Bool = false
    @State private var showPremiumWall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Seasonal effects")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Decorative elements that change with the season — cherry blossoms in spring, snowflakes in winter, and more.")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                VStack(spacing: 0) {
                    toggleRow(
                        icon: "sparkles",
                        color: themeStore.iconPink,
                        title: "Show effects",
                        isOn: isPremium ? $seasonalEffectsEnabled : .constant(false)
                    )
                    .onTapGesture {
                        if !isPremium { showPremiumWall = true }
                    }

                    if seasonalEffectsEnabled && isPremium {
                        Divider().padding(.leading, 68)

                        toggleRow(
                            icon: "wind",
                            color: themeStore.iconBlue,
                            title: "Animate",
                            isOn: $seasonalAnimationEnabled
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .animation(.easeInOut(duration: 0.25), value: seasonalEffectsEnabled)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current season")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(themeStore.secondaryText)

                    let season = Season.current
                    HStack(spacing: 8) {
                        Text(season.shapes.first?.emoji ?? "")
                            .font(.system(size: 28))
                        Text(seasonName(season))
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                if seasonalEffectsEnabled {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeStore.cardBg)
                            .frame(height: 180)
                        SeasonalOverlayView(animated: seasonalAnimationEnabled)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .allowsHitTesting(false)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .fullScreenCover(isPresented: $showPremiumWall) {
            PremiumView(asWall: true)
                .environmentObject(themeStore)
        }
    }

    private func toggleRow(icon: String, color: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(themeStore.buttonAccent)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(themeStore.cardBg)
    }

    private func seasonName(_ season: Season) -> String {
        switch season {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        }
    }
}
