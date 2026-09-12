// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor FileHabitDataStore: HabitDataStore {
    // Store the last synchronized version beside the entries, in the same atomic write.
    // Comparing the two tells us which local edits still need to reach iCloud.
    struct Document: Codable, Sendable {
        var data: HabitData
        var lastSynchronizedData: HabitData?
    }

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let changes: HabitDataChanges

    init(fileURL: URL? = nil, calendar: Calendar = .current) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        self.fileURL = fileURL ?? directory.appending(path: "habit-data.json")
        changes = HabitDataChanges(calendar: calendar)
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> HabitData { try readDocument().data }

    func save(_ data: HabitData, replacing previous: HabitData) async throws -> HabitData {
        var document = try readDocument()
        // iCloud may have added entries since the manager last read this file.
        // Read, merge and write without suspending, so another file operation cannot interrupt.
        document.data = changes.apply(from: previous, to: data, onto: document.data)
        try write(document)
        return document.data
    }

    func readDocument() throws -> Document {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return Document(data: HabitData(enabledHabits: [], entries: []))
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Document.self, from: data)
    }

    func acceptSynchronizedData(_ synchronized: HabitData, localAtStart: HabitData) throws {
        var document = try readDocument()
        // Keep any entries the user changed while the upload was running.
        document.data = changes.apply(from: localAtStart, to: document.data, onto: synchronized)
        document.lastSynchronizedData = synchronized
        try write(document)
    }

    private func write(_ document: Document) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }
}
