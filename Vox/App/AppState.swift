import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AppState {
    // MARK: - State
    var isRecording = false
    var isProcessing = false
    var lastTranscription = ""
    var statusMessage = ""
    var isModelLoaded = false
    var isModelLoading = false
    var modelLoadProgress: Double = 0

    // MARK: - Permission State
    var hasAccessibilityPermission = false
    var hasMicrophonePermission = false

    // MARK: - Managers
    let audioPipeline = AudioPipeline()
    let sttEngine = STTEngine()
    let llmProcessor = LLMProcessor()
    let textInjector = TextInjector()
    let hotkeyManager = HotkeyManager()

    // MARK: - Settings Access
    var useLLMProcessing: Bool {
        UserDefaults.standard.bool(forKey: "useLLMProcessing")
    }

    var claudeAPIKey: String {
        UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
    }

    var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    // MARK: - Init
    init() {
        hotkeyManager.onRecordStart = { [weak self] in
            self?.startDictation()
        }
        hotkeyManager.onRecordStop = { [weak self] in
            self?.stopDictation()
        }

        checkPermissions()
        loadModelInBackground()
    }

    // MARK: - Model Loading
    func loadModelInBackground() {
        guard !isModelLoaded && !isModelLoading else { return }
        isModelLoading = true
        statusMessage = "Loading speech model..."

        Task {
            do {
                try await sttEngine.loadModel()
                isModelLoaded = true
                isModelLoading = false
                statusMessage = "Ready"
            } catch {
                isModelLoading = false
                statusMessage = "Model load failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Permissions
    func checkPermissions() {
        hasAccessibilityPermission = TextInjector.hasAccessibilityPermission()
        hasMicrophonePermission = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            Task { @MainActor in
                self?.hasMicrophonePermission = granted
            }
        }
    }

    func requestAccessibilityPermission() {
        TextInjector.requestAccessibilityPermission()
        // Check again after a delay (user must toggle in System Settings)
        Task {
            try? await Task.sleep(for: .seconds(2))
            checkPermissions()
        }
    }

    // MARK: - Dictation Flow
    func startDictation() {
        guard isModelLoaded else {
            statusMessage = "Model not loaded yet"
            return
        }

        isRecording = true
        statusMessage = "Listening..."

        if soundEnabled {
            NSSound(named: "Tink")?.play()
        }

        do {
            try audioPipeline.startCapture()
        } catch {
            isRecording = false
            statusMessage = "Mic error: \(error.localizedDescription)"
            if soundEnabled {
                NSSound(named: "Basso")?.play()
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
                guard !samples.isEmpty else {
                    statusMessage = "No audio captured"
                    isProcessing = false
                    return
                }

                var text = try await sttEngine.transcribe(audioSamples: samples)

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    statusMessage = "Couldn't understand audio"
                    isProcessing = false
                    if soundEnabled {
                        NSSound(named: "Basso")?.play()
                    }
                    return
                }

                if useLLMProcessing && !claudeAPIKey.isEmpty {
                    let context = DictationContext(
                        appName: ContextEngine.frontmostAppName(),
                        appBundleID: ContextEngine.frontmostAppBundleID(),
                        timestamp: Date()
                    )
                    text = await llmProcessor.process(
                        rawTranscription: text,
                        context: context,
                        apiKey: claudeAPIKey
                    )
                }

                lastTranscription = text
                textInjector.inject(text: text)

                statusMessage = "Ready"
                if soundEnabled {
                    NSSound(named: "Glass")?.play()
                }
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
                if soundEnabled {
                    NSSound(named: "Basso")?.play()
                }
            }

            isProcessing = false
        }
    }
}
