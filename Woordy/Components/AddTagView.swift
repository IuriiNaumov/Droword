import SwiftUI

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var colorHex: String = ""

    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("New Tag") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name", text: $name)

                        ZStack(alignment: .trailing) {
                            TextField("Color (e.g. #111111)", text: $colorHex)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Circle()
                                .fill(parsedColor ?? Color.gray)
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)
                        }
                    }
                }
            }
            .navigationTitle("Add Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveTag()
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
        dismiss()
    }
}

#Preview {
    AddTagView()
}
