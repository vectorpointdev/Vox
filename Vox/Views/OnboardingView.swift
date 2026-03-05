import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var currentStep = 0

    var body: some View {
        VStack(spacing: 24) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                microphoneStep
            case 2:
                accessibilityStep
            case 3:
                readyStep
            default:
                EmptyView()
            }

            Spacer()
        }
        .padding(40)
        .frame(width: 480, height: 380)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Vox")
                .font(.largeTitle.bold())

            Text("Voice dictation powered by on-device AI.\nHold a hotkey, speak, and text appears at your cursor.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Get Started") {
                withAnimation { currentStep = 1 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Microphone Access")
                .font(.title.bold())

            Text("Vox needs your microphone to hear your voice for dictation.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if appState.hasMicrophonePermission {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Button("Continue") {
                    withAnimation { currentStep = 2 }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Grant Microphone Access") {
                    appState.requestMicrophonePermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Continue") {
                    withAnimation { currentStep = 2 }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "accessibility")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Accessibility Permission")
                .font(.title.bold())

            Text("Vox needs Accessibility access to type text into other apps.\nYou'll need to enable this in System Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if appState.hasAccessibilityPermission {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Button("Continue") {
                    withAnimation { currentStep = 3 }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Open System Settings") {
                    appState.requestAccessibilityPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("I've enabled it") {
                    appState.checkPermissions()
                    if appState.hasAccessibilityPermission {
                        withAnimation { currentStep = 3 }
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title.bold())

            if appState.isModelLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Downloading speech model...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if appState.isModelLoaded {
                Text("Hold **Option+Space** to start dictating.\nCustomize your hotkey in Settings.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("Speech model will download on first use.")
                    .foregroundStyle(.secondary)
            }

            Button("Start Using Vox") {
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
                dismissWindow(id: "onboarding")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
