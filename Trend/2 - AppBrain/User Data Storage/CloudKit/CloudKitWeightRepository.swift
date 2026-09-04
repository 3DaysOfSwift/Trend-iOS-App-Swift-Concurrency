import CloudKit
import Foundation

/// Stores the canonical payload in the user's private CloudKit database and keeps
/// an on-device cache so logging continues to work without a network connection.
actor CloudKitWeightRepository: LocallyCachedWeightRepository, CloudSyncStatusProviding {
    private enum Schema {
        static let recordType = "WeightStore"
        static let recordName = "primary"
        static let payload = "payload"
        static let schemaVersion = "schemaVersion"
        static let currentVersion: Int64 = 1
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let cache: FileWeightRepository
    private let pendingUploadURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var uploadTask: Task<Void, Never>?

    init(
        container: CKContainer = .default(),
        cache: FileWeightRepository = FileWeightRepository()
    ) {
        self.container = container
        database = container.privateCloudDatabase
        self.cache = cache
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        pendingUploadURL = support.appending(path: "cloud-upload-pending")

        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() async throws -> WeightStore {
        let localStore = try await loadCached()
        return await synchronize(localStore)
    }

    func loadCached() async throws -> WeightStore {
        try await cache.load()
    }

    func synchronize(_ localStore: WeightStore) async -> WeightStore {
        guard await cloudStatus() == .available else { return localStore }

        do {
            if hasPendingUpload {
                // A save may have occurred after synchronization began. Always
                // upload the newest durable value rather than the launch snapshot.
                let newestLocalStore = try await cache.load()
                try await upload(newestLocalStore)
                try clearPendingUpload()
                return newestLocalStore
            }

            guard let cloudStore = try await download() else { return localStore }

            // Never let a download overwrite a local save made while CloudKit was
            // responding. The pending marker makes that newer local value canonical.
            if hasPendingUpload {
                let newestLocalStore = try await cache.load()
                try await upload(newestLocalStore)
                try clearPendingUpload()
                return newestLocalStore
            }

            try await cache.save(cloudStore)
            return cloudStore
        } catch {
            // Cloud availability must never prevent access to locally cached health data.
            return localStore
        }
    }

    func save(_ store: WeightStore) async throws {
        try await cache.save(store)
        try markPendingUpload()

        // The on-device write is the user-facing save. Cloud synchronization is
        // repository-owned work so it can continue after the initiating View goes away.
        uploadTask?.cancel()
        uploadTask = Task { [weak self] in
            await self?.uploadPendingStore()
        }
    }

    private func uploadPendingStore() async {
        guard !Task.isCancelled, await cloudStatus() == .available else { return }
        do {
            let newestLocalStore = try await cache.load()
            guard !Task.isCancelled else { return }
            try await upload(newestLocalStore)
            guard !Task.isCancelled else { return }
            try clearPendingUpload()
        } catch {
            // The durable marker causes the local value to be retried on the next launch.
            // Background synchronization failures are intentionally not user-facing save failures.
        }
    }

    func cloudStatus() async -> CloudSyncStatus {
        do {
            switch try await container.accountStatus() {
            case .available: return CloudSyncStatus.available
            case .noAccount: return CloudSyncStatus.unavailable
            case .restricted: return CloudSyncStatus.restricted
            case .couldNotDetermine, .temporarilyUnavailable: return CloudSyncStatus.temporarilyUnavailable
            @unknown default: return CloudSyncStatus.temporarilyUnavailable
            }
        } catch {
            return CloudSyncStatus.temporarilyUnavailable
        }
    }

    private func download() async throws -> WeightStore? {
        do {
            let record = try await database.record(for: recordID)
            guard let payload = record[Schema.payload] as? Data else { return nil }
            return try decoder.decode(WeightStore.self, from: payload)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func upload(_ store: WeightStore) async throws {
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: Schema.recordType, recordID: recordID)
        }
        record[Schema.payload] = try encoder.encode(store) as CKRecordValue
        record[Schema.schemaVersion] = Schema.currentVersion as CKRecordValue
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
