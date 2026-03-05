import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.statusMessage)
                    .font(.headline)
            }

            if appState.isModelLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Downloading speech model...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Last transcription (safety net)
            if !appState.lastTranscription.isEmpty {
                Divider()
                Text("Last dictation:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.lastTranscription)
                    .font(.body)
                    .lineLimit(5)
                    .textSelection(.enabled)

                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.lastTranscription, forType: .string)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            Divider()

            // Hotkey hint
            Text("Hold Option+Space to dictate")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("Settings...") {
                openSettings()
            }
            .keyboardShortcut(",")

            Button("Quit Vox") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 280)
    }

    private func openSettings() {
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }

    private var statusColor: Color {
        if appState.isRecording {
            return .red
        } else if appState.isProcessing {
            return .orange
        } else if appState.isModelLoaded {
            return .green
        } else {
            return .gray
        }
    }
}
