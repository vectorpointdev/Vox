import AVFoundation
import Foundation

/// Thread-safe audio sample accumulator for bridging real-time audio thread to main thread.
final class AudioSampleBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []

    func append(_ newSamples: [Float]) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func drain() -> [Float] {
        lock.lock()
        let result = samples
        samples.removeAll(keepingCapacity: true)
        lock.unlock()
        return result
    }
}

@MainActor
final class AudioPipeline {
    private let engine = AVAudioEngine()
    private let sampleBuffer = AudioSampleBuffer()
    private var isCapturing = false

    // Target format for WhisperKit: 16kHz mono Float32
    private let targetSampleRate: Double = 16000

    init() {
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleConfigurationChange()
            }
        }
    }

    func startCapture() throws {
        _ = sampleBuffer.drain() // Clear any leftover samples
        isCapturing = true

        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioPipelineError.formatError
        }

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw AudioPipelineError.converterError
        }

        let buffer = sampleBuffer // Capture the Sendable buffer for the closure

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { inputBuffer, _ in
            // Runs on real-time audio thread — keep minimal
            let ratio = targetFormat.sampleRate / inputBuffer.format.sampleRate
            let frameCount = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)
            guard frameCount > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }

            guard status != .error, error == nil,
                  let channelData = convertedBuffer.floatChannelData else { return }

            let count = Int(convertedBuffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: count))
            buffer.append(samples)
        }

        engine.prepare()
        try engine.start()
    }

    func stopCapture() -> [Float] {
        guard isCapturing else { return [] }
        isCapturing = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        return sampleBuffer.drain()
    }

    private func handleConfigurationChange() {
        guard isCapturing else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
    }

    enum AudioPipelineError: Error, LocalizedError {
        case formatError
        case converterError

        var errorDescription: String? {
            switch self {
            case .formatError: "Failed to create target audio format"
            case .converterError: "Failed to create audio converter"
            }
        }
    }
}
