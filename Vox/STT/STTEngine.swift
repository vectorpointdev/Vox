import Foundation
import WhisperKit

@MainActor
final class STTEngine {
    private var whisperKit: WhisperKit?

    var isLoaded: Bool { whisperKit != nil }

    func loadModel() async throws {
        let modelConfig = await RemoteConfig.fetchModelConfig()
        let config = WhisperKitConfig(
            model: modelConfig.model,
            modelRepo: modelConfig.modelRepo,
            verbose: false
        )
        whisperKit = try await WhisperKit(config)
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw STTError.modelNotLoaded
        }

        nonisolated(unsafe) let kit = whisperKit
        let results = try await kit.transcribe(audioArray: audioSamples)

        let segments = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        print("[Vox STT] Raw segments: \(segments)")

        // Filter out Whisper hallucination artifacts (e.g. [BLANK_AUDIO], [MUSIC PLAYING], [SILENCE])
        let bracketPattern = try! NSRegularExpression(pattern: "\\[[A-Z_ ]+\\]", options: .caseInsensitive)

        let filtered = segments
            .map { segment in
                bracketPattern.stringByReplacingMatches(
                    in: segment,
                    range: NSRange(segment.startIndex..., in: segment),
                    withTemplate: ""
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return filtered
    }

    enum STTError: Error, LocalizedError {
        case modelNotLoaded

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded: "Speech model not loaded"
            }
        }
    }
}
