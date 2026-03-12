import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false

    var body: some View {
        ZStack {
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

                    Button(action: {
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .duo3DStyle(Color.accentBlack)
                    }
                    .buttonStyle(Duo3DButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(Color.appBackground.ignoresSafeArea())

            if showToast {
                BannerToastView(type: .success, message: "Saved", duration: 1.5)
            }
        }
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
                        .foregroundColor(.mainBlack)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.mainBlack : Color.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerView()
        .environmentObject(ThemeStore())
}
