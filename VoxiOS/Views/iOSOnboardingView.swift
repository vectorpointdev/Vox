import SwiftUI

struct iOSOnboardingView: View {
    @Environment(iOSAppState.self) private var appState
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
            .padding(.top, 20)

            Spacer()

            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                microphoneStep
            case 2:
                keyboardStep
            case 3:
                readyStep
            default:
                EmptyView()
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Vox")
                .font(.largeTitle.bold())

            Text("Intelligent voice dictation powered by on-device AI.\nSpeak naturally and get polished text.")
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
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Microphone Access")
                .font(.title.bold())

            Text("Vox needs your microphone to hear your voice for dictation.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if appState.hasMicrophonePermission {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

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

                Button("Skip for now") {
                    withAnimation { currentStep = 2 }
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var keyboardStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Enable Vox Keyboard")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: "1", text: "Open Settings → General → Keyboard")
                instructionRow(number: "2", text: "Tap Keyboards → Add New Keyboard")
                instructionRow(number: "3", text: "Select Vox")
                instructionRow(number: "4", text: "Tap Vox → Enable Allow Full Access")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Open Keyboard Settings") {
                appState.openKeyboardSettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Continue") {
                withAnimation { currentStep = 3 }
            }
            .foregroundStyle(.secondary)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title.bold())

            VStack(spacing: 8) {
                Text("Switch to Vox using the **globe key** on your keyboard, then tap the **mic button** to start dictating.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button("Start Using Vox") {
                appState.onboardingComplete = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
        }
    }
}
