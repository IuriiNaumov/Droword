import SwiftUI
import UIKit


struct LanguageCubePicker: View {
    @Binding var selectedLanguage: String
    var title: String
    var languages: [LanguageOption]
    var blockedLanguage: String? = nil

    let columns = [
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
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.75, blendDuration: 0.1)) {
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
                    .foregroundColor(isBlocked ? .gray : .mainBlack)
            }
            .frame(width: 110, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? language.color :
                          isBlocked ? Color.gray.opacity(0.15) :
                          language.color.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isBlocked ? Color.gray.opacity(0.4) :
                        language.color.opacity(isSelected ? 0.9 : 0.4),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isBlocked ? .clear :
                    language.color.opacity(isSelected ? 0.45 : 0.15),
                radius: isSelected ? 8 : 4,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(internalPressedState ? 0.96 : (isSelected ? 1.05 : 1.0))
            .opacity(isBlocked ? 0.5 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isSelected)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white, language.color)
                        .padding(8)
                        .shadow(radius: 3, y: 2)
                }
            }
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
