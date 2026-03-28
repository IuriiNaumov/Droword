import SwiftUI

struct ConfettiView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now
    @State private var isVisible = true

    private let particleCount: Int
    private let duration: Double

    init(particleCount: Int = 60, duration: Double = 2.5) {
        self.particleCount = particleCount
        self.duration = duration
    }

    var body: some View {
        if isVisible {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(startTime)
                    guard elapsed < duration else { return }

                    let gravity: CGFloat = 600
                    let t = CGFloat(elapsed)

                    for particle in particles {
                        let x = size.width / 2 + particle.velocityX * t + particle.drift * sin(t * 3)
                        let y = size.height * 0.4 + particle.velocityY * t + 0.5 * gravity * t * t

                        let fadeProgress = max(0, 1.0 - elapsed / duration)

                        guard x > -20, x < size.width + 20, y < size.height + 20 else { continue }

                        let angle = Angle.degrees(Double(particle.spin * t * 360))
                        var transform = CGAffineTransform.identity
                        transform = transform.translatedBy(x: x, y: y)
                        transform = transform.rotated(by: CGFloat(angle.radians))

                        context.opacity = fadeProgress * particle.opacity
                        context.transform = transform

                        let rect = CGRect(
                            x: -particle.width / 2,
                            y: -particle.height / 2,
                            width: particle.width,
                            height: particle.height
                        )

                        let path = particle.isCircle
                            ? Path(ellipseIn: rect)
                            : Path(roundedRect: rect, cornerRadius: 1)

                        context.fill(path, with: .color(particle.color))
                        context.transform = .identity
                    }
                }
            }
            .allowsHitTesting(false)
            .onAppear { initParticles() }
            .task {
                try? await Task.sleep(for: .seconds(duration))
                isVisible = false
            }
        }
    }

    private func initParticles() {
        let colors: [Color] = [
            themeStore.accentBlue,
            themeStore.accentGreen,
            themeStore.accentPurple,
            themeStore.accentPink,
            themeStore.accentGold,
            themeStore.accentRed
        ]

        startTime = .now
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                velocityX: CGFloat.random(in: -200...200),
                velocityY: CGFloat.random(in: -500 ... -200),
                drift: CGFloat.random(in: -15...15),
                spin: CGFloat.random(in: -2...2),
                width: CGFloat.random(in: 4...8),
                height: CGFloat.random(in: 6...14),
                isCircle: Bool.random(),
                color: colors.randomElement() ?? Color.accentBlue,
                opacity: Double.random(in: 0.7...1.0)
            )
        }
    }
}

private struct ConfettiParticle {
    let velocityX: CGFloat
    let velocityY: CGFloat
    let drift: CGFloat
    let spin: CGFloat
    let width: CGFloat
    let height: CGFloat
    let isCircle: Bool
    let color: Color
    let opacity: Double
}
