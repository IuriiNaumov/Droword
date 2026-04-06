import SwiftUI

struct FontSizePickerView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    private let steps: [CGFloat] = [0.85, 1.0, 1.15, 1.3]

    @State private var sliderIndex: Double = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Font Size")
                    .sheetTitle()

                wordCardPreview
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: themeStore.fontScale)

                // Slider section
                VStack(spacing: 12) {
                    // Current size label
                    Text(themeStore.fontScaleLabel)
                        .font(themeStore.medium(14))
                        .foregroundColor(themeStore.secondaryText)
                        .animation(.none, value: themeStore.fontScale)

                    HStack(spacing: 16) {
                        Text("A")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeStore.secondaryText)

                        GeometryReader { geo in
                            let trackWidth = geo.size.width
                            let stepCount = CGFloat(steps.count - 1)
                            let thumbSize: CGFloat = 28

                            ZStack(alignment: .leading) {
                                // Track background
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(themeStore.secondaryText.opacity(0.15))
                                    .frame(height: 4)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, (thumbSize - 4) / 2)

                                // Notch marks
                                ForEach(0..<steps.count, id: \.self) { i in
                                    let x = (trackWidth - thumbSize) * CGFloat(i) / stepCount + thumbSize / 2
                                    Circle()
                                        .fill(CGFloat(i) <= sliderIndex
                                              ? themeStore.mainAccentColor
                                              : themeStore.secondaryText.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .position(x: x, y: thumbSize / 2)
                                }

                                // Active track
                                let activeWidth = (trackWidth - thumbSize) * CGFloat(sliderIndex) / stepCount
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(themeStore.mainAccentColor)
                                    .frame(width: max(0, activeWidth + thumbSize / 2), height: 4)
                                    .padding(.vertical, (thumbSize - 4) / 2)

                                // Thumb
                                let thumbX = (trackWidth - thumbSize) * CGFloat(sliderIndex) / stepCount
                                Circle()
                                    .fill(themeStore.mainAccentColor)
                                    .frame(width: thumbSize, height: thumbSize)
                                    .shadow(color: themeStore.mainAccentColor.opacity(0.3), radius: 4, y: 2)
                                    .offset(x: thumbX)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let raw = (value.location.x - thumbSize / 2) / (trackWidth - thumbSize) * stepCount
                                                let clamped = min(max(raw, 0), stepCount)
                                                let snapped = (clamped * 2).rounded() / 2
                                                withAnimation(.interactiveSpring()) {
                                                    sliderIndex = snapped.rounded()
                                                }
                                                let newScale = steps[Int(sliderIndex.rounded())]
                                                if abs(themeStore.fontScale - newScale) > 0.01 {
                                                    Haptics.selection()
                                                    themeStore.fontScale = newScale
                                                }
                                            }
                                    )
                            }
                            .frame(height: thumbSize)
                        }
                        .frame(height: 28)

                        Text("A")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(themeStore.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeStore.cardBg)
                    )
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
            .onAppear {
                sliderIndex = Double(currentStepIndex)
            }
        }
    }

    // MARK: - Word Card Preview

    private var wordCardPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Serendipity")
                .font(themeStore.bold(24))
                .foregroundColor(themeStore.mainText)

            Text("/ˌsɛr.ənˈdɪp.ɪ.ti/")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.mainText.opacity(0.8))

            Text("Noun")
                .font(themeStore.regular(14))
                .foregroundColor(themeStore.mainText.opacity(0.8))
                .padding(.bottom, 2)

            Text("Счастливая случайность")
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.mainText)

            Text("Finding that book was pure serendipity.")
                .font(themeStore.regular(16))
                .foregroundColor(themeStore.mainText)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    // MARK: - Helpers

    private var currentStepIndex: Int {
        steps.enumerated().min(by: { abs($0.element - themeStore.fontScale) < abs($1.element - themeStore.fontScale) })?.offset ?? 1
    }
}

extension ThemeStore {
    var fontScaleLabel: String {
        switch fontScale {
        case ..<0.9: return String(localized: "Small")
        case 0.9..<1.1: return String(localized: "Default")
        case 1.1..<1.25: return String(localized: "Large")
        default: return String(localized: "Extra Large")
        }
    }
}
