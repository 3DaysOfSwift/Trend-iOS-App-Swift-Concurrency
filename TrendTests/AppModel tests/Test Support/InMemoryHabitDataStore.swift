// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

actor InMemoryHabitDataStore: HabitDataStore {
    private var data: HabitData

    init(data: HabitData = HabitData(enabledHabits: [], entries: [])) {
        self.data = data
    }

    func savePreferences(selected: [Habit], custom: [Habit]) async throws -> HabitData {
        self.data.enabledHabits = selected
        self.data.customHabits = custom
        return self.data
    }

    func load() async throws -> HabitData { data }
    func saveEntries(_ entries: [HabitEntry]) async throws -> HabitData {
        self.data.entries = entries
        return self.data
    }
}
