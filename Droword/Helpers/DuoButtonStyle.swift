import SwiftUI

struct Duo3DStyle: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    let bgColor: Color
    var isDisabled: Bool = false
    var force3D: Bool = false
    var verticalPadding: CGFloat = DesignSpacing.buttonVertical

    @Environment(\.colorScheme) private var colorScheme

    private var use3D: Bool { (force3D || themeStore.isDuolingo) && !themeStore.isGlass }
    private var usePixel: Bool { themeStore.isPixel }
    private var radius: CGFloat { usePixel ? 0 : (use3D ? 16 : themeStore.controlRadius) }
    private var lip: CGFloat { use3D || usePixel ? 4 : 0 }

    private var primaryLabelColor: Color {
        if isDisabled {
            return use3D ? themeStore.mutedControlText : .white
        }
        if themeStore.isGlass {
            return colorScheme == .dark ? .white : .black
        }
        return .white
    }

    private var faceColor: Color {
        if isDisabled {
            return use3D ? themeStore.mutedControl : themeStore.secondaryText.opacity(0.4)
        }
        return bgColor
    }

    private var lipColor: Color {
        if isDisabled {
            return Color(hex: "#AFAFAF").opacity(0.55)
        }
        return darkerShade(of: faceColor, by: 0.16)
    }

    func body(content: Content) -> some View {
        content
            .font(themeStore.bold(17))
            .foregroundStyle(primaryLabelColor)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if themeStore.isGlass {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(isDisabled
                                  ? themeStore.secondaryText.opacity(0.25)
                                  : bgColor.opacity(0.28))
                    } else if usePixel {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(themeStore.pixelShadow)
                            .offset(x: 4, y: 4)
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(faceColor)
                            .overlay {
                                RoundedRectangle(cornerRadius: radius, style: .continuous)
                                    .strokeBorder(themeStore.pixelInk, lineWidth: 2)
                            }
                    } else if use3D {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(lipColor)
                            .offset(y: lip)

                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(faceColor)
                    } else if isDisabled {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(themeStore.secondaryText.opacity(0.4))
                    } else {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(bgColor)
                    }
                }
            )
            .padding(.bottom, lip)
            .padding(.trailing, usePixel ? 4 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass && !isDisabled, cornerRadius: radius))
    }
}

struct Duo3DSecondaryStyle: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore

    private var use3D: Bool { themeStore.isDuolingo && !themeStore.isGlass }
    private var usePixel: Bool { themeStore.isPixel }
    private var radius: CGFloat { usePixel ? 0 : (use3D ? 16 : themeStore.controlRadius) }

    func body(content: Content) -> some View {
        content
            .font(themeStore.bold(17))
            .foregroundStyle(themeStore.mainText)
            .padding(.vertical, DesignSpacing.buttonVertical)
            .frame(maxWidth: .infinity)
            .background {
                if usePixel {
                    ZStack {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(themeStore.pixelShadow)
                            .offset(x: 4, y: 4)
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(themeStore.cardBg)
                            .overlay {
                                RoundedRectangle(cornerRadius: radius, style: .continuous)
                                    .strokeBorder(themeStore.pixelInk, lineWidth: 2)
                            }
                    }
                } else {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(themeStore.secondaryButtonBg)
                }
            }
            .padding(.bottom, usePixel ? 4 : 0)
            .padding(.trailing, usePixel ? 4 : 0)
    }
}

struct Duo3DChipModifier: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    var face: Color
    var lip: Color
    var border: Color? = nil
    var cornerRadius: CGFloat = 12
    var lipDepth: CGFloat = 3

    private var use3D: Bool { themeStore.isDuolingo && !themeStore.isGlass }
    private var usePixel: Bool { themeStore.isPixel }
    private var resolvedRadius: CGFloat { usePixel ? 0 : cornerRadius }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if usePixel {
                        RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                            .fill(themeStore.pixelShadow)
                            .offset(x: 3, y: 3)
                    } else if use3D {
                        RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                            .fill(lip)
                            .offset(y: lipDepth)
                    }
                    RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                        .fill(face)
                }
            )
            .overlay {
                if let border, use3D || usePixel {
                    RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                        .strokeBorder(border, lineWidth: 2)
                }
            }
            .padding(.bottom, usePixel ? 3 : (use3D ? lipDepth : 0))
            .padding(.trailing, usePixel ? 3 : 0)
            .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: resolvedRadius))
    }
}

struct Duo3DButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeStore: ThemeStore

    func makeBody(configuration: Configuration) -> some View {
        let use3D = themeStore.isDuolingo && !themeStore.isGlass
        let usePixel = themeStore.isPixel
        return configuration.label
            .offset(
                x: usePixel && configuration.isPressed ? 4 : 0,
                y: (use3D || usePixel) && configuration.isPressed ? 4 : 0
            )
            .scaleEffect((use3D || usePixel) ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .opacity(configuration.isPressed ? (use3D ? 0.95 : 0.85) : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func duo3DStyle(_ color: Color, isDisabled: Bool = false, force3D: Bool = false, verticalPadding: CGFloat = DesignSpacing.buttonVertical) -> some View {
        modifier(Duo3DStyle(bgColor: color, isDisabled: isDisabled, force3D: force3D, verticalPadding: verticalPadding))
    }

    func duo3DSecondaryStyle() -> some View {
        modifier(Duo3DSecondaryStyle())
    }

    func duo3DChipFilled(_ color: Color, cornerRadius: CGFloat = 12) -> some View {
        modifier(Duo3DChipModifier(
            face: color,
            lip: darkerShade(of: color, by: 0.16),
            border: nil,
            cornerRadius: cornerRadius
        ))
    }

    func duo3DChipOutlined(cornerRadius: CGFloat = 12) -> some View {
        modifier(Duo3DChipOutlinedModifier(cornerRadius: cornerRadius))
    }
}

private struct Duo3DChipOutlinedModifier: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let use3D = themeStore.isDuolingo && !themeStore.isGlass
        let usePixel = themeStore.isPixel
        content.modifier(Duo3DChipModifier(
            face: themeStore.controlFace,
            lip: use3D ? Color(hex: "#AFAFAF").opacity(0.45) : .clear,
            border: use3D ? themeStore.dividerColor : (usePixel ? themeStore.pixelInk : nil),
            cornerRadius: cornerRadius
        ))
    }
}
