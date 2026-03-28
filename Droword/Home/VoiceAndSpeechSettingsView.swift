import SwiftUI

struct VoiceAndSpeechSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ttsVoice") private var ttsVoice: String = "coral"
    @AppStorage("ttsRate") private var ttsRate: Double = 1.0

    private let speedOptions: [Double] = [0.75, 0.9, 1.0, 1.25, 1.5]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Voice & Speech")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Voice")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                VoicePickerView(
                    selectedKey: $ttsVoice,
                    options: [
                        VoiceOption(key: "coral", title: "Coral", description: "soft, neutral"),
                        VoiceOption(key: "alloy", title: "Alloy", description: "friendly, warm"),
                        VoiceOption(key: "verse", title: "Verse", description: "energetic, expressive"),
                        VoiceOption(key: "sage", title: "Sage", description: "calm, confident")
                    ]
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Speed")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(speedOptions, id: \.self) { option in
                            RadioButtonRow(
                                title: String(format: "%.2fx", option),
                                isSelected: ttsRate == option
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) { ttsRate = option }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        
    }
}
