import Foundation

struct TranscriptItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let createdAt: Date
}

enum TranscriptHistoryStore {
    private static let storageKey = "vox.transcriptHistory"

    static func load() -> [TranscriptItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([TranscriptItem].self, from: data)) ?? []
    }

    static func save(_ items: [TranscriptItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
