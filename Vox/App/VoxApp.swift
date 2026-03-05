import SwiftUI

@main
struct VoxApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
                .symbolEffect(.pulse, isActive: appState.isRecording)
        }

        Window("Vox Settings", id: "settings") {
            SettingsView()
                .environment(appState)
        }
        .windowResizability(.contentSize)

        Window("Welcome to Vox", id: "onboarding") {
            OnboardingView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
    }
}
