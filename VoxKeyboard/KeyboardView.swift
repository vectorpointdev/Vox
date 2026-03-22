import SwiftUI

struct KeyboardView: View {
    @Bindable var state: KeyboardState
    let onNextKeyboard: () -> Void
    @State private var showUppercase = false
    @State private var showNumbers = false

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            statusBar
                .padding(.horizontal, 12)
                .padding(.top, 4)

            // Keyboard area
            if state.isRecording || state.isProcessing {
                dictationOverlay
                    .frame(height: 180)
            } else if showNumbers {
                numberKeyboard
                    .frame(height: 180)
            } else {
                letterKeyboard
                    .frame(height: 180)
            }

            // Bottom row with special keys
            bottomRow
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            if state.isModelLoading {
                ProgressView()
                    .controlSize(.mini)
            }
            Text(state.statusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()

            if !state.lastTranscription.isEmpty && !state.isRecording && !state.isProcessing {
                Text(state.lastTranscription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 150)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Letter Keyboard

    private var letterKeyboard: some View {
        let rows: [[String]] = [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"]
        ]

        return VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 4) {
                    if rowIndex == 2 {
                        // Shift key
                        Button {
                            showUppercase.toggle()
                        } label: {
                            Image(systemName: showUppercase ? "shift.fill" : "shift")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 38)
                                .background(showUppercase ? Color(.systemGray3) : Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }

                    ForEach(row, id: \.self) { key in
                        KeyButton(label: showUppercase ? key : key.lowercased()) {
                            state.insertText(showUppercase ? key : key.lowercased())
                            if showUppercase { showUppercase = false }
                        }
                    }

                    if rowIndex == 2 {
                        // Backspace key
                        Button {
                            state.deleteBackward()
                        } label: {
                            Image(systemName: "delete.left")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 38)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Number Keyboard

    private var numberKeyboard: some View {
        let rows: [[String]] = [
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
            [".", ",", "?", "!", "'"]
        ]

        return VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 4) {
                    if rowIndex == 2 {
                        Button {
                            // Could add symbols page
                        } label: {
                            Text("#+=")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 36, height: 38)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }

                    ForEach(row, id: \.self) { key in
                        KeyButton(label: key) {
                            state.insertText(key)
                        }
                    }

                    if rowIndex == 2 {
                        Button {
                            state.deleteBackward()
                        } label: {
                            Image(systemName: "delete.left")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 38)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Dictation Overlay

    private var dictationOverlay: some View {
        VStack(spacing: 16) {
            Spacer()

            if state.isRecording {
                // Animated recording indicator
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 60, height: 60)

                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                }

                Text("Listening...")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text("Tap mic to stop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if state.isProcessing {
                ProgressView()
                    .controlSize(.large)

                Text("Processing...")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: 4) {
            // Globe / next keyboard
            Button {
                onNextKeyboard()
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .frame(width: 40, height: 38)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            // 123 / ABC toggle
            Button {
                showNumbers.toggle()
            } label: {
                Text(showNumbers ? "ABC" : "123")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 40, height: 38)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            // Dictation button
            Button {
                state.toggleDictation()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: state.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                    if !state.isRecording && !state.isProcessing {
                        Text("Dictate")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(height: 38)
                .padding(.horizontal, 16)
                .background(
                    state.isRecording
                        ? Color.red
                        : (state.isProcessing ? Color.orange : Color.accentColor)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .disabled(state.isProcessing)

            // Space bar
            Button {
                state.insertText(" ")
            } label: {
                Text("space")
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            // Return
            Button {
                state.insertNewline()
            } label: {
                Image(systemName: "return")
                    .font(.system(size: 16))
                    .frame(width: 60, height: 38)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

// MARK: - Key Button

struct KeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5)
        }
        .buttonStyle(.plain)
    }
}
