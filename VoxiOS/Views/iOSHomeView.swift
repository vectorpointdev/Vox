import SwiftUI

struct iOSHomeView: View {
    @Environment(iOSAppState.self) private var appState

    var body: some View {
        List {
            // Status Section
            Section {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vox Keyboard")
                            .font(.headline)
                        Text(appState.statusMessage.isEmpty ? "Ready" : appState.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Circle()
                        .fill(appState.isModelLoaded ? .green : .gray)
                        .frame(width: 10, height: 10)
                }
            }

            // Setup Guide
            Section("Setup") {
                // Keyboard enable step
                HStack {
                    Image(systemName: "keyboard")
                        .frame(width: 24)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text("Enable Vox Keyboard")
                            .font(.subheadline.bold())
                        Text("Settings → General → Keyboard → Keyboards → Add New Keyboard → Vox")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Settings") {
                        appState.openKeyboardSettings()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }

                // Full access step
                HStack {
                    Image(systemName: "lock.open")
                        .frame(width: 24)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text("Allow Full Access")
                            .font(.subheadline.bold())
                        Text("Required for microphone and AI processing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Microphone permission
                HStack {
                    Image(systemName: appState.hasMicrophonePermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.hasMicrophonePermission ? .green : .red)
                        .frame(width: 24)
                    Text("Microphone Access")
                    Spacer()
                    if !appState.hasMicrophonePermission {
                        Button("Grant") {
                            appState.requestMicrophonePermission()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }

            // How to Use
            Section("How to Use") {
                Label("Switch to Vox keyboard using the globe key", systemImage: "globe")
                    .font(.subheadline)
                Label("Tap the mic button to start dictating", systemImage: "mic.fill")
                    .font(.subheadline)
                Label("Tap again to stop — text is inserted automatically", systemImage: "text.cursor")
                    .font(.subheadline)
                Label("AI cleans up filler words and fixes grammar", systemImage: "brain")
                    .font(.subheadline)
            }

            // Speech Model
            Section("Speech Model") {
                if appState.isModelLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Downloading speech model...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if appState.isModelLoaded {
                    Label("Model loaded", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Pre-download Speech Model") {
                        appState.loadModelInBackground()
                    }
                    Text("The keyboard will also download the model on first use.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Vox")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: iOSSettingsView().environment(appState)) {
                    Image(systemName: "gear")
                }
            }
        }
        .onAppear {
            appState.checkPermissions()
        }
    }
}
