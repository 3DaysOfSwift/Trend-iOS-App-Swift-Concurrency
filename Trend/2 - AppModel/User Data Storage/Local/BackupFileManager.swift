// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// Encodes weight-history exports outside the main actor.
actor BackupFileManager {
    func encode(_ store: WeightStore) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(store)
    }

}
