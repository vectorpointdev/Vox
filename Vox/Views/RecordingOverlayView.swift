import SwiftUI

struct RecordingOverlayView: View {
    let isRecording: Bool
    let isProcessing: Bool

    var body: some View {
        if isRecording || isProcessing {
            HStack(spacing: 6) {
                Circle()
                    .fill(isRecording ? Color.red : Color.orange)
                    .frame(width: 8, height: 8)
                    .opacity(isRecording ? 1 : 0.8)

                Text(isRecording ? "Listening..." : "Processing...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 4)
        }
    }
}
