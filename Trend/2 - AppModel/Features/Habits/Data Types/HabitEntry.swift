// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct HabitData: Codable, Equatable, Sendable {
    var selectedHabitIDs: Set<String>
    var entries: [HabitEntry]
}

struct HabitEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let habitType: Habit.HabitType
    let date: Date
    let value: Double
    let occurrenceCount: Int?

    init(id: UUID, habitType: Habit.HabitType, date: Date, value: Double, occurrenceCount: Int? = nil) {
        self.id = id
        self.habitType = habitType
        self.date = date
        self.value = value
        self.occurrenceCount = occurrenceCount
    }
}
