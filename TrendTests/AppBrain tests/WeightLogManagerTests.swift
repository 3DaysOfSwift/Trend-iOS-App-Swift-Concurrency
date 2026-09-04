// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct WeightLogManagerTests {
    @Test func addingEntryPersistsCanonicalKilograms() async throws {
        let repository = InMemoryWeightRepository()
        let manager = WeightLogManager(repository: repository)
        await manager.load()
        try await manager.add(
            WeightEntryDraft(date: .now, value: "75.5", note: " Test "),
            unit: .kilograms
        )
        let stored = try await repository.load()
        #expect(stored.entries.first?.kilograms == 75.5)
        #expect(stored.entries.first?.note == "Test")
    }

    @Test func cachedEntriesArePublishedBeforeCloudSynchronizationCompletes() async throws {
        let entry = WeightEntry(date: .now, kilograms: 71.2, note: "Cached")
        let repository = DelayedSynchronizationRepository(
            store: WeightStore(entries: [entry], goalKilograms: nil)
        )
        let manager = WeightLogManager(repository: repository)

        let loading = Task { await manager.load() }
        await repository.waitUntilSynchronizationStarts()

        #expect(manager.entries.map(\.id) == [entry.id])
        #expect(manager.state == .ready)

        loading.cancel()
        await loading.value
    }
}

private actor DelayedSynchronizationRepository: LocallyCachedWeightRepository {
    private let store: WeightStore
    private var synchronizationStarted = false
    private var synchronizationWaiters: [CheckedContinuation<Void, Never>] = []

    init(store: WeightStore) {
        self.store = store
    }

    func load() async throws -> WeightStore {
        await synchronize(try await loadCached())
    }

    func loadCached() async throws -> WeightStore {
        store
    }

    func synchronize(_ localStore: WeightStore) async -> WeightStore {
        synchronizationStarted = true
        synchronizationWaiters.forEach { $0.resume() }
        synchronizationWaiters.removeAll()
        try? await Task.sleep(for: .seconds(30))
        return localStore
    }

    func save(_ store: WeightStore) async throws {}

    func waitUntilSynchronizationStarts() async {
        guard !synchronizationStarted else { return }
        await withCheckedContinuation { continuation in
            synchronizationWaiters.append(continuation)
        }
    }
}
