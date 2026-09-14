// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

protocol HabitDataStore: Sendable {
    func load() async throws -> HabitData
    func saveEntries(_ entries: [HabitEntry]) async throws -> HabitData
    func savePreferences(selected: [Habit], custom: [Habit]) async throws -> HabitData
}
