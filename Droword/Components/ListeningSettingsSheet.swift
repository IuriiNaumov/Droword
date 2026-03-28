import SwiftUI

struct ListeningSettingsSheet: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var settings: ListeningSettings
    var onSave: () -> Void

    private let unifiedCornerRadius: CGFloat = 16

    @Environment(\.dismiss) private var dismiss

    private let pauseOptions: [(String, Double)] = [
        ("1s", 1),
        ("2s", 2),
        ("3s", 3),
        ("5s", 5),
        ("7s", 7),
    ]

    private let repeatOptions: [(String, Int)] = [
        ("1x", 1),
        ("2x", 2),
        ("3x", 3),
    ]

    private let sleepOptions: [(String, Int)] = [
        ("Off", 0),
        ("10m", 10),
        ("15m", 15),
        ("20m", 20),
        ("30m", 30),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    settingSection(title: "Recall pause") {
                        segmentedPicker(
                            options: pauseOptions,
                            selected: settings.pauseDuration,
                            onSelect: { settings.pauseDuration = $0 }
                        )
                    }

                    settingSection(title: "Word order") {
                        segmentedPicker(
                            options: [
                                ("Foreign first", false),
                                ("Native first", true),
                            ],
                            selected: settings.nativeFirst,
                            onSelect: { settings.nativeFirst = $0 }
                        )
                    }

                    settingRow(title: "Example sentences", isOn: $settings.includeExamples)

                    settingRow(title: "Shuffle order", isOn: $settings.shuffle)

                    settingRow(title: "Hard words only", isOn: $settings.hardWordsOnly)

                    settingSection(title: "Repetitions per word") {
                        segmentedPicker(
                            options: repeatOptions,
                            selected: settings.repeatCount,
                            onSelect: { settings.repeatCount = $0 }
                        )
                    }

                    settingSection(title: "Sleep timer") {
                        segmentedPicker(
                            options: sleepOptions,
                            selected: settings.sleepTimerMinutes,
                            onSelect: { settings.sleepTimerMinutes = $0 }
                        )
                    }
                }
                .padding(24)
            }
            .background(themeStore.appBg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                    .font(.custom("Poppins-Medium", size: 16))
                }
            }
        }
    }

    @ViewBuilder
    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(themeStore.mainText)
            content()
        }
    }

    private func settingRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(themeStore.mainText)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(themeStore.mainText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }

    private func segmentedPicker<T: Equatable>(
        options: [(String, T)],
        selected: T,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                let isSelected = opt.1 == selected
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onSelect(opt.1)
                    }
                    Haptics.selection()
                } label: {
                    Text(opt.0)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(isSelected ? .white : themeStore.mainText)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: unifiedCornerRadius - 4)
                                .fill(isSelected ? themeStore.mainAccentColor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: unifiedCornerRadius, style: .continuous)
                .fill(themeStore.cardBg)
        )
    }
}
