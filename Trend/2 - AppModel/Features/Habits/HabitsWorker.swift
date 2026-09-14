// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor HabitsWorker {
    private let storage: any HabitDataStore
    private let calendar: Calendar

    init(storage: any HabitDataStore, calendar: Calendar) {
        self.storage = storage
        self.calendar = calendar
    }

    // The manager supplies its current habits and entries after the previous operation has completed.
    // The worker does not retain a second copy.
    func load(on today: Date) async throws -> HabitData {
        let habitData = try await storage.load()
        return calculateSummaries(habitData, on: today)
    }


    func selectHabits(_ ids: Set<String>, habitData: HabitData, today: Date, customNames: [String] = []) async throws -> HabitData {
        var updated = habitData
        let names = customNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard names.allSatisfy({ !$0.isEmpty && $0.count <= 60 }) else { throw HabitError.invalidHabitName }
        let added = names.map { Habit(customName: $0) }
        updated.customHabits += added
        let catalog = Habit.availableHabits + habitData.customHabits
        updated.enabledHabits = catalog.filter { ids.contains($0.id) } + added
        let saved = try await storage.savePreferences(selected: updated.enabledHabits, custom: updated.customHabits)
        return calculateSummaries(saved, on: today)
    }

    func recordCoffee(on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        let value = (entry(in: habitData.entries, for: .coffee, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: .coffee, on: date,
            habitData: habitData, today: today)
    }

    func recordGymRepetitions(_ repetitions: Int, on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        let value = (entry(in: habitData.entries, for: .gymRepetitions, on: date)?.value ?? 0) + Double(repetitions)
        return try await saveEntry(value, for: .gymRepetitions, on: date,
            habitData: habitData, today: today)
    }

    func recordRun(kilometres: Double, on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        return try await saveEntry(kilometres, for: .runningDistance, on: date,
            habitData: habitData, today: today, occurrence: true)
    }

    func recordSleep(hours: Double, on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        return try await saveEntry(hours, for: .sleep, on: date,
            habitData: habitData, today: today)
    }

    func recordWakeTime(minutesAfterMidnight: Int, on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        return try await saveEntry(Double(minutesAfterMidnight), for: .wakeTime, on: date,
            habitData: habitData, today: today)
    }

    func recordGlassOfWater(on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        let value = (entry(in: habitData.entries, for: .water, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: .water, on: date,
            habitData: habitData, today: today)
    }

    func recordAlcoholicDrink(on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry, habitData: HabitData) {
        let value = (entry(in: habitData.entries, for: .alcohol, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: .alcohol, on: date,
            habitData: habitData, today: today)
    }

    func removeCoffee(on date: Date, habitData: HabitData, today: Date) async throws -> (entry: HabitEntry?, habitData: HabitData) {
        let type = Habit.HabitType.coffee
        guard let existing = entry(in: habitData.entries, for: type, on: date) else {
            return (nil, calculateSummaries(habitData, on: today))
        }
        if existing.value > 1 {
            let result = try await saveEntry(existing.value - 1, for: type, on: date,
                habitData: habitData, today: today)
            return (result.entry, result.habitData)
        }
        var updated = habitData
        updated.entries.removeAll { $0.id == existing.id }
        let saved = try await storage.saveEntries(updated.entries)
        return (nil, calculateSummaries(saved, on: today))
    }

    func clearGymRepetitions(on date: Date, habitData: HabitData, today: Date) async throws -> HabitData {
        var updated = habitData
        updated.entries.removeAll {
            $0.habitType == .gymRepetitions && calendar.isDate($0.date, inSameDayAs: date)
        }
        let saved = try await storage.saveEntries(updated.entries)
        return calculateSummaries(saved, on: today)
    }

    private func saveEntry(_ value: Double, for type: Habit.HabitType, on date: Date,
                           habitData: HabitData, today: Date, occurrence: Bool = false) async throws -> (entry: HabitEntry, habitData: HabitData) {
        let habit = Habit(type: type)
        guard habitData.enabledHabits.contains(where: { $0.type == type }),
              habit.recordingPolicy.accumulatesOccurrences == occurrence,
              habit.recordingPolicy.accepts(value) else {
            throw HabitError.invalidValue
        }
        let existing = entry(in: habitData.entries, for: type, on: date)
        let recordedEntry = HabitEntry(
            id: UUID(), habitType: type, date: date,
            value: occurrence ? (existing?.value ?? 0) + value : value,
            occurrenceCount: occurrence ? (existing?.occurrenceCount ?? 0) + 1 : existing?.occurrenceCount
        )
        var updated = habitData
        updated.entries.removeAll { $0.habitType == type && calendar.isDate($0.date, inSameDayAs: date) }
        updated.entries.append(recordedEntry)
        updated.entries.sort { $0.date > $1.date }
        let saved = try await storage.saveEntries(updated.entries)
        return (recordedEntry, calculateSummaries(saved, on: today))
    }

    // Quick check-ins replace a daily answer, or add a measured occurrence.
    // The manager serializes this complete read-modify-save operation.
    func recordDailyValue(_ value: Double, habitID: String, habitData: HabitData, today: Date) async throws -> HabitData {
        guard let habit = habitData.enabledHabits.first(where: { $0.id == habitID }),
              Habit.availableHabits.contains(where: { $0.id == habitID }) || habit.type == .custom,
              habit.recordingPolicy.accepts(value) else { throw HabitError.invalidValue }
        let existing = habitData.entries.first {
            $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: today)
        }
        let adds = habit.type == .runningDistance
        let total = adds ? (existing?.value ?? 0) + value : value
        guard total.isFinite else { throw HabitError.invalidValue }
        if !habit.recordingPolicy.accumulatesOccurrences, !habit.recordingPolicy.accepts(total) {
            throw HabitError.invalidValue
        }
        let entry = HabitEntry(id: UUID(), habitType: habit.type, date: today, value: total,
            occurrenceCount: habit.type == .runningDistance ? (existing?.occurrenceCount ?? 0) + 1 : nil,
            customHabitID: habit.type == .custom ? habit.id : nil)
        var updated = habitData
        updated.entries.removeAll { $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: today) }
        updated.entries.insert(entry, at: 0)
        return calculateSummaries(try await storage.saveEntries(updated.entries), on: today)
    }

    private func entry(in entries: [HabitEntry], for type: Habit.HabitType, on date: Date) -> HabitEntry? {
        entries.first { $0.habitType == type && calendar.isDate($0.date, inSameDayAs: date) }
    }

    func calculateSummaries(_ habitData: HabitData, on today: Date) -> HabitData {
        var entriesByDay: [String: [Date: HabitEntry]] = [:]
        var lifetimeSummaries: [String: HabitLifetimeSummary] = [:]
        let grouped = Dictionary(grouping: habitData.entries, by: \.habitID)
        var weeks: [String: HabitWeekSummary] = [:]
        for habit in Habit.allHabits.filter({ $0.type != .custom }) + habitData.customHabits {
            let entries = grouped[habit.id] ?? []
            var days: [Date: HabitEntry] = [:]
            for entry in entries where days[calendar.startOfDay(for: entry.date)] == nil {
                days[calendar.startOfDay(for: entry.date)] = entry
            }
            entriesByDay[habit.id] = days
            weeks[habit.id] = weekSummary(entriesByDay: days, on: today)
            lifetimeSummaries[habit.id] = HabitLifetimeSummary(
                totalValue: entries.reduce(0) { $0 + $1.value },
                firstEntryDate: entries.map(\.date).min()
            )
        }
        var calculated = habitData
        calculated.todayEntries = entriesByDay.compactMapValues { $0[calendar.startOfDay(for: today)] }
        calculated.entriesByDay = entriesByDay
        calculated.weekSummaries = weeks
        calculated.lifetimeSummaries = lifetimeSummaries
        calculated.summaryDate = calendar.startOfDay(for: today)
        return calculated
    }

    func weekSummary(entriesByDay: [Date: HabitEntry], on date: Date) -> HabitWeekSummary {
        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today)
        let monday = calendar.date(byAdding: .day, value: -((weekday - 2 + 7) % 7), to: today) ?? today
        let days = (0..<7).compactMap { offset -> HabitWeekSummary.Day? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let entry = entriesByDay[day]
            return HabitWeekSummary.Day(date: day, value: entry?.value ?? 0,
                hasCheckIn: entry != nil, isToday: day == today)
        }
        var day = today
        if entriesByDay[day] == nil {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        while entriesByDay[day] != nil {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return HabitWeekSummary(currentStreak: streak, days: days)
    }
}
