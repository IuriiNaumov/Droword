import SwiftUI
import PhotosUI
import UIKit

struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let currentImage: UIImage?
    let onComplete: (UIImage?) -> Void

    @State private var showSourcePicker = true
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCropper = false

    var body: some View {
        ZStack {
            if showCamera {
                CameraView { image in
                    showCamera = false
                    if let image {
                        pickedImage = image
                        showSourcePicker = false
                        showCropper = true
                    } else {
                        showSourcePicker = true
                    }
                }
                .ignoresSafeArea()
            } else if showCropper, let pickedImage {
                AvatarCropView(image: pickedImage) { croppedImage in
                    onComplete(croppedImage)
                    dismiss()
                } onCancel: {
                    showCropper = false
                    self.pickedImage = nil
                    showSourcePicker = true
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if showSourcePicker {
                sourcePickerCard
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCropper)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSourcePicker)
        .animation(.easeInOut(duration: 0.2), value: showCamera)
        .presentationDetents([.medium])
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    pickedImage = uiImage
                    showSourcePicker = false
                    showCropper = true
                }
            }
        }
    }

    private var sourcePickerCard: some View {
        VStack(spacing: 0) {
            Text("Change photo")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.mainBlack)
                .padding(.top, 24)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                sourceButton(
                    icon: "camera.fill",
                    title: "Take a photo",
                    color: .blue
                ) {
                    showSourcePicker = false
                    showCamera = true
                }

                sourceButton(
                    icon: "photo.on.rectangle",
                    title: "Choose from gallery",
                    color: .green
                ) {
                    showPhotosPicker = true
                }

                if currentImage != nil {
                    sourceButton(
                        icon: "trash.fill",
                        title: "Remove photo",
                        color: .red
                    ) {
                        onComplete(nil)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.mainGrey)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)

            Spacer()
        }
    }

    private func sourceButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
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
                    .foregroundColor(.mainBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mainGrey.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Crop View

struct AvatarCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 300

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { onCancel() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }

                Spacer()

                Text("Move and scale")
                    .font(.custom("Poppins-Medium", size: 17))
                    .foregroundColor(.white)

                Spacer()

                Color.clear.frame(width: 42, height: 42)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            Spacer()

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize * scale, height: cropSize * scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                clampOffset()
                            }
                    )
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = max(1.0, min(newScale, 5.0))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                clampOffset()
                            }
                    )

                CropOverlay(cropSize: cropSize)
                    .allowsHitTesting(false)
            }
            .frame(width: cropSize + 40, height: cropSize + 40)

            Spacer()

            Button {
                let cropped = cropImage()
                onConfirm(cropped)
            } label: {
                Text("Choose")
                    .font(.custom("Poppins-Bold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.toastAndButtons)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func clampOffset() {
        let maxOffset = (cropSize * scale - cropSize) / 2
        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = max(-maxOffset, min(maxOffset, offset.width))
            offset.height = max(-maxOffset, min(maxOffset, offset.height))
            lastOffset = offset
        }
    }

    private func cropImage() -> UIImage {
        let rendererSize = CGSize(width: cropSize, height: cropSize)
        let renderer = UIGraphicsImageRenderer(size: rendererSize)

        return renderer.image { _ in
            let ctx = UIGraphicsGetCurrentContext()!

            // Clip to circle
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: rendererSize))
            ctx.addPath(circlePath.cgPath)
            ctx.clip()

            let imageSize = CGSize(width: cropSize * scale, height: cropSize * scale)
            let origin = CGPoint(
                x: (cropSize - imageSize.width) / 2 + offset.width,
                y: (cropSize - imageSize.height) / 2 + offset.height
            )

            image.draw(in: CGRect(origin: origin, size: imageSize))
        }
    }
}

private struct CropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.55))

            Circle()
                .frame(width: cropSize, height: cropSize)
                .blendMode(.destinationOut)
        }
        .compositingGroup()

        Circle()
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
            .frame(width: cropSize, height: cropSize)
    }
}


struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        private var didFinish = false

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard !didFinish else { return }
            didFinish = true
            let image = info[.originalImage] as? UIImage
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !didFinish else { return }
            didFinish = true
            onCapture(nil)
        }
    }
}
