import AVFoundation
import Foundation

/// Tiny synthesized UI sounds (not TTS). Respects the silent switch via `.ambient`.
enum SoundFX {
    enum Kind {
        case pop
        case ding
        case whoosh
        case combo
        case sparkle
    }

    private static var player: AVAudioPlayer?
    private static var cache: [Kind: Data] = [:]

    static func play(_ kind: Kind) {
        Task { @MainActor in
            playSync(kind)
        }
    }

    @MainActor
    private static func playSync(_ kind: Kind) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let data = try wavData(for: kind)
            let p = try AVAudioPlayer(data: data)
            p.volume = {
                switch kind {
                case .whoosh: return 0.45
                case .sparkle: return 0.48
                case .ding: return 0.5
                default: return 0.55
                }
            }()
            p.prepareToPlay()
            player = p
            p.play()
        } catch {
            #if DEBUG
            print("⚠️ SoundFX failed: \(error.localizedDescription)")
            #endif
        }
    }

    private static func wavData(for kind: Kind) throws -> Data {
        if let cached = cache[kind] { return cached }
        let data: Data
        switch kind {
        case .pop:
            data = try synthesize(
                duration: 0.07,
                freqs: [(880, 1.0), (1320, 0.45)],
                attack: 0.004,
                release: 0.05
            )
        case .ding:
            data = try synthesize(
                duration: 0.18,
                freqs: [(1174.7, 1.0), (1760, 0.35)],
                attack: 0.002,
                release: 0.14
            )
        case .whoosh:
            data = try synthesizeWhoosh(duration: 0.22)
        case .combo:
            data = try synthesize(
                duration: 0.22,
                freqs: [(659.3, 0.9), (987.8, 0.7), (1318.5, 0.55)],
                attack: 0.003,
                release: 0.12,
                chirp: true
            )
        case .sparkle:
            // Soft chime + tiny high ticks — join moment on splash.
            data = try synthesizeSparkle(duration: 0.58)
        }
        cache[kind] = data
        return data
    }

    private static func synthesize(
        duration: Double,
        freqs: [(Double, Double)],
        attack: Double,
        release: Double,
        chirp: Bool = false
    ) throws -> Data {
        let sampleRate = 22050.0
        let count = Int(duration * sampleRate)
        var samples = [Int16](repeating: 0, count: count)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var env = 1.0
            if t < attack {
                env = t / max(attack, 0.0001)
            } else if t > duration - release {
                env = max(0, (duration - t) / max(release, 0.0001))
            }

            var sample = 0.0
            for (index, pair) in freqs.enumerated() {
                let (baseFreq, amp) = pair
                let freq = chirp ? baseFreq * (1.0 + 0.12 * Double(index) + 0.35 * (t / duration)) : baseFreq
                sample += sin(2 * .pi * freq * t) * amp
            }
            sample = (sample / Double(freqs.count)) * env * 0.55
            let clipped = max(-1.0, min(1.0, sample))
            samples[i] = Int16(clipped * Double(Int16.max))
        }

        return try pcm16WAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func synthesizeWhoosh(duration: Double) throws -> Data {
        let sampleRate = 22050.0
        let count = Int(duration * sampleRate)
        var samples = [Int16](repeating: 0, count: count)
        var state = 0.0

        for i in 0..<count {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Soft noise burst that slides down in amplitude = “whoosh”
            state = state * 0.96 + Double.random(in: -1...1) * 0.35
            let tone = sin(2 * .pi * (420 - 220 * progress) * t) * 0.25
            let env = sin(.pi * progress) * (0.55 + 0.45 * (1 - progress))
            let sample = (state * 0.55 + tone) * env * 0.4
            samples[i] = Int16(max(-1.0, min(1.0, sample)) * Double(Int16.max))
        }

        return try pcm16WAV(samples: samples, sampleRate: Int(sampleRate))
    }

    /// Soft fairy-tale chime — gentle arpeggio with a long shimmer tail.
    private static func synthesizeSparkle(duration: Double) throws -> Data {
        let sampleRate = 22050.0
        let count = Int(duration * sampleRate)
        var samples = [Int16](repeating: 0, count: count)

        // Soft major-ish bells, staggered like a tiny music-box phrase.
        // C6, E6, G6, C7 — warm, not sharp.
        let notes: [(start: Double, freq: Double, amp: Double, len: Double)] = [
            (0.00, 1046.5, 0.85, 0.42),
            (0.07, 1318.5, 0.72, 0.40),
            (0.14, 1568.0, 0.62, 0.38),
            (0.22, 2093.0, 0.48, 0.36),
            (0.30, 2637.0, 0.22, 0.28)
        ]

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample = 0.0

            for note in notes {
                let local = t - note.start
                guard local >= 0, local < note.len else { continue }

                // Soft attack, long exponential decay — “fairy dust”
                let attack = 0.012
                let attackEnv = local < attack ? (local / attack) : 1.0
                let decay = exp(-local * 4.2)
                let env = attackEnv * decay

                // Fundamental + soft overtone (bell-ish, not harsh)
                let fund = sin(2 * .pi * note.freq * local)
                let over = sin(2 * .pi * note.freq * 2.01 * local) * 0.18
                let air = sin(2 * .pi * note.freq * 3.02 * local) * 0.06
                sample += (fund + over + air) * note.amp * env
            }

            // Very quiet high shimmer veil
            if t > 0.05, t < 0.55 {
                let veil = sin(2 * .pi * 3200 * t) * 0.04 * exp(-(t - 0.05) * 5.5)
                sample += veil
            }

            let clipped = max(-1.0, min(1.0, sample * 0.38))
            samples[i] = Int16(clipped * Double(Int16.max))
        }

        return try pcm16WAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func pcm16WAV(samples: [Int16], sampleRate: Int) throws -> Data {
        let dataSize = samples.count * 2
        var data = Data()
        data.reserveCapacity(44 + dataSize)

        func appendASCII(_ s: String) {
            data.append(contentsOf: s.utf8)
        }
        func appendUInt16(_ v: UInt16) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        func appendUInt32(_ v: UInt32) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1) // PCM
        appendUInt16(1) // mono
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2)
        appendUInt16(16)
        appendASCII("data")
        appendUInt32(UInt32(dataSize))

        for s in samples {
            var le = s.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        return data
    }
}
