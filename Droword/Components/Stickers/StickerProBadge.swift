import SwiftUI

struct StickerProBadge: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var height: CGFloat = 52

    var body: some View {
        let unit = height / 60
        let tone = StickerTone.purple
        ZStack {
            Capsule().sticker(tone, unit: unit)

            Capsule()
                .fill(tone.highlight)
                .frame(width: height * 0.32, height: height * 0.09)
                .offset(x: -height * 0.56, y: -height * 0.3)

            Text("PRO")
                .font(themeStore.bold(height * 0.42))
                .tracking(height * 0.04)
                .foregroundStyle(.white)
        }
        .frame(width: height * 1.9, height: height)
        .padding(.trailing, height * 0.07)
        .padding(.bottom, height * 0.08)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("PRO"))
    }
}

#Preview {
    VStack(spacing: 24) {
        StickerProBadge()
        StickerProBadge(height: 40)
    }
    .padding()
    .environmentObject(ThemeStore())
}
