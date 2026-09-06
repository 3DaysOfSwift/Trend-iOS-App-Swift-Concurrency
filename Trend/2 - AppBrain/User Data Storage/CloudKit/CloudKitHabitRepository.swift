// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import CloudKit
import Foundation

/// Keeps paid habit history available offline and synchronizes the canonical
/// document through the user's private iCloud database.
actor CloudKitHabitRepository: HabitRepository {
    private enum Schema {
        static let recordType = "HabitStore"
        static let recordName = "primary"
        static let payload = "payload"
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let cache: FileHabitRepository
    private let pendingUploadURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var uploadTask: Task<Void, Never>?

    init(
        container: CKContainer = .default(),
        cache: FileHabitRepository = FileHabitRepository()
    ) {
        self.container = container
        database = container.privateCloudDatabase
        self.cache = cache
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        pendingUploadURL = support.appending(path: "habit-cloud-upload-pending")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async throws -> HabitStore {
        let localStore = try await cache.load()
        guard await cloudIsAvailable else { return localStore }

        do {
            if hasPendingUpload {
                try await upload(localStore)
                try clearPendingUpload()
                return localStore
            }
            guard let cloudStore = try await download() else { return localStore }
            if hasPendingUpload { return localStore }
            try await cache.save(cloudStore)
            return cloudStore
        } catch {
            return localStore
        }
    }

    func save(_ store: HabitStore) async throws {
        try await cache.save(store)
        try markPendingUpload()
        uploadTask?.cancel()
        uploadTask = Task { [weak self] in await self?.uploadPendingStore() }
    }

    private func uploadPendingStore() async {
        guard !Task.isCancelled, await cloudIsAvailable else { return }
        do {
            let store = try await cache.load()
            guard !Task.isCancelled else { return }
            try await upload(store)
            guard !Task.isCancelled else { return }
            try clearPendingUpload()
        } catch {
            // The marker deliberately survives so the next launch retries.
        }
    }

    private var cloudIsAvailable: Bool {
        get async {
            do { return try await container.accountStatus() == .available }
            catch { return false }
        }
    }

    private func download() async throws -> HabitStore? {
        do {
            let record = try await database.record(for: recordID)
            guard let payload = record[Schema.payload] as? Data else { return nil }
            return try decoder.decode(HabitStore.self, from: payload)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func upload(_ store: HabitStore) async throws {
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: Schema.recordType, recordID: recordID)
        }
        record[Schema.payload] = try encoder.encode(store) as CKRecordValue
        _ = try await database.save(record)
    }

    private var recordID: CKRecord.ID { CKRecord.ID(recordName: Schema.recordName) }
    private var hasPendingUpload: Bool { FileManager.default.fileExists(atPath: pendingUploadURL.path()) }

    private func markPendingUpload() throws {
        try FileManager.default.createDirectory(at: pendingUploadURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: pendingUploadURL, options: .atomic)
    }

    private func clearPendingUpload() throws {
        guard hasPendingUpload else { return }
        try FileManager.default.removeItem(at: pendingUploadURL)
    }
}
