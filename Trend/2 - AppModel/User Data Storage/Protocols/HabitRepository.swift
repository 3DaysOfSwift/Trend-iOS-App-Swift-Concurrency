// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

protocol HabitRepository: Sendable {
    func load() async throws -> HabitStore
    func save(_ store: HabitStore) async throws
}
