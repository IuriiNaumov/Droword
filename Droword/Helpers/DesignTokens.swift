import SwiftUI

/// Единые метрики дизайна — общий источник истины для радиусов, отступов и глубины.
/// Использование этих констант вместо «магических чисел» держит интерфейс консистентным
/// и упрощает сквозные изменения стиля.

enum DesignRadius {
    /// Мелкие элементы: чипы, бейджи, поля ввода
    static let small: CGFloat = 12
    /// Карточки, кнопки, ячейки списков — базовый радиус
    static let card: CGFloat = 16
    /// Крупные контейнеры и контент листов
    static let large: CGFloat = 20
    /// Диалоги и алерты
    static let dialog: CGFloat = 24
}

enum DesignSpacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let section: CGFloat = 28
}

// MARK: - Tactile press feedback

/// Лёгкий отклик на нажатие: кнопка чуть уменьшается и притухает.
/// Придаёт «живость» плоским кнопкам без тяжёлого 3D-эффекта.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card depth

/// Плоский стиль карточек: без рамок и теней. Оставлен как сквозной модификатор,
/// чтобы места вызова `.cardDepth()` не требовалось убирать и при желании можно
/// было вернуть глубину в одном месте.
struct CardDepthModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignRadius.card

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// Добавляет карточке тонкую рамку и мягкую тень (тема-зависимо).
    func cardDepth(cornerRadius: CGFloat = DesignRadius.card) -> some View {
        modifier(CardDepthModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Sheet modernization

extension View {
    /// Современное оформление модальных листов: индикатор перетаскивания и
    /// скруглённые углы — как в системных листах iOS.
    func modernSheet() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DesignRadius.dialog)
    }
}
