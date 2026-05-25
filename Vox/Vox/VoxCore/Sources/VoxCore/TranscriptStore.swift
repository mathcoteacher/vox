import Foundation

public struct TranscriptItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let text: String
    public let createdAt: Date

    public init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

public final class TranscriptStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let storageKey: String

    public init(defaults: UserDefaults = .standard, storageKey: String = "vox.transcriptHistory") {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    public func load() -> [TranscriptItem] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([TranscriptItem].self, from: data)) ?? []
    }

    public func save(_ items: [TranscriptItem]) {
        guard let data = try? JSONEncoder().encode(items) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    @discardableResult
    public func append(_ text: String, createdAt: Date = Date()) -> [TranscriptItem] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return load()
        }

        var items = load()
        if let first = items.first, first.text == trimmed {
            return items
        }

        items.insert(TranscriptItem(text: trimmed, createdAt: createdAt), at: 0)
        save(items)
        return items
    }

    @discardableResult
    public func remove(id: UUID) -> [TranscriptItem] {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
        return items
    }

    public func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
