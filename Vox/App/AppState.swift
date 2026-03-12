import SwiftUI
import AVFoundation
@preconcurrency import ApplicationServices

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
        // Force a fresh accessibility check (not cached)
        hasAccessibilityPermission = Self.checkAccessibilityTrusted(prompt: false)

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .authorized {
            hasMicrophonePermission = true
        } else if micStatus == .notDetermined {
            // After delete/reinstall, status may be .notDetermined even if system already granted.
            // requestAccess resolves instantly if already granted.
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .audio)
                hasMicrophonePermission = granted
            }
        } else {
            hasMicrophonePermission = false
        }
    }

    /// Recheck permissions periodically (e.g. when settings window appears)
    func startPermissionRecheck() {
        Task {
            for _ in 0..<5 {
                try? await Task.sleep(for: .seconds(2))
                checkPermissions()
                if hasAccessibilityPermission && hasMicrophonePermission { break }
            }
        }
    }

    func requestMicrophonePermission() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            hasMicrophonePermission = granted
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

    private nonisolated static func checkAccessibilityTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
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
            NSSound(named: "Hero")?.play()
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
                let t0 = CFAbsoluteTimeGetCurrent()
                print("[Vox] Captured \(samples.count) audio samples (\(String(format: "%.1f", Double(samples.count) / 16000))s of audio)")

                guard !samples.isEmpty else {
                    statusMessage = "No audio captured"
                    isProcessing = false
                    return
                }

                var text = try await sttEngine.transcribe(audioSamples: samples)
                let t1 = CFAbsoluteTimeGetCurrent()
                print("[Vox] Transcription (\(String(format: "%.2f", t1 - t0))s): '\(text)'")

                // Safety net: strip any remaining bracketed Whisper artifacts
                text = text.replacingOccurrences(
                    of: "\\[[A-Z_ ]+\\]",
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                ).trimmingCharacters(in: .whitespacesAndNewlines)

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
                    let t2 = CFAbsoluteTimeGetCurrent()
                    print("[Vox] LLM processing (\(String(format: "%.2f", t2 - t1))s)")
                }

                lastTranscription = text
                let tEnd = CFAbsoluteTimeGetCurrent()
                print("[Vox] Total pipeline: \(String(format: "%.2f", tEnd - t0))s — injecting: '\(text)'")
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
