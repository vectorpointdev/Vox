import SwiftUI
import AVFoundation

@MainActor
@Observable
final class iOSAppState {
    // MARK: - State
    var isModelLoaded = false
    var isModelLoading = false
    var statusMessage = ""
    var hasMicrophonePermission = false
    var isKeyboardEnabled = false

    // MARK: - Managers
    let sttEngine = SharedSTTEngine()

    // MARK: - Settings (via App Group)
    private var defaults: UserDefaults {
        UserDefaults(suiteName: SharedDictionaryStore.appGroupID) ?? .standard
    }

    var onboardingComplete: Bool {
        get { defaults.bool(forKey: "onboardingComplete") }
        set { defaults.set(newValue, forKey: "onboardingComplete") }
    }

    var useLLMProcessing: Bool {
        get { defaults.bool(forKey: "useLLMProcessing") }
        set { defaults.set(newValue, forKey: "useLLMProcessing") }
    }

    var claudeAPIKey: String {
        get { defaults.string(forKey: "claudeAPIKey") ?? "" }
        set { defaults.set(newValue, forKey: "claudeAPIKey") }
    }

    var soundEnabled: Bool {
        get {
            defaults.object(forKey: "soundEnabled") == nil
                ? true
                : defaults.bool(forKey: "soundEnabled")
        }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }

    // MARK: - Init
    init() {
        checkPermissions()
    }

    // MARK: - Permissions
    func checkPermissions() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .authorized {
            hasMicrophonePermission = true
        } else if micStatus == .notDetermined {
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .audio)
                hasMicrophonePermission = granted
            }
        } else {
            hasMicrophonePermission = false
        }

        checkKeyboardEnabled()
    }

    func requestMicrophonePermission() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            hasMicrophonePermission = granted
        }
    }

    func checkKeyboardEnabled() {
        // Check if our keyboard extension is enabled in system keyboards
        // This checks via the text input modes
        let inputModes = UITextInputMode.activeInputModes
        isKeyboardEnabled = inputModes.contains { mode in
            mode.primaryLanguage != nil
        }
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

    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func openKeyboardSettings() {
        if let url = URL(string: "App-prefs:General&path=Keyboard/KEYBOARDS") {
            UIApplication.shared.open(url)
        }
    }
}
