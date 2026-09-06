// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitsManager: HabitsFeature {
    private let repository: any HabitRepository
    private let calendar: Calendar
    private let currentDate: @MainActor () -> Date

    private(set) var loadState: HabitLoadState = .idle
    private(set) var habits: [Habit] = []
    private(set) var entries: [HabitEntry] = []
    private(set) var errorMessage: String?

    init(
        repository: any HabitRepository,
        calendar: Calendar = .current,
        currentDate: @escaping @MainActor () -> Date = { .now }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func refresh() async {
        loadState = .loading
        do {
            let store = try await repository.load()
            habits = HabitTemplate.allCases
                .filter { store.selectedHabitIDs.contains($0.id) }
                .map(\.habit)
            entries = store.entries
            errorMessage = nil
            loadState = .ready
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectTemplates(_ templateIDs: Set<String>) async throws {
        let selected = HabitTemplate.allCases
            .filter { templateIDs.contains($0.id) }
            .map(\.habit)
        // Keep history when a habit leaves the active selection. Selecting it
        // again should restore its earlier trend rather than silently erase it.
        try await persist(selectedHabitIDs: selected.map(\.id), entries: entries)
    }

    private func record(_ value: Double, for habitID: String, on date: Date) async throws {
        guard
            habits.contains(where: { $0.id == habitID }),
            let template = HabitTemplate(rawValue: habitID),
            !template.recordingPolicy.accumulatesOccurrences,
            template.recordingPolicy.accepts(value)
        else {
            throw HabitError.invalidValue
        }
        let existingEntry = entry(for: habitID, on: date)
        var updatedEntries = entries.filter {
            !($0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date))
        }
        updatedEntries.append(HabitEntry(
            id: UUID(),
            habitID: habitID,
            date: date,
            value: value,
            occurrenceCount: existingEntry?.occurrenceCount
        ))
        updatedEntries.sort { $0.date > $1.date }
        try await persist(selectedHabitIDs: habits.map(\.id), entries: updatedEntries)
    }

    private func recordOccurrence(_ value: Double, for habitID: String, on date: Date) async throws {
        guard
            habits.contains(where: { $0.id == habitID }),
            let template = HabitTemplate(rawValue: habitID),
            template.recordingPolicy.accumulatesOccurrences,
            template.recordingPolicy.accepts(value)
        else {
            throw HabitError.invalidValue
        }

        let existingEntry = entry(for: habitID, on: date)
        var updatedEntries = entries.filter {
            !($0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date))
        }
        updatedEntries.append(HabitEntry(
            id: UUID(),
            habitID: habitID,
            date: date,
            value: (existingEntry?.value ?? 0) + value,
            occurrenceCount: (existingEntry?.occurrenceCount ?? 0) + 1
        ))
        updatedEntries.sort { $0.date > $1.date }
        try await persist(selectedHabitIDs: habits.map(\.id), entries: updatedEntries)
    }

    private func removeOne(for habitID: String, on date: Date) async throws {
        guard HabitTemplate(rawValue: habitID) == .coffee || HabitTemplate(rawValue: habitID) == .water || HabitTemplate(rawValue: habitID) == .alcohol else {
            throw HabitError.unsupportedOperation
        }
        guard let existingEntry = entry(for: habitID, on: date), existingEntry.value > 0 else { return }

        if existingEntry.value > 1 {
            try await record(existingEntry.value - 1, for: habitID, on: date)
        } else {
            let updatedEntries = entries.filter { $0.id != existingEntry.id }
            try await persist(selectedHabitIDs: habits.map(\.id), entries: updatedEntries)
        }
    }

    private func clearEntry(for habitID: String, on date: Date) async throws {
        let updatedEntries = entries.filter {
            !($0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date))
        }
        guard updatedEntries.count != entries.count else { return }
        try await persist(selectedHabitIDs: habits.map(\.id), entries: updatedEntries)
    }

    func entry(for habitID: String, on date: Date) -> HabitEntry? {
        entries.first { $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date) }
    }

    func todaysEntry(for habitID: String) -> HabitEntry? {
        entry(for: habitID, on: currentDate())
    }

    func weekSnapshot(for habitID: String, on date: Date) -> HabitWeekSnapshot {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let startOfToday = mondayCalendar.startOfDay(for: date)
        let weekday = mondayCalendar.component(.weekday, from: startOfToday)
        let daysSinceMonday = (weekday - mondayCalendar.firstWeekday + 7) % 7
        let monday = mondayCalendar.date(byAdding: .day, value: -daysSinceMonday, to: startOfToday) ?? startOfToday

        let days = (0..<7).compactMap { offset -> HabitWeekSnapshot.Day? in
            guard let day = mondayCalendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let entry = entry(for: habitID, on: day)
            return HabitWeekSnapshot.Day(
                date: day,
                value: entry?.value ?? 0,
                hasCheckIn: entry != nil,
                isToday: mondayCalendar.isDate(day, inSameDayAs: startOfToday)
            )
        }
        return HabitWeekSnapshot(
            currentStreak: currentStreak(for: habitID, on: startOfToday),
            days: days
        )
    }

    func currentWeekSnapshot(for habitID: String) -> HabitWeekSnapshot {
        weekSnapshot(for: habitID, on: currentDate())
    }

    func lifetimeSummary(for habitID: String) -> HabitLifetimeSummary {
        let habitEntries = entries.filter { $0.habitID == habitID }
        return HabitLifetimeSummary(
            totalValue: habitEntries.reduce(0) { $0 + $1.value },
            firstEntryDate: habitEntries.map(\.date).min()
        )
    }

    func recordCoffee(on date: Date) async throws {
        try await record((entry(for: HabitTemplate.coffee.id, on: date)?.value ?? 0) + 1, for: HabitTemplate.coffee.id, on: date)
    }

    func removeCoffee(on date: Date) async throws {
        try await removeOne(for: HabitTemplate.coffee.id, on: date)
    }

    func recordGymRepetitions(_ repetitions: Int, on date: Date) async throws {
        let total = (entry(for: HabitTemplate.gymRepetitions.id, on: date)?.value ?? 0) + Double(repetitions)
        try await record(total, for: HabitTemplate.gymRepetitions.id, on: date)
    }

    func clearGymRepetitions(on date: Date) async throws {
        try await clearEntry(for: HabitTemplate.gymRepetitions.id, on: date)
    }

    func recordRun(kilometres: Double, on date: Date) async throws {
        try await recordOccurrence(kilometres, for: HabitTemplate.runningDistance.id, on: date)
    }

    func recordSleep(hours: Double, on date: Date) async throws {
        try await record(hours, for: HabitTemplate.sleep.id, on: date)
    }

    func recordWakeTime(minutesAfterMidnight: Int, on date: Date) async throws {
        try await record(Double(minutesAfterMidnight), for: HabitTemplate.wakeTime.id, on: date)
    }

    func recordGlassOfWater(on date: Date) async throws {
        let total = (entry(for: HabitTemplate.water.id, on: date)?.value ?? 0) + 1
        try await record(total, for: HabitTemplate.water.id, on: date)
    }

    func recordAlcoholicDrink(on date: Date) async throws {
        let total = (entry(for: HabitTemplate.alcohol.id, on: date)?.value ?? 0) + 1
        try await record(total, for: HabitTemplate.alcohol.id, on: date)
    }

    func recordCoffeeToday() async throws {
        try await recordCoffee(on: currentDate())
    }

    func removeCoffeeToday() async throws {
        try await removeCoffee(on: currentDate())
    }

    func recordGymRepetitionsToday(_ repetitions: Int) async throws {
        try await recordGymRepetitions(repetitions, on: currentDate())
    }

    func clearGymRepetitionsToday() async throws {
        try await clearGymRepetitions(on: currentDate())
    }

    func recordRunToday(kilometres: Double) async throws {
        try await recordRun(kilometres: kilometres, on: currentDate())
    }

    func recordSleepToday(hours: Double) async throws {
        try await recordSleep(hours: hours, on: currentDate())
    }

    func recordWakeTimeToday(minutesAfterMidnight: Int) async throws {
        try await recordWakeTime(minutesAfterMidnight: minutesAfterMidnight, on: currentDate())
    }

    func recordGlassOfWaterToday() async throws {
        try await recordGlassOfWater(on: currentDate())
    }

    func recordAlcoholicDrinkToday() async throws {
        try await recordAlcoholicDrink(on: currentDate())
    }

    private func currentStreak(for habitID: String, on date: Date) -> Int {
        var day = calendar.startOfDay(for: date)

        // Today's streak remains alive until the day ends, just as it does for
        // the primary weight check-in streak.
        if entry(for: habitID, on: day) == nil {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }

        var streak = 0
        while entry(for: habitID, on: day) != nil {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    private func persist(selectedHabitIDs: [String], entries: [HabitEntry]) async throws {
        let store = HabitStore(selectedHabitIDs: selectedHabitIDs, entries: entries)
        try await repository.save(store)
        habits = HabitTemplate.allCases
            .filter { selectedHabitIDs.contains($0.id) }
            .map(\.habit)
        self.entries = entries
        loadState = .ready
        errorMessage = nil
    }

}

enum HabitError: LocalizedError {
    case invalidValue
    case unsupportedOperation

    var errorDescription: String? {
        switch self {
        case .invalidValue: "Enter a valid value before saving."
        case .unsupportedOperation: "This tracker does not support that action."
        }
    }
}
