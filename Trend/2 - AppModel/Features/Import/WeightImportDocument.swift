// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct WeightImportDocument: Sendable {
    let source: String
    let entries: [WeightEntry]
    let explanation: String

    static func validate(_ entries: [WeightEntry]) throws {
        guard entries.count <= 50_000 else { throw WeightImportError.invalid("Import up to 50,000 entries at a time.") }
        for (index, entry) in entries.enumerated() {
            guard entry.kilograms.isFinite, entry.kilograms > 0, entry.kilograms <= 1_000,
                  entry.date.timeIntervalSince1970.isFinite,
                  (-2_208_988_800...32_503_680_000).contains(entry.date.timeIntervalSince1970) else {
                throw WeightImportError.invalid("Entry \(index + 1) has an invalid date or weight. Nothing has been changed.")
            }
        }
    }
}

struct WeightImportMerge: Sendable {
    let additions: [WeightEntry]
    let skipped: Int

    /// Keep existing records, including their notes. Different measurements on
    /// the same day remain separate. Matching timestamps are compared to a second
    /// because Trend's exported JSON dates have second precision.
    init(incoming: [WeightEntry], existing: [WeightEntry]) {
        var ids = Set(existing.map(\.id))
        var measurements = Set(existing.map(Measurement.init))
        var additions: [WeightEntry] = []
        for entry in incoming {
            let key = Measurement(entry)
            if ids.contains(entry.id) || measurements.contains(key) { continue }
            ids.insert(entry.id)
            measurements.insert(key)
            additions.append(entry)
        }
        self.additions = additions
        skipped = incoming.count - additions.count
    }

    private struct Measurement: Hashable {
        let second: Int64
        let weight: Int64

        init(_ entry: WeightEntry) {
            second = Int64(entry.date.timeIntervalSince1970.rounded())
            weight = Int64((entry.kilograms * 10_000).rounded())
        }
    }
}

enum WeightImportError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): message }
    }
}
