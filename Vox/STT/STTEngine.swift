import Foundation
import WhisperKit

@MainActor
final class STTEngine {
    private var whisperKit: WhisperKit?

    var isLoaded: Bool { whisperKit != nil }

    func loadModel() async throws {
        let config = WhisperKitConfig(model: "base.en", verbose: false)
        whisperKit = try await WhisperKit(config)
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw STTError.modelNotLoaded
        }

        nonisolated(unsafe) let kit = whisperKit
        let results = try await kit.transcribe(audioArray: audioSamples)

        return results
            .map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
