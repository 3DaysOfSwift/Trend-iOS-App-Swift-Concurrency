// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

// Apply only the entries and selections that changed, preserving everything else.
// A changed or deleted local entry wins if both sides edited the same habit/day.
struct HabitStoreChanges {
    let calendar: Calendar

    func apply(from previous: HabitStore, to updated: HabitStore, onto latest: HabitStore) -> HabitStore {
        let before = entriesByDay(previous.entries)
        let after = entriesByDay(updated.entries)
        var merged = entriesByDay(latest.entries)
        for day in Set(before.keys).union(after.keys) where before[day] != after[day] {
            // Assigning nil removes an entry. Deletions must be merged too.
            merged[day] = after[day]
        }

        let previousIDs = Set(previous.selectedHabitIDs)
        let updatedIDs = Set(updated.selectedHabitIDs)
        var selectedIDs = Set(latest.selectedHabitIDs)
        selectedIDs.subtract(previousIDs.subtracting(updatedIDs))
        selectedIDs.formUnion(updatedIDs.subtracting(previousIDs))
        return HabitStore(
            selectedHabitIDs: selectedIDs.sorted(),
            entries: merged.values.sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.id.uuidString < $1.id.uuidString
            }
        )
    }

    private struct HabitDay: Hashable {
        let habitID: String
        let date: Date
    }

    private func entriesByDay(_ entries: [HabitEntry]) -> [HabitDay: HabitEntry] {
        var result: [HabitDay: HabitEntry] = [:]
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let day = HabitDay(habitID: entry.habitID, date: calendar.startOfDay(for: entry.date))
            if result[day] == nil { result[day] = entry }
        }
        return result
    }
}
