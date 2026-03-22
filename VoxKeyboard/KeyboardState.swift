import UIKit
import AVFoundation

@MainActor
@Observable
final class KeyboardState {
    // MARK: - State
    var isRecording = false
    var isProcessing = false
    var statusMessage = "Tap mic to dictate"
    var isModelLoaded = false
    var isModelLoading = false
    var lastTranscription = ""

    // MARK: - Text Proxy
    var textDocumentProxy: UITextDocumentProxy

    // MARK: - Managers
    let audioPipeline = AudioPipeline()
    let sttEngine = SharedSTTEngine()
    let llmProcessor = SharedLLMProcessor()

    // MARK: - Settings (via App Group)
    private var defaults: UserDefaults {
        UserDefaults(suiteName: SharedDictionaryStore.appGroupID) ?? .standard
    }

    var useLLMProcessing: Bool {
        defaults.bool(forKey: "useLLMProcessing")
    }

    var claudeAPIKey: String {
        defaults.string(forKey: "claudeAPIKey") ?? ""
    }

    var soundEnabled: Bool {
        defaults.object(forKey: "soundEnabled") == nil
            ? true
            : defaults.bool(forKey: "soundEnabled")
    }

    // MARK: - Init
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
        loadModelInBackground()
    }

    // MARK: - Model Loading
    func loadModelInBackground() {
        guard !isModelLoaded && !isModelLoading else { return }
        isModelLoading = true
        statusMessage = "Loading model..."

        Task {
            do {
                try await sttEngine.loadModel()
                isModelLoaded = true
                isModelLoading = false
                statusMessage = "Tap mic to dictate"
            } catch {
                isModelLoading = false
                statusMessage = "Model error"
                print("[VoxKeyboard] Model load failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Dictation Flow
    func toggleDictation() {
        if isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }

    func startDictation() {
        guard isModelLoaded else {
            statusMessage = "Model loading..."
            loadModelInBackground()
            return
        }

        isRecording = true
        statusMessage = "Listening..."

        if soundEnabled {
            hapticFeedback(.heavy)
        }

        do {
            try audioPipeline.startCapture()
        } catch {
            isRecording = false
            statusMessage = "Mic error"
            print("[VoxKeyboard] Mic error: \(error.localizedDescription)")
            if soundEnabled {
                hapticFeedback(.error)
            }
        }
    }

    func stopDictation() {
        guard isRecording else { return }

        isRecording = false
        isProcessing = true
        statusMessage = "Processing..."

        let samples = audioPipeline.stopCapture()

        Task {
            do {
                let t0 = CFAbsoluteTimeGetCurrent()
                print("[VoxKeyboard] Captured \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000))s)")

                guard !samples.isEmpty else {
                    statusMessage = "No audio"
                    isProcessing = false
                    return
                }

                var text = try await sttEngine.transcribe(audioSamples: samples)
                let t1 = CFAbsoluteTimeGetCurrent()
                print("[VoxKeyboard] Transcription (\(String(format: "%.2f", t1 - t0))s): '\(text)'")

                // Strip bracketed Whisper artifacts
                text = text.replacingOccurrences(
                    of: "\\[[A-Z_ ]+\\]",
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                ).trimmingCharacters(in: .whitespacesAndNewlines)

                if text.isEmpty {
                    statusMessage = "Couldn't understand"
                    isProcessing = false
                    if soundEnabled { hapticFeedback(.error) }
                    return
                }

                // LLM post-processing
                if useLLMProcessing && !claudeAPIKey.isEmpty {
                    let context = SharedDictationContext(
                        appName: nil,
                        appBundleID: nil,
                        timestamp: Date()
                    )
                    text = await llmProcessor.process(
                        rawTranscription: text,
                        context: context,
                        apiKey: claudeAPIKey
                    )
                    let t2 = CFAbsoluteTimeGetCurrent()
                    print("[VoxKeyboard] LLM processing (\(String(format: "%.2f", t2 - t1))s)")
                }

                lastTranscription = text
                let tEnd = CFAbsoluteTimeGetCurrent()
                print("[VoxKeyboard] Total pipeline: \(String(format: "%.2f", tEnd - t0))s — inserting: '\(text)'")

                // Insert text via the keyboard's text document proxy
                textDocumentProxy.insertText(text)

                statusMessage = "Tap mic to dictate"
                if soundEnabled { hapticFeedback(.success) }
            } catch {
                statusMessage = "Error"
                print("[VoxKeyboard] Error: \(error.localizedDescription)")
                if soundEnabled { hapticFeedback(.error) }
            }

            isProcessing = false
        }
    }

    // MARK: - Standard Keyboard Actions
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    func insertNewline() {
        textDocumentProxy.insertText("\n")
    }

    // MARK: - Haptics
    private func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
