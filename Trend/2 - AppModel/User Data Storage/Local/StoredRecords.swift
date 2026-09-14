// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import SwiftData

// Storage representations stay behind the repository boundary. Defaults and the
// absence of unique constraints make these models compatible with CloudKit.
@Model final class StoredWeightEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var kilograms: Double = 0
    var note: String = ""
    var modifiedAt: Date = Date.now

    init(_ entry: WeightEntry) { update(entry) }
    func update(_ entry: WeightEntry) {
        id = entry.id; date = entry.date; kilograms = entry.kilograms; note = entry.note
        modifiedAt = .now
    }
    var value: WeightEntry { WeightEntry(id: id, date: date, kilograms: kilograms, note: note) }
}

@Model final class StoredHabitEntry {
    var id: UUID = UUID()
    var habitType: String = ""
    var date: Date = Date.now
    var value: Double = 0
    var occurrenceCount: Int?
    var customHabitID: String?
    var modifiedAt: Date = Date.now

    init(_ entry: HabitEntry) { update(entry) }
    func update(_ entry: HabitEntry) {
        id = entry.id; habitType = entry.habitType.rawValue; date = entry.date
        value = entry.value; occurrenceCount = entry.occurrenceCount; customHabitID = entry.customHabitID
        modifiedAt = .now
    }
    func entry() throws -> HabitEntry {
        guard let type = Habit.HabitType(rawValue: habitType) else {
            throw StoreError.failure("This habit needs a newer version of Trend. Its record has been preserved.")
        }
        return HabitEntry(id: id, habitType: type, date: date, value: value,
                          occurrenceCount: occurrenceCount, customHabitID: customHabitID)
    }
}

@Model final class StoredPreference {
    var key: String = ""
    var payload: Data = Data()
    var modifiedAt: Date = Date.now
    var recordID: UUID = UUID()

    init(key: String, payload: Data) { self.key = key; self.payload = payload }
}
