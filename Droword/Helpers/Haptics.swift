import CoreHaptics
import UIKit

public enum Haptics {
    private static var engine: CHHapticEngine?
    private static var engineFailed = false
    private static var heartbeatTask: Task<Void, Never>?
    private static var previewTask: Task<Void, Never>?
    private static var suggestionTask: Task<Void, Never>?

    private static var supportsCoreHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private static func ensureEngine() -> CHHapticEngine? {
        guard supportsCoreHaptics, !engineFailed else { return nil }
        if let engine { return engine }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = {
                try? engine.start()
            }
            engine.stoppedHandler = { _ in
                try? engine.start()
            }
            try engine.start()
            self.engine = engine
            return engine
        } catch {
            engineFailed = true
            return nil
        }
    }

    private static func play(_ events: [CHHapticEvent], feel: HapticFeel? = nil, keepSustain: Bool = false) {
        let feel = feel ?? HapticFeel.current
        guard feel != .off, !events.isEmpty else { return }
        let shaped = shape(events, feel: feel, keepSustain: keepSustain)
        guard let engine = ensureEngine() else { return }
        do {
            let pattern = try CHHapticPattern(events: shaped, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private static func transient(time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private static func continuous(time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private static func shape(_ events: [CHHapticEvent], feel: HapticFeel, keepSustain: Bool = false) -> [CHHapticEvent] {
        switch feel {
        case .off:
            return []
        case .soft:
            return events
        case .silk:
            return remap(events, intensity: 0.58, sharpness: 0.42, dropContinuous: false)
        case .crisp:
            return remap(events, intensity: 0.88, sharpness: 1.2, dropContinuous: !keepSustain)
        case .pop:
            return popify(remap(events, intensity: 1.0, sharpness: 0.72, dropContinuous: !keepSustain))
        }
    }

    private static func remap(
        _ events: [CHHapticEvent],
        intensity: Float,
        sharpness: Float,
        dropContinuous: Bool
    ) -> [CHHapticEvent] {
        events.compactMap { event in
            if dropContinuous, event.type == .hapticContinuous { return nil }
            let params = event.eventParameters.map { parameter in
                switch parameter.parameterID {
                case .hapticIntensity:
                    return CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: min(1, max(0, parameter.value * intensity))
                    )
                case .hapticSharpness:
                    return CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: min(1, max(0, parameter.value * sharpness))
                    )
                default:
                    return parameter
                }
            }
            return CHHapticEvent(
                eventType: event.type,
                parameters: params,
                relativeTime: event.relativeTime,
                duration: event.duration
            )
        }
    }

    private static func popify(_ events: [CHHapticEvent]) -> [CHHapticEvent] {
        guard let first = events.first(where: { $0.type == .hapticTransient }) else { return events }
        let intensity = first.eventParameters.first(where: { $0.parameterID == .hapticIntensity })?.value ?? 0.4
        let sharpness = first.eventParameters.first(where: { $0.parameterID == .hapticSharpness })?.value ?? 0.3
        let echo = transient(time: first.relativeTime + 0.03, intensity: intensity * 0.55, sharpness: sharpness * 0.7)
        return events + [echo]
    }

    static func preview(_ feel: HapticFeel) {
        previewTask?.cancel()
        guard feel != .off else { return }
        previewTask = Task { @MainActor in
            play(cardEvents(opening: true), feel: feel)
            try? await Task.sleep(for: .milliseconds(240))
            if Task.isCancelled { return }
            play([
                transient(time: 0.00, intensity: 0.48, sharpness: 0.7),
                transient(time: 0.05, intensity: 0.72, sharpness: 0.42)
            ], feel: feel)
        }
    }

    public static func addWordTap() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.7, sharpness: 0.22),
                continuous(time: 0.01, duration: 0.04, intensity: 0.28, sharpness: 0.12)
            ])
        } else {
            fallbackImpact(.soft, intensity: 0.7)
        }
    }

    public static func startHeartbeat() {
        stopHeartbeat()
        guard HapticFeel.current != .off else { return }
        heartbeatTask = Task { @MainActor in
            while !Task.isCancelled {
                playHeartbeatBeat()
                try? await Task.sleep(for: .milliseconds(780))
            }
        }
    }

    public static func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    private static func playHeartbeatBeat() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.62, sharpness: 0.28),
                transient(time: 0.13, intensity: 0.4, sharpness: 0.42)
            ])
        } else {
            fallbackImpact(.soft, intensity: 0.6)
        }
    }

    private static func cardEvents(opening: Bool) -> [CHHapticEvent] {
        if opening {
            return [transient(time: 0.00, intensity: 0.36, sharpness: 0.24)]
        }
        return [transient(time: 0.00, intensity: 0.28, sharpness: 0.18)]
    }

    public static func cardExpand() {
        if supportsCoreHaptics {
            play(cardEvents(opening: true))
        } else {
            fallbackImpact(.soft, intensity: 0.42)
        }
    }

    public static func cardCollapse() {
        if supportsCoreHaptics {
            play(cardEvents(opening: false))
        } else {
            fallbackImpact(.soft, intensity: 0.32)
        }
    }

    public static func soundWave() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.22, sharpness: 0.7)])
        } else {
            fallbackImpact(.soft, intensity: 0.22)
        }
    }

    public static func fontSizeStep() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.48, sharpness: 0.88)])
        } else {
            fallbackSelection()
        }
    }

    public static func success() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.42, sharpness: 0.7),
                transient(time: 0.055, intensity: 0.78, sharpness: 0.38)
            ])
        } else {
            fallbackNotification(.success)
        }
    }

    public static func error() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.7, sharpness: 0.12),
                continuous(time: 0.02, duration: 0.09, intensity: 0.38, sharpness: 0.08)
            ])
        } else {
            fallbackNotification(.error)
        }
    }

    public static func combo(streak count: Int) {
        if supportsCoreHaptics {
            if count >= 7 {
                play([
                    transient(time: 0.00, intensity: 0.42, sharpness: 0.8),
                    transient(time: 0.045, intensity: 0.6, sharpness: 0.62),
                    transient(time: 0.09, intensity: 0.82, sharpness: 0.4)
                ])
            } else if count >= 5 {
                play([
                    transient(time: 0.00, intensity: 0.4, sharpness: 0.75),
                    transient(time: 0.05, intensity: 0.68, sharpness: 0.48)
                ])
            } else {
                play([
                    transient(time: 0.00, intensity: 0.38, sharpness: 0.72),
                    transient(time: 0.045, intensity: 0.58, sharpness: 0.46)
                ])
            }
        } else {
            fallbackNotification(.success)
        }
    }

    public static func tick() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.4, sharpness: 0.86)])
        } else {
            fallbackSelection()
        }
    }

    public static func selection() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.34, sharpness: 0.78)])
        } else {
            fallbackSelection()
        }
    }

    public static func softTap() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.28, sharpness: 0.32)])
        } else {
            fallbackImpact(.soft, intensity: 0.35)
        }
    }

    /// Letter ticks + bloom — synced to the kinetic wordmark.
    public static func splash() {
        if supportsCoreHaptics {
            play([
                continuous(time: 0.00, duration: 0.18, intensity: 0.12, sharpness: 0.10),
                transient(time: 0.09, intensity: 0.22, sharpness: 0.94),
                transient(time: 0.154, intensity: 0.20, sharpness: 0.90),
                transient(time: 0.218, intensity: 0.24, sharpness: 0.88),
                transient(time: 0.282, intensity: 0.26, sharpness: 0.86),
                transient(time: 0.346, intensity: 0.28, sharpness: 0.84),
                transient(time: 0.410, intensity: 0.30, sharpness: 0.82),
                transient(time: 0.474, intensity: 0.36, sharpness: 0.70),
                continuous(time: 0.54, duration: 0.28, intensity: 0.20, sharpness: 0.14),
                transient(time: 0.58, intensity: 0.32, sharpness: 0.38),
                transient(time: 0.74, intensity: 0.16, sharpness: 0.92),
                transient(time: 0.92, intensity: 0.20, sharpness: 0.78),
                transient(time: 1.12, intensity: 0.14, sharpness: 0.90)
            ], keepSustain: true)
        } else {
            fallbackImpact(.soft, intensity: 0.28)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                fallbackSelection()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                fallbackSelection()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
                fallbackImpact(.soft, intensity: 0.38)
            }
        }
    }

    /// Squeeze then fly-through when the splash leaves.
    public static func splashExit() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.22, sharpness: 0.28),
                continuous(time: 0.04, duration: 0.22, intensity: 0.26, sharpness: 0.12),
                transient(time: 0.12, intensity: 0.46, sharpness: 0.24)
            ], keepSustain: true)
        } else {
            fallbackImpact(.soft, intensity: 0.28)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                fallbackImpact(.medium, intensity: 0.42)
            }
        }
    }

    public static func buttonPress() {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: 0.4, sharpness: 0.3)])
        } else {
            fallbackImpact(.soft, intensity: 0.45)
        }
    }

    public static func menuTap() {
        softTap()
    }

    public static func open() {
        softTap()
    }

    public static func lightImpact(intensity: CGFloat = 0.6) {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: Float(intensity) * 0.42, sharpness: 0.36)])
        } else {
            fallbackImpact(.soft, intensity: intensity * 0.6)
        }
    }

    public static func mediumImpact(intensity: CGFloat = 0.9) {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: Float(intensity) * 0.5, sharpness: 0.34)])
        } else {
            fallbackImpact(.medium, intensity: intensity * 0.7)
        }
    }

    public static func heavyImpact(intensity: CGFloat = 1.0) {
        if supportsCoreHaptics {
            play([transient(time: 0.00, intensity: min(1, Float(intensity) * 0.68), sharpness: 0.22)])
        } else {
            fallbackImpact(.heavy, intensity: intensity)
        }
    }

    public static func warning() {
        if supportsCoreHaptics {
            play([
                transient(time: 0.00, intensity: 0.5, sharpness: 0.2),
                transient(time: 0.07, intensity: 0.38, sharpness: 0.16)
            ])
        } else {
            fallbackNotification(.warning)
        }
    }

    public static func celebration() {
        combo(streak: 7)
    }

    /// Long blooming rumble when a suggestion pack lands on Home.
    public static func suggestionsArrived() {
        suggestionTask?.cancel()
        guard HapticFeel.current != .off else { return }
        if supportsCoreHaptics {
            play([
                continuous(time: 0.00, duration: 0.22, intensity: 0.22, sharpness: 0.10),
                transient(time: 0.10, intensity: 0.38, sharpness: 0.22),
                continuous(time: 0.20, duration: 0.28, intensity: 0.52, sharpness: 0.14),
                transient(time: 0.34, intensity: 0.62, sharpness: 0.18),
                continuous(time: 0.46, duration: 0.34, intensity: 0.40, sharpness: 0.12),
                transient(time: 0.62, intensity: 0.74, sharpness: 0.16),
                continuous(time: 0.74, duration: 0.28, intensity: 0.24, sharpness: 0.10),
                transient(time: 0.98, intensity: 0.48, sharpness: 0.28)
            ], keepSustain: true)
        } else {
            suggestionTask = Task { @MainActor in
                fallbackImpact(.soft, intensity: 0.45)
                try? await Task.sleep(for: .milliseconds(140))
                if Task.isCancelled { return }
                fallbackImpact(.medium, intensity: 0.7)
                try? await Task.sleep(for: .milliseconds(180))
                if Task.isCancelled { return }
                fallbackImpact(.heavy, intensity: 0.95)
                try? await Task.sleep(for: .milliseconds(220))
                if Task.isCancelled { return }
                fallbackImpact(.medium, intensity: 0.55)
            }
        }
    }

    public static func streak() {
        tick()
    }

    private static func fallbackImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        guard HapticFeel.current != .off else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private static func fallbackSelection() {
        guard HapticFeel.current != .off else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private static func fallbackNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard HapticFeel.current != .off else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
