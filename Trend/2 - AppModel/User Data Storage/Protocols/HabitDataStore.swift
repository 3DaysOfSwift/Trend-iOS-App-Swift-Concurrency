// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

protocol HabitDataStore: Sendable {
    func load() async throws -> HabitData
    func save(_ data: HabitData, replacing previous: HabitData) async throws -> HabitData
}

protocol HabitCloudSynchronizing: HabitDataStore {
    func synchronize() async throws
}
