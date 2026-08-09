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
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("New Tag")
                    .sheetTitle()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name")
                            .font(themeStore.regular(18))
                            .foregroundStyle(themeStore.secondaryText)
                        Spacer()
                        Text("\(name.count)/40")
                            .font(themeStore.regular(14))
                            .foregroundStyle(themeStore.secondaryText.opacity(0.6))
                    }

                    FormTextField(
                        title: "Enter tag name",
                        text: $name,
                        maxLength: 40
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(themeStore.regular(18))
                        .foregroundStyle(themeStore.secondaryText)

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
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        ForEach(suggestedColors, id: \.hex) { item in
                            Button {
                                colorHex = item.hex
                                Haptics.selection()
                            } label: {
                                Circle()
                                    .fill(item.color)
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(themeStore.appBg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        CloseButtonIcon()
                            .environmentObject(themeStore)
                    }
                }
            }
        }
        .task {
            if !didRequestNotifications {
                didRequestNotifications = true
                NotificationManager.shared.requestAuthorization()
            }
        }
    }

    private var suggestedColors: [(hex: String, color: Color)] {
        [
            ("#D86B94", themeStore.accentPink),
            ("#5B9BD5", themeStore.accentBlue),
            ("#7D71C8", themeStore.accentPurple),
            ("#38B05B", themeStore.accentGreen),
            ("#EBA130", themeStore.accentGold),
            ("#E04F4F", themeStore.accentRed),
        ]
    }

    private var parsedColor: Color? {
        if let match = suggestedColors.first(where: { $0.hex == colorHex }) {
            return match.color
        }
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
