import SwiftUI
import PhotosUI
import UIKit

struct AvatarPickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    let currentImage: UIImage?
    let onComplete: (UIImage?) -> Void

    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Change photo")
                    .sheetTitle()

                VStack(spacing: 12) {
                    sourceButton(
                        icon: "camera.fill",
                        title: "Take a photo",
                        color: Color.accentBlue
                    ) {
                        showCamera = true
                    }

                    sourceButton(
                        icon: "photo.on.rectangle",
                        title: "Choose from gallery",
                        color: Color.accentGreen
                    ) {
                        showPhotosPicker = true
                    }

                    if currentImage != nil {
                        sourceButton(
                            icon: "trash.fill",
                            title: "Remove photo",
                            color: Color.accentRed
                        ) {
                            onComplete(nil)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
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
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    onComplete(uiImage)
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                showCamera = false
                if let image {
                    onComplete(image)
                    dismiss()
                }
            }
            .ignoresSafeArea()
        }
    }

    private func sourceButton(icon: String, title: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(themeStore.mainText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeStore.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeStore.cardBg)
            )
        }
        .buttonStyle(.plain)
    }
}


