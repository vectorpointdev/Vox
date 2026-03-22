import SwiftUI

struct iOSSettingsView: View {
    @Environment(iOSAppState.self) private var appState
    @State private var useLLM = false
    @State private var apiKey = ""
    @State private var soundEnabled = true
    @State private var apiKeyTestResult: String?
    @State private var isTestingAPIKey = false
    @State private var dictionaryEntries: [SharedDictionaryEntry] = []

    var body: some View {
        List {
            // AI Processing
            Section {
                Toggle("Enable AI Post-Processing", isOn: $useLLM)
                    .onChange(of: useLLM) { _, newValue in
                        appState.useLLMProcessing = newValue
                    }
                Text("Uses Claude to clean up filler words, fix grammar, and polish your dictation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("AI Processing", systemImage: "brain")
            }

            if useLLM {
                Section("Claude API Key") {
                    SecureField("sk-ant-...", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiKey) { _, newValue in
                            appState.claudeAPIKey = newValue
                        }

                    Button {
                        testAPIKey()
                    } label: {
                        HStack {
                            Text("Test API Key")
                            Spacer()
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
                    .disabled(apiKey.isEmpty || isTestingAPIKey)
                }
            }

            // Audio Feedback
            Section {
                Toggle("Haptic Feedback", isOn: $soundEnabled)
                    .onChange(of: soundEnabled) { _, newValue in
                        appState.soundEnabled = newValue
                    }
            } header: {
                Label("Feedback", systemImage: "hand.tap")
            }

            // Custom Dictionary
            Section {
                Text("Words and phrases that Vox should always spell a specific way.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach($dictionaryEntries) { $entry in
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Heard as...", text: $entry.phrase)
                            .font(.subheadline)
                        HStack {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Replace with...", text: $entry.replacement)
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete { indexSet in
                    dictionaryEntries.remove(atOffsets: indexSet)
                    SharedDictionaryStore.save(dictionaryEntries)
                }

                Button("Add Entry") {
                    dictionaryEntries.append(SharedDictionaryEntry(phrase: "", replacement: ""))
                }
            } header: {
                Label("Custom Dictionary", systemImage: "character.book.closed")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            useLLM = appState.useLLMProcessing
            apiKey = appState.claudeAPIKey
            soundEnabled = appState.soundEnabled
            dictionaryEntries = SharedDictionaryStore.load()
        }
        .onChange(of: dictionaryEntries) { _, newValue in
            SharedDictionaryStore.save(newValue)
        }
    }

    private func testAPIKey() {
        isTestingAPIKey = true
        apiKeyTestResult = nil

        Task {
            let result = await SharedLLMProcessor().process(
                rawTranscription: "Hello world",
                context: SharedDictationContext(appName: nil, appBundleID: nil, timestamp: Date()),
                apiKey: apiKey
            )
            isTestingAPIKey = false
            apiKeyTestResult = result.isEmpty ? "Error: No response" : "Success!"
        }
    }
}
