// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import CloudKit
import Foundation

protocol HabitCloudClient: Sendable {
    func merge(_ local: HabitData, since previous: HabitData?) async throws -> HabitData
}

actor CloudKitHabitClient: HabitCloudClient {
    private let database: CKDatabase
    private let changes: HabitDataChanges
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let recordID = CKRecord.ID(recordName: "primary")

    init(container: CKContainer = .default(), calendar: Calendar = .current) {
        database = container.privateCloudDatabase
        changes = HabitDataChanges(calendar: calendar)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func merge(_ local: HabitData, since previous: HabitData?) async throws -> HabitData {
        // Retry only a conflicting edit from another device; other failures reach the caller.
        for attempt in 0..<3 {
            let record = try await fetchRecord()
            let remote: HabitData
            if let payload = record["payload"] as? Data {
                remote = try decoder.decode(HabitData.self, from: payload)
            } else {
                // A new cloud record must receive the complete local history.
                remote = previous ?? HabitData(selectedHabitIDs: [], entries: [])
            }
            let merged = changes.apply(
                from: previous ?? HabitData(selectedHabitIDs: [], entries: []),
                to: local, onto: remote)
            if record.recordChangeTag != nil, merged == remote { return merged }
            record["payload"] = try encoder.encode(merged) as CKRecordValue
            do {
                let results = try await database.modifyRecords(
                    saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
                guard let saved = results.saveResults[recordID] else { throw CocoaError(.coderInvalidValue) }
                _ = try saved.get()
                return merged
            } catch let error as CKError where error.code == .serverRecordChanged && attempt < 2 {
                continue
            }
        }
        throw CKError(.serverRecordChanged)
    }

    private func fetchRecord() async throws -> CKRecord {
        do { return try await database.record(for: recordID) }
        catch let error as CKError where error.code == .unknownItem {
            return CKRecord(recordType: "HabitStore", recordID: recordID)
        }
    }
}
