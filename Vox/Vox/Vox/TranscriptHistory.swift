import Foundation
import VoxCore

typealias TranscriptItem = VoxCore.TranscriptItem

enum TranscriptHistoryStore {
    private static let store = TranscriptStore(storageKey: "vox.transcriptHistory")

    static func load() -> [TranscriptItem] {
        store.load()
    }

    static func save(_ items: [TranscriptItem]) {
        store.save(items)
    }
}
