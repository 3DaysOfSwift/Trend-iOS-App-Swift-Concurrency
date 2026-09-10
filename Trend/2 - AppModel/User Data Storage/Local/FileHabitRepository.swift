// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor FileHabitRepository: HabitRepository {
    // Store the last synchronized version beside the entries, in the same atomic write.
    // Comparing the two tells us which local edits still need to reach iCloud.
    struct Document: Codable, Sendable {
        var store: HabitStore
        var lastSynchronizedStore: HabitStore?
    }

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let changes: HabitStoreChanges

    init(fileURL: URL? = nil, calendar: Calendar = .current) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        self.fileURL = fileURL ?? directory.appending(path: "habit-store.json")
        changes = HabitStoreChanges(calendar: calendar)
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> HabitStore { try readDocument().store }

    func save(_ store: HabitStore) throws {
        var document = try readDocument()
        document.store = store
        try write(document)
    }

    func save(_ store: HabitStore, replacing previous: HabitStore) async throws -> HabitStore {
        var document = try readDocument()
        // iCloud may have added entries since the manager last read this file.
        // Read, merge and write without suspending, so another file operation cannot interrupt.
        document.store = changes.apply(from: previous, to: store, onto: document.store)
        try write(document)
        return document.store
    }

    func readDocument() throws -> Document {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return Document(store: HabitStore(selectedHabitIDs: [], entries: []))
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Document.self, from: data)
    }

    func acceptSynchronizedStore(_ synchronized: HabitStore, localAtStart: HabitStore) throws {
        var document = try readDocument()
        // Keep any entries the user changed while the upload was running.
        document.store = changes.apply(from: localAtStart, to: document.store, onto: synchronized)
        document.lastSynchronizedStore = synchronized
        try write(document)
    }

    private func write(_ document: Document) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }
}
