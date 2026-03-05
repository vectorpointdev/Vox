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

        Settings {
            SettingsView()
                .environment(appState)
        }

        Window("Welcome to Vox", id: "onboarding") {
            OnboardingView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
    }
}
