import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("useLLMProcessing") private var useLLMProcessing = false
    @AppStorage("claudeAPIKey") private var claudeAPIKey = ""
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var launchAtLogin = false
    @State private var apiKeyTestResult: String?
    @State private var isTestingAPIKey = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            aiTab
                .tabItem { Label("AI Processing", systemImage: "brain") }
        }
        .frame(width: 450, height: 280)
        .onAppear {
            launchAtLogin = (try? SMAppService.mainApp.status == .enabled) ?? false
            appState.checkPermissions()
        }
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Hold-to-talk:", name: .holdToTalk)
            }

            Section("Audio") {
                Toggle("Play sounds", isOn: $soundEnabled)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section("Permissions") {
                HStack {
                    Image(systemName: appState.hasMicrophonePermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.hasMicrophonePermission ? .green : .red)
                    Text("Microphone")
                    Spacer()
                    if !appState.hasMicrophonePermission {
                        Button("Grant") { appState.requestMicrophonePermission() }
                            .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Image(systemName: appState.hasAccessibilityPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.hasAccessibilityPermission ? .green : .red)
                    Text("Accessibility")
                    Spacer()
                    if !appState.hasAccessibilityPermission {
                        Button("Grant") { appState.requestAccessibilityPermission() }
                            .buttonStyle(.borderless)
                        Button("Recheck") { appState.checkPermissions() }
                            .buttonStyle(.borderless)
                    }
                }
                if !appState.hasAccessibilityPermission {
                    Text("If already granted, restart Vox for it to take effect.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - AI Tab
    private var aiTab: some View {
        Form {
            Section {
                Toggle("Enable AI post-processing", isOn: $useLLMProcessing)
                Text("Uses Claude to clean up filler words, fix grammar, and polish your dictation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if useLLMProcessing {
                Section("Claude API Key") {
                    SecureField("sk-ant-...", text: $claudeAPIKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Test API Key") {
                            testAPIKey()
                        }
                        .disabled(claudeAPIKey.isEmpty || isTestingAPIKey)

                        if isTestingAPIKey {
                            ProgressView()
                                .controlSize(.small)
                        }

                        if let result = apiKeyTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(result.contains("Success") ? .green : .red)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func testAPIKey() {
        isTestingAPIKey = true
        apiKeyTestResult = nil

        Task {
            let result = await LLMProcessor().process(
                rawTranscription: "Hello world",
                context: DictationContext(appName: nil, appBundleID: nil, timestamp: Date()),
                apiKey: claudeAPIKey
            )
            isTestingAPIKey = false
            apiKeyTestResult = result.isEmpty ? "Error: No response" : "Success!"
        }
    }
}
