import Foundation

/// Reads user-selected backup documents outside the main actor and returns the
/// application value that the settings feature can import.
actor BackupFileManager {
    func encode(_ store: WeightStore) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(store)
    }

    func readWeightStore(from url: URL) throws -> WeightStore {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WeightStore.self, from: Data(contentsOf: url))
    }
}
