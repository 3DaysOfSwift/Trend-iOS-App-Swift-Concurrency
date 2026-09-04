// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

protocol HabitRepository: Sendable {
    func load() async throws -> HabitStore
    func save(_ store: HabitStore) async throws
}

actor FileHabitRepository: HabitRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        self.fileURL = fileURL ?? directory.appending(path: "habit-store.json")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async throws -> HabitStore {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return HabitStore(habits: [], entries: [])
        }
        return try decoder.decode(HabitStore.self, from: Data(contentsOf: fileURL))
    }

    func save(_ store: HabitStore) async throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(store).write(to: fileURL, options: .atomic)
    }
}
