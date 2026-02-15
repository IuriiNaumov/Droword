import SwiftUI

struct VoiceOption: Identifiable, Equatable {
    let id = UUID()
    let key: String
    let title: String
    let description: String
}

struct VoicePickerView: View {
    @Binding var selectedKey: String
    var options: [VoiceOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(options) { option in
                Button(action: { select(option) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(Color.mainGrey.opacity(0.4), lineWidth: 2)
                                .frame(width: 22, height: 22)
                            if option.key == selectedKey {
                                Circle()
                                    .fill(Color("MainGreen"))
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
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.cardBackground)
                }
                .buttonStyle(.plain)
            }
        }
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func select(_ option: VoiceOption) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            selectedKey = option.key
        }
        // Persist immediately so AudioManager picks it up without app relaunch
        UserDefaults.standard.set(selectedKey, forKey: "ttsVoice")
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
