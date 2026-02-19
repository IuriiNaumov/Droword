import SwiftUI
import UIKit

struct LanguageCubePicker: View {
    @Binding var selectedLanguage: String
    var title: String
    var languages: [LanguageOption]
    var blockedLanguage: String? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.mainBlack)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(languages) { lang in
                    let isBlocked = lang.name == blockedLanguage

                    LanguageCube(
                        language: lang,
                        isSelected: selectedLanguage == lang.name,
                        isBlocked: isBlocked
                    ) {
                        if !isBlocked {
                            let generator = UIImpactFeedbackGenerator(style: .soft)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                selectedLanguage = lang.name
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}

struct LanguageCube: View {
    let language: LanguageOption
    let isSelected: Bool
    let isBlocked: Bool
    let onTap: () -> Void

    @State private var internalPressedState: Bool = false

    private var textColor: Color {
        if isBlocked { return .gray }
        if isSelected { return language.color.darker(by: 0.55) }
        return language.color.darker(by: 0.4)
    }

    var body: some View {
        Button(action: {
            if !isBlocked {
                onTap()
            }
        }) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 42))

                Text(language.name)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(textColor)
            }
            .frame(width: 110, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        isSelected
                        ? language.color
                        : isBlocked
                        ? Color.gray.opacity(0.15)
                        : language.color.opacity(0.25)
                    )
            )

            .scaleEffect(internalPressedState ? 0.96 : (isSelected ? 1.05 : 1.0))
            .opacity(isBlocked ? 0.5 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isBlocked)
        .pressAction { pressed in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                internalPressedState = pressed
            }
        }
    }
}

extension Color {
    func darker(by amount: Double = 0.3) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: max(r - amount, 0),
            green: max(g - amount, 0),
            blue: max(b - amount, 0),
            opacity: a
        )
    }
}

extension View {
    func pressAction(onChange: @escaping (Bool) -> Void) -> some View {
        modifier(PressActionsModifier(onChange: onChange))
    }
}

private struct PressActionsModifier: ViewModifier {
    @State private var isPressed = false
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onChange(true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onChange(false)
                    }
            )
    }
}

#Preview {
    LanguageCubePicker(
        selectedLanguage: .constant("Español"),
        title: "I speak",
        languages: previewLanguages
    )
}

#Preview("Dark") {
    LanguageCubePicker(
        selectedLanguage: .constant("English"),
        title: "I’m learning",
        languages: previewLanguages
    )
    .preferredColorScheme(.dark)
}

private let previewLanguages = [
    LanguageOption(name: "English", flag: "🇬🇧", color: Color(hex: "#CDEBF1")),
    LanguageOption(name: "Español", flag: "🇲🇽", color: Color(hex: "#DEF1D0")),
    LanguageOption(name: "Русский", flag: "🇷🇺", color: Color(hex: "#FFE6A7"))
]
