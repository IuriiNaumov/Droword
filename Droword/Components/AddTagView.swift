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
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Text("New Tag")
                        .font(.custom("Poppins-Bold", size: 26))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.mainGrey)
                                .padding(8)
                                .background(Color.mainGrey.opacity(0.12))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                }.padding(.top, 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(Color.mainGrey)

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
                        .foregroundColor(Color.mainGrey)

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
                }

                Spacer()

                Button(action: { saveTag() }) {
                    Text(isSaving ? "Adding..." : "Add")
                        .duo3DStyle(Color.accentBlack, isDisabled: isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        NotificationManager.shared.scheduleDailyReminder(hour: 20, minute: 0, tagName: trimmedName)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    AddTagView()
}
