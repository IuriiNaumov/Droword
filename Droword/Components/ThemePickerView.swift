import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Theme")
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                VStack(spacing: 16) {
                    paletteRow(title: "Colorful", palette: .colorful)
                    paletteRow(title: "Monochrome", palette: .monochrome)
                }

                Spacer(minLength: 0)

                Button(action: { dismiss() }) {
                    Text("Save")
                        .duo3DStyle(Color.accentGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private func paletteRow(title: String, palette: ThemeStore.Palette) -> some View {
        let isSelected = themeStore.palette == palette
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                themeStore.set(palette)
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentBlue)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.accentBlue : Color.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerView()
        .environmentObject(ThemeStore())
}
