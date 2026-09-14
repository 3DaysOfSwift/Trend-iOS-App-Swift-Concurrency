// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// File access and format decoding happen off the main actor. Neither operation
/// changes the database. Add new format adapters here as sample exports arrive.
actor WeightImportFileReader {
    static let maximumBytes = 20 * 1024 * 1024

    func read(_ url: URL, timeZone: TimeZone) throws -> WeightImportDocument {
        guard url.isFileURL else { throw WeightImportError.invalid("Choose a local CSV or Trend JSON backup file.") }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        // A false security-scope result is normal for files already in our sandbox.
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: Self.maximumBytes + 1) ?? Data()
        return try decode(data, timeZone: timeZone)
    }

    func decode(_ data: Data, timeZone: TimeZone) throws -> WeightImportDocument {
        guard data.count <= Self.maximumBytes else { throw WeightImportError.invalid("This file exceeds the 20 MB import limit.") }
        guard let text = String(data: data, encoding: .utf8) else {
            throw WeightImportError.invalid("Use a UTF-8 CSV file or a Trend JSON backup.")
        }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{feff}")))
        let document: WeightImportDocument
        if cleaned.first == "{" {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let jsonData = Data(cleaned.utf8)
            let object = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            if object?["formatVersion"] != nil {
                let snapshot = try decoder.decode(RecoverySnapshot.self, from: jsonData)
                try snapshot.validate()
                document = WeightImportDocument(source: "Trend recovery backup", entries: snapshot.weight.entries,
                    explanation: "Only weight entries will be merged. Habits, goal and settings will not change.")
            } else {
                let store = try decoder.decode(WeightStore.self, from: jsonData)
                document = WeightImportDocument(source: "Trend weight backup", entries: store.entries,
                    explanation: "Only weight entries will be merged. Your current goal will not change.")
            }
        } else {
            document = try WeightCSVDecoder.decode(cleaned, timeZone: timeZone)
        }
        guard !document.entries.isEmpty else { throw WeightImportError.invalid("No weight entries were found. Nothing has been changed.") }
        try WeightImportDocument.validate(document.entries)
        return document
    }
}
