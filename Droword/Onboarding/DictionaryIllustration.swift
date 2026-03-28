import SwiftUI

struct DictionaryIllustration: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let accent: Color
    let size: CGFloat
    let px: CGFloat
    let py: CGFloat

    private let tagColor: Color = .accentBlue

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.15))
                .frame(width: size * 0.75, height: size * 0.58)
                .rotationEffect(.degrees(-3))
                .offset(x: -size * 0.02 + px * 0.12, y: size * 0.02 + py * 0.08)

            VStack(alignment: .leading, spacing: 8) {
                // Tag badge — matches WordCardView tag style
                Text("Travel")
                    .font(themeStore.medium(13))
                    .foregroundColor(themeStore.accentBlue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(themeStore.accentBlue, lineWidth: 1)
                    )
                    .padding(.bottom, 2)

                // Header row — matches WordCardView headerRow
                HStack(alignment: .top, spacing: 8) {
                    Text("Serendipity")
                        .font(themeStore.bold(24))
                        .foregroundColor(themeStore.mainText)

                    Spacer()

                    // Static sound waves icon — matches WordCardView audio button
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeStore.mainText.opacity(0.4))
                        .padding(.top, 6)
                }

                // Transcription — matches WordCardView transcription
                Text("/ˌser.ənˈdɪp.ə.ti/")
                    .font(themeStore.regular(14))
                    .foregroundColor(themeStore.mainText.opacity(0.8))

                // Translation — matches WordCardView translation
                Text("Счастливая случайность")
                    .font(themeStore.regular(16))
                    .foregroundColor(themeStore.mainText)

                // Example with highlighted word — matches WordCardView example style
                Text("A \(Text("serendipity").font(themeStore.bold(16)).foregroundColor(.orange)) led me to this place.")
                    .font(themeStore.regular(16))
                    .foregroundColor(themeStore.mainText)
                    .fixedSize(horizontal: false, vertical: true)

                // Bottom row — matches WordCardView share/delete row
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(themeStore.mainText.opacity(0.8))
                    Spacer()
                    Image(systemName: "trash.fill")
                        .foregroundColor(.accentRed)
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(width: size * 0.75, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.cardBg)
            )
            .offset(x: px * 0.3, y: py * 0.2)
        }
        .allowsHitTesting(false)
    }
}
