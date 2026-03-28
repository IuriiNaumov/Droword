import SwiftUI
import UserNotifications

struct AddTagView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var colorHex: String = ""

    @State private var isSaving = false
    @State private var didRequestNotifications = false

    var body: some View {
        ZStack {
            themeStore.appBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Text("New Tag")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Button { dismiss() } label: {
                            CloseButtonIcon()
                                .environmentObject(themeStore)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }.padding(.top, 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(themeStore.secondaryText)

                    FormTextField(
                        title: "Enter tag name",
                        text: $name,
                        maxLength: 40,
                        showCounter: true
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(themeStore.secondaryText)

                    FormTextField(
                        title: "e.g. #FFAA33",
                        text: $colorHex,
                        maxLength: 7,
                        showCounter: false
                    ).overlay(alignment: .trailing) {
                        Circle()
                            .fill(parsedColor ?? Color.gray)
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 12)
                            .allowsHitTesting(false)
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Text("Suggested")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(themeStore.secondaryText)
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        ForEach(suggestedColors, id: \.hex) { item in
                            Button {
                                colorHex = item.hex
                                Haptics.selection()
                            } label: {
                                Circle()
                                    .fill(Color(item.assetName))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(colorHex == item.hex ? themeStore.mainText : Color.clear, lineWidth: 2)
                                            .padding(-2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                Button(action: { saveTag() }) {
                    Text(isSaving ? "Adding..." : "Add")
                        .duo3DStyle(themeStore.mainAccentColor, isDisabled: isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .buttonStyle(Duo3DButtonStyle())
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .task {
            if !didRequestNotifications {
                didRequestNotifications = true
                NotificationManager.shared.requestAuthorization()
            }
        }
    }

    private struct SuggestedColor {
        let hex: String
        let assetName: String
    }

    private let suggestedColors: [SuggestedColor] = [
        SuggestedColor(hex: "#D86B94", assetName: "AccentPink"),
        SuggestedColor(hex: "#5B9BD5", assetName: "AccentBlue"),
        SuggestedColor(hex: "#7D71C8", assetName: "AccentPurple"),
        SuggestedColor(hex: "#38B05B", assetName: "AccentGreen"),
        SuggestedColor(hex: "#EBA130", assetName: "AccentGold"),
        SuggestedColor(hex: "#E04F4F", assetName: "AccentRed"),
    ]

    private var parsedColor: Color? {
        let trimmed = colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = TagStore.shared.normalizeHex(trimmed)
        return Color(fromHexString: normalized)
    }

    private func saveTag() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let normalized = TagStore.shared.normalizeHex(colorHex)
        TagStore.shared.addTag(name: trimmedName, colorHex: normalized)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    AddTagView()
}
