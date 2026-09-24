import SwiftUI
import PhotosUI
import UIKit

struct AvatarPickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    let currentImage: UIImage?
    let onPickedRaw: (UIImage) -> Void
    let onRemoved: () -> Void

    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingCameraImage: UIImage?

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
                            onRemoved()
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
                    CloseButton()
                }
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedItem = nil
                        onPickedRaw(uiImage)
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if let image = pendingCameraImage {
                pendingCameraImage = nil
                onPickedRaw(image)
                dismiss()
            }
        }) {
            CameraView { image in
                pendingCameraImage = image
                showCamera = false
            }
            .ignoresSafeArea()
        }
    }

    private func sourceButton(icon: String, title: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(themeStore.isGlass ? 0.22 : 0.12))
                        .frame(width: 44, height: 44)
                        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, shape: .capsule))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(themeStore.medium(16))
                    .foregroundStyle(themeStore.mainText)

                Spacer()

                DisclosureChevron()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                    .fill(themeStore.isGlass ? color.opacity(0.18) : themeStore.cardBg)
            )
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
    }
}

struct CroppableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ImageCropperView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 4
    private let outputSize: CGFloat = 512

    var body: some View {
        GeometryReader { geo in
            let cropSize = min(geo.size.width, geo.size.height) - 48

            ZStack {
                Color.black.ignoresSafeArea()

                imageLayer(cropSize: cropSize)
                    .gesture(dragGesture(cropSize: cropSize))
                    .simultaneousGesture(magnifyGesture(cropSize: cropSize))

                CropMask(cropSize: cropSize)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay(alignment: .top) {
                Text("Move and Scale")
                    .font(themeStore.medium(15))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 24)
            }
            .overlay(alignment: .bottom) {
                controls(cropSize: cropSize)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func imageLayer(cropSize: CGFloat) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: cropSize, height: cropSize)
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: cropSize, height: cropSize)
            .clipped()
    }

    private func dragGesture(cropSize: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clamp(proposed, cropSize: cropSize, scale: scale)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func magnifyGesture(cropSize: CGFloat) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = min(max(lastScale * value.magnification, minScale), maxScale)
                scale = newScale
                offset = clamp(offset, cropSize: cropSize, scale: newScale)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private func baseFillSize(cropSize: CGFloat) -> CGSize {
        let aspect = image.size.width / max(image.size.height, 1)
        if aspect >= 1 {
            return CGSize(width: cropSize * aspect, height: cropSize)
        } else {
            return CGSize(width: cropSize, height: cropSize / aspect)
        }
    }

    private func clamp(_ proposed: CGSize, cropSize: CGFloat, scale: CGFloat) -> CGSize {
        let base = baseFillSize(cropSize: cropSize)
        let maxX = max(0, (base.width * scale - cropSize) / 2)
        let maxY = max(0, (base.height * scale - cropSize) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    @MainActor
    private func renderCroppedImage(cropSize: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: imageLayer(cropSize: cropSize))
        renderer.scale = outputSize / cropSize
        renderer.isOpaque = true
        return renderer.uiImage
    }

    private func controls(cropSize: CGFloat) -> some View {
        HStack {
            Button {
                Haptics.menuTap()
                onCancel()
            } label: {
                Text("Cancel")
                    .font(themeStore.medium(17))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                Haptics.menuTap()
                if let cropped = renderCroppedImage(cropSize: cropSize) {
                    onCrop(cropped)
                }
            } label: {
                Text("Choose")
                    .font(themeStore.bold(17))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 36)
    }
}

private struct CropMask: View {
    let cropSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .reverseMask {
                    Circle().frame(width: cropSize, height: cropSize)
                }
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: cropSize, height: cropSize)
        }
    }
}

private extension View {

    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .center) {
                    mask()
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
        }
    }
}

#Preview {
    AvatarPickerView(
        currentImage: nil,
        onPickedRaw: { _ in },
        onRemoved: {}
    )
    .environmentObject(ThemeStore())
}
