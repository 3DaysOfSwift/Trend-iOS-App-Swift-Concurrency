// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor FileWeightRepository: WeightRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        self.fileURL = fileURL ?? directory.appending(path: "weight-store.json")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async throws -> WeightStore {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return WeightStore(entries: [], goalKilograms: nil)
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(WeightStore.self, from: data)
    }

    func save(_ store: WeightStore) async throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(store).write(to: fileURL, options: .atomic)
    }
}
