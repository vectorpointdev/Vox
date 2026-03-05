import Foundation

actor LLMProcessor {
    private let timeoutSeconds: TimeInterval = 3

    func process(rawTranscription: String, context: DictationContext, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return rawTranscription }

        do {
            return try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask {
                    try await self.callClaudeAPI(
                        rawTranscription: rawTranscription,
                        context: context,
                        apiKey: apiKey
                    )
                }

                group.addTask {
                    try await Task.sleep(for: .seconds(self.timeoutSeconds))
                    throw LLMError.timeout
                }

                // Return whichever finishes first
                guard let result = try await group.next() else {
                    return rawTranscription
                }
                group.cancelAll()
                return result
            }
        } catch {
            // On any error (timeout, network, parse), fall back silently
            return rawTranscription
        }
    }

    private func callClaudeAPI(rawTranscription: String, context: DictationContext, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let appContext = context.appName.map { "The user is typing in \($0)." } ?? ""

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": """
                You are a dictation post-processor. Clean up raw speech transcripts into polished text.
                Rules:
                - Remove filler words (um, uh, like, you know, so, basically)
                - Fix grammar and punctuation
                - Add proper capitalization
                - If the speaker corrects themselves ("no wait", "I mean", "actually"), keep only the correction
                - Preserve the speaker's meaning exactly — do NOT add, remove, or change content
                - Return ONLY the cleaned text, nothing else
                \(appContext)
                """,
            "messages": [
                ["role": "user", "content": rawTranscription]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw LLMError.parseError
        }

        return text
    }

    enum LLMError: Error {
        case apiError
        case parseError
        case timeout
    }
}
