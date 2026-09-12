// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct HabitData: Codable, Equatable, Sendable {
    var enabledHabits: [Habit]
    var entries: [HabitEntry]

    // Calculated after loading or changing entries; not saved to storage.
    var todayEntries: [String: HabitEntry] = [:]
    var entriesByDay: [String: [Date: HabitEntry]] = [:]
    var weekSummaries: [String: HabitWeekSummary] = [:]
    var lifetimeSummaries: [String: HabitLifetimeSummary] = [:]
    var summaryDate: Date?

    init(enabledHabits: [Habit], entries: [HabitEntry]) {
        self.enabledHabits = enabledHabits
        self.entries = entries
    }

    private enum CodingKeys: String, CodingKey {
        case enabledHabitIDs, entries
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let ids = try values.decode([String].self, forKey: .enabledHabitIDs)
        enabledHabits = ids.compactMap { Habit(id: $0) }
        entries = try values.decode([HabitEntry].self, forKey: .entries)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        // Save IDs only; names, symbols and recording rules come from Habit.
        try values.encode(enabledHabits.map(\.id), forKey: .enabledHabitIDs)
        try values.encode(entries, forKey: .entries)
    }
}
