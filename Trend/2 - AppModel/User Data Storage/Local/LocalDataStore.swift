// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import SwiftData
import CryptoKit

/// SwiftData access stays on one actor. Explicit operations use fresh contexts
/// and save before returning, without suspension during read/write work.
/// Apple's ModelContainer owns CloudKit synchronization.
actor LocalDataStore {
    nonisolated let changes: AsyncStream<Void>
    private let notification: AsyncStream<Void>.Continuation
    let directory: URL
    private let cloudContainerIdentifier: String?
    private var container: ModelContainer?
    private var writesSuspended = false
    private var loadedWeight: WeightStore?
    private var loadedHabitEntries: [HabitEntry] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Tests remain local; live() supplies the CloudKit identifier.
    /// Construction does not load data or start asynchronous work.
    init(directory: URL, cloudContainerIdentifier: String? = nil) {
        self.directory = directory
        self.cloudContainerIdentifier = cloudContainerIdentifier
        encoder.outputFormatting = [.sortedKeys]
        (changes, notification) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
    }

    private func context() throws -> ModelContext {
        if container == nil {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let schema = Schema([StoredWeightEntry.self, StoredHabitEntry.self, StoredPreference.self])
            let configuration = ModelConfiguration(schema: schema,
                url: directory.appending(path: "Trend.store"),
                cloudKitDatabase: cloudContainerIdentifier.map { .private($0) } ?? .none)
            container = try ModelContainer(for: schema, configurations: [configuration])
        }
        let context = ModelContext(container!)
        context.autosaveEnabled = false
        return context
    }

    func loadWeight() throws -> WeightStore {
        let value = try readWeight(in: context())
        loadedWeight = value
        return value
    }

    func saveWeight(_ store: WeightStore) throws {
        try requireWritable()
        let context = try context()
        try writeWeight(store, replacing: loadedWeight, in: context)
        try context.save()
        loadedWeight = store
        notification.yield(())
    }

    func loadHabits() throws -> HabitData {
        let data = try readHabits(in: context())
        loadedHabitEntries = data.entries
        return data
    }

    func saveHabitEntries(_ entries: [HabitEntry]) throws -> HabitData {
        try requireWritable()
        let context = try context()
        try writeHabitEntries(entries, replacing: loadedHabitEntries, in: context)
        try context.save()
        let data = try readHabits(in: context)
        loadedHabitEntries = data.entries
        notification.yield(())
        return data
    }

    func saveHabitPreferences(selected: [Habit], custom: [Habit]) throws -> HabitData {
        try requireWritable()
        let context = try context()
        try put(selected, key: "selectedHabits", in: context)
        try put(custom, key: "customHabits", in: context)
        try context.save()
        notification.yield(())
        return try readHabits(in: context)
    }

    func snapshot() throws -> RecoverySnapshot {
        let context = try context()
        let weight = try readWeight(in: context)
        let habits = try readHabits(in: context)
        // Content identity includes remote changes, without altering edit baselines.
        struct Contents: Encodable { let weight: WeightStore; let habits: HabitData }
        let hash = SHA256.hash(data: try encoder.encode(Contents(weight: weight, habits: habits)))
        let chars = Array(hash.prefix(16).map { String(format: "%02x", $0) }.joined())
        let revision = [0..<8, 8..<12, 12..<16, 16..<20, 20..<32]
            .map { String(chars[$0]) }.joined(separator: "-")
        return RecoverySnapshot(revision: revision, createdAt: .now, weight: weight, habits: habits)
    }

    /// Explicit replacement synchronizes too. Keep a pre-restore recovery copy first.
    func restore(_ snapshot: RecoverySnapshot) throws {
        try requireWritable()
        try snapshot.validate()
        let previous = try self.snapshot()
        let folder = directory.appending(path: "Backups/Before-restore", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try encoder.encode(previous).write(to: folder.appending(path: "\(UUID().uuidString).json"), options: .atomic)
        let context = try context()
        try writeWeight(snapshot.weight, replacing: readWeight(in: context), in: context)
        try writeHabitEntries(snapshot.habits.entries, replacing: readHabits(in: context).entries, in: context)
        try put(snapshot.habits.enabledHabits, key: "selectedHabits", in: context)
        try put(snapshot.habits.customHabits, key: "customHabits", in: context)
        try context.save()
        loadedWeight = snapshot.weight
        loadedHabitEntries = snapshot.habits.entries
        writesSuspended = true
        notification.yield(())
    }

    func finishRestore() { writesSuspended = false }
    private func requireWritable() throws {
        guard !writesSuspended else { throw StoreError.failure("Restore is finishing. Please try recording again in a moment.") }
    }
    func close() { container = nil; loadedWeight = nil; loadedHabitEntries = [] }

    private func readWeight(in context: ModelContext) throws -> WeightStore {
        let records = try context.fetch(FetchDescriptor<StoredWeightEntry>(sortBy: [SortDescriptor(\.modifiedAt)]))
        var entries: [UUID: WeightEntry] = [:]
        for record in records { entries[record.id] = record.value }
        return WeightStore(entries: entries.values.sorted { $0.id.uuidString < $1.id.uuidString },
                           goalKilograms: try preference(Double?.self, key: "goal", in: context) ?? nil)
    }

    private func readHabits(in context: ModelContext) throws -> HabitData {
        let records = try context.fetch(FetchDescriptor<StoredHabitEntry>(sortBy: [SortDescriptor(\.modifiedAt)]))
        var entries: [UUID: HabitEntry] = [:]
        for record in records { entries[record.id] = try record.entry() }
        var data = HabitData(enabledHabits: try preference([Habit].self, key: "selectedHabits", in: context) ?? [],
                             entries: entries.values.sorted { $0.id.uuidString < $1.id.uuidString })
        data.customHabits = try preference([Habit].self, key: "customHabits", in: context) ?? []
        return data
    }

    private func writeWeight(_ store: WeightStore, replacing baseline: WeightStore?, in context: ModelContext) throws {
        guard Set(store.entries.map(\.id)).count == store.entries.count,
              store.entries.allSatisfy({ $0.kilograms.isFinite && $0.kilograms > 0 && $0.date.timeIntervalSince1970.isFinite }),
              store.goalKilograms.map({ $0.isFinite && $0 > 0 }) ?? true else {
            throw StoreError.failure("Invalid weight records. Existing data has not been replaced.")
        }
        let rows = try context.fetch(FetchDescriptor<StoredWeightEntry>())
        let removed = Set((baseline?.entries ?? []).map(\.id)).subtracting(Set(store.entries.map(\.id)))
        for row in rows where removed.contains(row.id) { context.delete(row) }
        // Apply only the user's delta, never deleting unseen remote records or
        // overwriting remote edits to rows the user has not changed.
        for entry in store.entries where !(baseline?.entries.contains(entry) ?? false) {
            let matches = rows.filter { $0.id == entry.id }
            if matches.isEmpty { context.insert(StoredWeightEntry(entry)) }
            else { for row in matches { row.update(entry) } }
        }
        if baseline == nil || baseline?.goalKilograms != store.goalKilograms {
            try put(store.goalKilograms, key: "goal", in: context)
        }
    }

    private func writeHabitEntries(_ entries: [HabitEntry], replacing baseline: [HabitEntry], in context: ModelContext) throws {
        guard Set(entries.map(\.id)).count == entries.count,
              entries.allSatisfy({ $0.value.isFinite && $0.value >= 0 && $0.date.timeIntervalSince1970.isFinite }) else {
            throw StoreError.failure("Invalid habit records. Existing data has not been replaced.")
        }
        let rows = try context.fetch(FetchDescriptor<StoredHabitEntry>())
        let removed = Set(baseline.map(\.id)).subtracting(Set(entries.map(\.id)))
        for row in rows where removed.contains(row.id) { context.delete(row) }
        for entry in entries where !baseline.contains(entry) {
            let matches = rows.filter { $0.id == entry.id }
            if matches.isEmpty { context.insert(StoredHabitEntry(entry)) }
            else { for row in matches { row.update(entry) } }
        }
    }

    private func preference<T: Decodable>(_ type: T.Type, key: String, in context: ModelContext) throws -> T? {
        let rows = try context.fetch(FetchDescriptor<StoredPreference>())
            .filter { $0.key == key }.sorted {
                $0.modifiedAt == $1.modifiedAt ? $0.recordID.uuidString < $1.recordID.uuidString : $0.modifiedAt < $1.modifiedAt
            }
        guard let row = rows.last else { return nil }
        return try decoder.decode(type, from: row.payload)
    }

    private func put<T: Encodable>(_ value: T, key: String, in context: ModelContext) throws {
        let data = try encoder.encode(value)
        let rows = try context.fetch(FetchDescriptor<StoredPreference>()).filter { $0.key == key }
        if rows.isEmpty { context.insert(StoredPreference(key: key, payload: data)) }
        else { for row in rows where row.payload != data { row.payload = data; row.modifiedAt = .now } }
    }
}

enum StoreError: LocalizedError {
    case failure(String)
    var errorDescription: String? { switch self { case .failure(let message): message } }
}

struct LocalWeightRepository: WeightRepository {
    let storage: LocalDataStore
    func load() async throws -> WeightStore { try await storage.loadWeight() }
    func save(_ store: WeightStore) async throws { try await storage.saveWeight(store) }
}

struct LocalHabitRepository: HabitDataStore {
    let storage: LocalDataStore
    func load() async throws -> HabitData { try await storage.loadHabits() }
    func saveEntries(_ entries: [HabitEntry]) async throws -> HabitData { try await storage.saveHabitEntries(entries) }
    func savePreferences(selected: [Habit], custom: [Habit]) async throws -> HabitData {
        try await storage.saveHabitPreferences(selected: selected, custom: custom)
    }
}
