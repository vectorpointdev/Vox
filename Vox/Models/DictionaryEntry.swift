import Foundation

struct DictionaryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var phrase: String
    var replacement: String

    enum CodingKeys: String, CodingKey {
        case phrase, replacement
    }
}

enum DictionaryStore {
    private static let key = "customDictionary"

    static func load() -> [DictionaryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([DictionaryEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func save(_ entries: [DictionaryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
