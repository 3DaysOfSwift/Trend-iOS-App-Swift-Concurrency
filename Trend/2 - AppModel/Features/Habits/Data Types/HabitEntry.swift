// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct HabitEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let habitType: Habit.HabitType
    let date: Date
    let value: Double
    let occurrenceCount: Int?
    let customHabitID: String?
    var habitID: String { customHabitID ?? habitType.rawValue }

    init(id: UUID, habitType: Habit.HabitType, date: Date, value: Double, occurrenceCount: Int? = nil, customHabitID: String? = nil) {
        self.id = id
        self.habitType = habitType
        self.date = date
        self.value = value
        self.occurrenceCount = occurrenceCount
        self.customHabitID = customHabitID
    }
}
