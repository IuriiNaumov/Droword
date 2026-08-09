import Foundation
import Speech
import AVFoundation
import Combine

/// Обёртка над SFSpeechRecognizer + AVAudioEngine для упражнения на произношение.
/// Запрашивает разрешения, записывает речь и отдаёт распознанный текст.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var isUnavailable = false

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // Auto-stop: finish shortly after the user goes quiet, and cap the total
    // duration, so there's no manual "stop" button (Duolingo-style).
    private var silenceTimer: Timer?
    private var maxTimer: Timer?
    private let silenceDelay: TimeInterval = 1.6
    private let maxDuration: TimeInterval = 12

    /// Маппинг названий языков (как в LanguageCatalog) на идентификаторы локали.
    static func localeIdentifier(for languageName: String) -> String {
        switch languageName {
        case "English": return "en-US"
        case "Español": return "es-ES"
        case "Русский": return "ru-RU"
        case "Français": return "fr-FR"
        case "Deutsch": return "de-DE"
        case "Italiano": return "it-IT"
        case "Português": return "pt-PT"
        case "한국어": return "ko-KR"
        case "中文": return "zh-CN"
        case "日本語": return "ja-JP"
        case "العربية": return "ar-SA"
        case "हिन्दी": return "hi-IN"
        default: return "en-US"
        }
    }

    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { return false }

        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func start(localeIdentifier: String) {
        transcript = ""
        isUnavailable = false

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) ?? SFSpeechRecognizer(),
              recognizer.isAvailable else {
            isUnavailable = true
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak req] buffer, _ in
                req?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            scheduleMaxTimer()

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        // Once we've heard something, finish after a short pause.
                        if !self.transcript.isEmpty { self.scheduleSilenceTimer() }
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self.stop()
                    }
                }
            }
        } catch {
            isUnavailable = true
            stop()
        }
    }

    /// Stop recording once the user has been quiet for `silenceDelay`.
    private func scheduleSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDelay, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.stop() }
        }
    }

    /// Hard cap so recording never runs forever if nothing is recognised.
    private func scheduleMaxTimer() {
        maxTimer?.invalidate()
        maxTimer = Timer.scheduledTimer(withTimeInterval: maxDuration, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.stop() }
        }
    }

    func stop() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxTimer?.invalidate()
        maxTimer = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
