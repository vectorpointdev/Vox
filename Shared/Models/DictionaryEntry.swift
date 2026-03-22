import Foundation

struct SharedDictionaryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var phrase: String
    var replacement: String

    enum CodingKeys: String, CodingKey {
        case phrase, replacement
    }
}

enum SharedDictionaryStore {
    private static let key = "customDictionary"

    /// App Group suite name for sharing data between iOS app and keyboard extension
    static let appGroupID = "group.com.andykim.vox"

    private static var defaults: UserDefaults {
        #if os(iOS)
        return UserDefaults(suiteName: appGroupID) ?? .standard
        #else
        return .standard
        #endif
    }

    static func load() -> [SharedDictionaryEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([SharedDictionaryEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func save(_ entries: [SharedDictionaryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }
}
