// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

// Apply only the entries and selections that changed, preserving everything else.
// A changed or deleted local entry wins if both sides edited the same habit/day.
struct HabitDataChanges {
    let calendar: Calendar

    func apply(from previous: HabitData, to updated: HabitData, onto latest: HabitData) -> HabitData {
        let before = entriesByDay(previous.entries)
        let after = entriesByDay(updated.entries)
        var merged = entriesByDay(latest.entries)
        for day in Set(before.keys).union(after.keys) where before[day] != after[day] {
            // Assigning nil removes an entry. Deletions must be merged too.
            merged[day] = after[day]
        }

        var selectedIDs = latest.selectedHabitIDs
        selectedIDs.subtract(previous.selectedHabitIDs.subtracting(updated.selectedHabitIDs))
        selectedIDs.formUnion(updated.selectedHabitIDs.subtracting(previous.selectedHabitIDs))
        return HabitData(
            selectedHabitIDs: selectedIDs,
            entries: merged.values.sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.id.uuidString < $1.id.uuidString
            }
        )
    }

    private struct HabitDay: Hashable {
        let habitType: Habit.HabitType
        let date: Date
    }

    private func entriesByDay(_ entries: [HabitEntry]) -> [HabitDay: HabitEntry] {
        var result: [HabitDay: HabitEntry] = [:]
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let day = HabitDay(habitType: entry.habitType, date: calendar.startOfDay(for: entry.date))
            if result[day] == nil { result[day] = entry }
        }
        return result
    }
}
