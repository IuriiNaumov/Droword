import SwiftUI
import PhotosUI
import UIKit

struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let currentImage: UIImage?
    let onComplete: (UIImage?) -> Void

    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCropper = false

    var body: some View {
        sourcePickerCard
            .presentationDetents([.medium])
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImage = uiImage
                        showCropper = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    if let image {
                        pickedImage = image
                        showCropper = true
                    }
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showCropper) {
                if let pickedImage {
                    AvatarCropView(image: pickedImage) { croppedImage in
                        onComplete(croppedImage)
                        dismiss()
                    } onCancel: {
                        showCropper = false
                        self.pickedImage = nil
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

struct AvatarCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let cropSize = geo.size.width - 48

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize(for: cropSize).width * scale,
                           height: imageSize(for: cropSize).height * scale)
                    .offset(offset)
                    .allowsHitTesting(false)

                CropOverlay(cropSize: cropSize)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack {
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
                    .padding(.top, geo.safeAreaInsets.top + 8)

                    Spacer()

                    Button {
                        let cropped = cropImage(cropSize: cropSize)
                        onConfirm(cropped)
                    } label: {
                        Text("Choose")
                            .font(.custom("Poppins-Bold", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.accentBlack)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
            }
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            clampOffset(cropSize: cropSize)
                        },
                    MagnifyGesture()
                        .onChanged { value in
                            let newScale = lastScale * value.magnification
                            scale = max(1.0, min(newScale, 5.0))
                        }
                        .onEnded { _ in
                            lastScale = scale
                            clampOffset(cropSize: cropSize)
                        }
                )
            )
        }
        .ignoresSafeArea()
    }

    /// Computes the image display size so the shorter side fills the crop circle.
    private func imageSize(for cropSize: CGFloat) -> CGSize {
        let imgW = image.size.width
        let imgH = image.size.height
        guard imgW > 0, imgH > 0 else { return CGSize(width: cropSize, height: cropSize) }
        let aspect = imgW / imgH
        if aspect > 1 {
            return CGSize(width: cropSize * aspect, height: cropSize)
        } else {
            return CGSize(width: cropSize, height: cropSize / aspect)
        }
    }

    private func clampOffset(cropSize: CGFloat) {
        let size = imageSize(for: cropSize)
        let displayW = size.width * scale
        let displayH = size.height * scale
        let maxOffsetX = max(0, (displayW - cropSize) / 2)
        let maxOffsetY = max(0, (displayH - cropSize) / 2)
        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = max(-maxOffsetX, min(maxOffsetX, offset.width))
            offset.height = max(-maxOffsetY, min(maxOffsetY, offset.height))
            lastOffset = offset
        }
    }

    private func cropImage(cropSize: CGFloat) -> UIImage {
        let outputSize = CGSize(width: cropSize * 2, height: cropSize * 2)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        return renderer.image { _ in
            let ctx = UIGraphicsGetCurrentContext()!
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: outputSize))
            ctx.addPath(circlePath.cgPath)
            ctx.clip()

            let size = imageSize(for: cropSize)
            let drawW = size.width * scale * 2
            let drawH = size.height * scale * 2
            let origin = CGPoint(
                x: (outputSize.width - drawW) / 2 + offset.width * 2,
                y: (outputSize.height - drawH) / 2 + offset.height * 2
            )
            image.draw(in: CGRect(origin: origin, size: CGSize(width: drawW, height: drawH)))
        }
    }
}

private struct CropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.55))

                Circle()
                    .frame(width: cropSize, height: cropSize)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()

            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .frame(width: cropSize, height: cropSize)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
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
