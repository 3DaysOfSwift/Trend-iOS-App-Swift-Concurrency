// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

protocol HabitRepository: Sendable {
    func load() async throws -> HabitStore
    func save(_ store: HabitStore) async throws
    func save(_ store: HabitStore, replacing previous: HabitStore) async throws -> HabitStore
}

extension HabitRepository {
    func save(_ store: HabitStore, replacing previous: HabitStore) async throws -> HabitStore {
        try await save(store)
        return store
    }
}

protocol HabitCloudSynchronizing: HabitRepository {
    func synchronize() async throws
}
