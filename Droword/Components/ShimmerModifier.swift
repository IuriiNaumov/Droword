import SwiftUI

private struct ShimmerModifier: ViewModifier {
    let active: Bool
    let speed: Double
    let blendMode: BlendMode
    let opacity: Double

    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if !active {
            content.opacity(opacity)
        } else {
            content
                .opacity(opacity)
                .overlay(
                    GeometryReader { geometry in
                        let gradient = LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color.primary.opacity(0.8), location: 0.5),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: UnitPoint(x: 0, y: 0),
                            endPoint: UnitPoint(x: 1, y: 0)
                        )
                        
                        Rectangle()
                            .fill(gradient)
                            .rotationEffect(.degrees(20))
                            .offset(x: geometry.size.width * phase)
                            .mask(content)
                            .animation(
                                .linear(duration: speed)
                                    .repeatForever(autoreverses: false),
                                value: phase
                            )
                            .onAppear {
                                phase = 2
                            }
                    }
                )
                .blendMode(blendMode)
        }
    }
}

public extension View {
    func shimmering(active: Bool = true, speed: Double = 1.25, blendMode: BlendMode = .screen, opacity: Double = 0.6) -> some View {
        modifier(ShimmerModifier(active: active, speed: speed, blendMode: blendMode, opacity: opacity))
    }
}
