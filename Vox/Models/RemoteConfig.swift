import Foundation

struct ModelConfig: Decodable {
    let model: String
    let modelRepo: String

    static let fallback = ModelConfig(model: "base.en", modelRepo: "argmaxinc/whisperkit-coreml")
}

enum RemoteConfig {
    private static let configURL = URL(string: "https://vox-config.vercel.app/api/config")!
    private static let timeout: TimeInterval = 5

    static func fetchModelConfig() async -> ModelConfig {
        var request = URLRequest(url: configURL, timeoutInterval: timeout)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[Vox Config] Non-200 response, using fallback")
                return .fallback
            }
            let config = try JSONDecoder().decode(ModelConfig.self, from: data)
            print("[Vox Config] Remote config: model=\(config.model) repo=\(config.modelRepo)")
            return config
        } catch {
            print("[Vox Config] Fetch failed (\(error.localizedDescription)), using fallback")
            return .fallback
        }
    }
}
