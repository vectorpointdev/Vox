import Foundation
import WhisperKit

@MainActor
final class SharedSTTEngine {
    private var whisperKit: WhisperKit?

    var isLoaded: Bool { whisperKit != nil }

    func loadModel() async throws {
        let modelConfig = await RemoteConfig.fetchModelConfig()
        let config = WhisperKitConfig(
            model: modelConfig.model,
            modelRepo: modelConfig.modelRepo,
            verbose: false
        )
        do {
            whisperKit = try await WhisperKit(config)
        } catch {
            let errorDesc = String(describing: error)
            if errorDesc.contains("metadata") || errorDesc.contains("corrupted") || errorDesc.contains("permission") {
                print("[Vox STT] Corrupted model cache detected, clearing and retrying...")
                Self.clearModelCache(repo: modelConfig.modelRepo)
                whisperKit = try await WhisperKit(config)
            } else {
                throw error
            }
        }
    }

    private static func clearModelCache(repo: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cachePath = docs.appending(path: "huggingface/models/\(repo)")
        try? FileManager.default.removeItem(at: cachePath)
        print("[Vox STT] Cleared cache at \(cachePath.path)")
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw STTError.modelNotLoaded
        }

        nonisolated(unsafe) let kit = whisperKit
        let results = try await kit.transcribe(audioArray: audioSamples)

        let segments = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        print("[Vox STT] Raw segments: \(segments)")

        // Filter out Whisper hallucination artifacts
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
