import SwiftUI

struct HapticSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @AppStorage(AppStorageKeys.hapticFeel) private var hapticFeel: String = HapticFeel.soft.rawValue

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Haptics")
                    .sheetTitle()

                Text("Pick the feel. Tap a row to use it, or play a sample first.")
                    .font(themeStore.regular(14))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(HapticFeel.allCases) { feel in
                        hapticRow(feel)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
    }

    private func hapticRow(_ feel: HapticFeel) -> some View {
        let selected = hapticFeel == feel.rawValue
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(themeStore.secondaryText.opacity(0.18))
                    .frame(width: 22, height: 22)
                if selected {
                    Circle()
                        .fill(themeStore.mainAccentColor)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feel.title)
                    .font(themeStore.medium(16))
                    .foregroundStyle(.primary)
                Text(feel.description)
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
            }

            Spacer()

            if feel != .off {
                Button {
                    Haptics.preview(feel)
                } label: {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeStore.mainText)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Play \(feel.title)"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.card))
        .contentShape(Rectangle())
        .onTapGesture {
            select(feel)
        }
    }

    private func select(_ feel: HapticFeel) {
        withAnimation(.easeInOut(duration: 0.15)) {
            hapticFeel = feel.rawValue
        }
        Haptics.preview(feel)
    }
}
