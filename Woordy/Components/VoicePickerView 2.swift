import SwiftUI
import AVFoundation

struct VoiceOption: Identifiable, Equatable {
    let id = UUID()
    let key: String
    let title: String
    let description: String
}

struct VoicePickerView: View {
    @Binding var selectedKey: String
    var options: [VoiceOption]
    @State private var previewingKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(options) { option in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Color.mainGrey.opacity(0.4), lineWidth: 1)
                            .frame(width: 22, height: 22)
                        if option.key == selectedKey {
                            Circle()
                                .fill(Color.toastAndButtons)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.mainBlack)
                        Text(option.description)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.mainGrey)
                    }
                    Spacer()

                    Button(action: { preview(option) }) {
                        SoundWavesView(isPlaying: previewingKey == option.key)
                            .frame(width: 24, height: 24)
                            .tint(.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Preview voice \(option.title)")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cardBackground)
                )
                .contentShape(Rectangle())
                .onTapGesture { select(option) }
            }
        }
    }

    private func select(_ option: VoiceOption) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            selectedKey = option.key
        }
      
        UserDefaults.standard.set(selectedKey, forKey: "ttsVoice")
    }

    private let previewPhrases: [String] = [
        "Hey, how are you doing today?",
        "Nice to hear from you!",
        "Hope you're having a great day!",
        "Hello there, what's new?",
        "It's great to talk with you!"
    ]

    private func preview(_ option: VoiceOption) {
        let phrase = previewPhrases.randomElement() ?? "Hey, how are you doing today?"
        Task {
            previewingKey = option.key
            await AudioManager.shared.play(text: phrase, voiceKey: option.key)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if previewingKey == option.key { previewingKey = nil }
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var key = "coral"
        var body: some View {
            VoicePickerView(
                selectedKey: $key,
                options: [
                    VoiceOption(key: "coral", title: "Coral", description: "soft, neutral"),
                    VoiceOption(key: "alloy", title: "Alloy", description: "friendly, warm"),
                    VoiceOption(key: "verse", title: "Verse", description: "energetic, expressive"),
                    VoiceOption(key: "sage", title: "Sage", description: "calm, confident")
                ]
            )
        }
    }
    return Demo()
}
