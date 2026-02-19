import SwiftUI
import UserNotifications

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var colorHex: String = ""

    @State private var isSaving = false
    @State private var didRequestNotifications = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color(.mainGrey))

                        FormTextField(
                            title: "Enter tag name",
                            text: $name,
                            focusedColor: .mainGrey
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(Color(.mainGrey))

                        FormTextField(
                            title: "e.g. #FFAA33",
                            text: $colorHex,
                            focusedColor: .mainGrey
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Adding..." : "Add") {
                        saveTag()
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        dismiss()
    }
}

#Preview {
    AddTagView()
}
