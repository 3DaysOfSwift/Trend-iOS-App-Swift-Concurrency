// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitsManager: HabitsFeature {
    private let repository: any HabitRepository
    private let calendar: Calendar

    private(set) var habits: [Habit] = []
    private(set) var entries: [HabitEntry] = []
    private(set) var errorMessage: String?

    init(repository: any HabitRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func refresh() async {
        do {
            let store = try await repository.load()
            habits = store.habits
            entries = store.entries
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectTemplates(_ templateIDs: Set<String>) async throws {
        let selected = HabitTemplate.allCases
            .filter { templateIDs.contains($0.id) }
            .map(\.habit)
        // Keep history when a habit leaves the active selection. Selecting it
        // again should restore its earlier trend rather than silently erase it.
        try await persist(habits: selected, entries: entries)
    }

    func record(_ value: Double, for habitID: String, on date: Date) async throws {
        guard
            let habit = habits.first(where: { $0.id == habitID }),
            value.isFinite,
            value >= 0,
            isValid(value, for: habit.valueType)
        else {
            throw HabitError.invalidValue
        }
        var updatedEntries = entries.filter {
            !($0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date))
        }
        updatedEntries.append(HabitEntry(id: UUID(), habitID: habitID, date: date, value: value))
        updatedEntries.sort { $0.date > $1.date }
        try await persist(habits: habits, entries: updatedEntries)
    }

    func removeOne(for habitID: String, on date: Date) async throws {
        guard let existingEntry = entry(for: habitID, on: date), existingEntry.value > 0 else { return }

        if existingEntry.value > 1 {
            try await record(existingEntry.value - 1, for: habitID, on: date)
        } else {
            let updatedEntries = entries.filter { $0.id != existingEntry.id }
            try await persist(habits: habits, entries: updatedEntries)
        }
    }

    func entry(for habitID: String, on date: Date) -> HabitEntry? {
        entries.first { $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date) }
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

    func lifetimeSummary(for habitID: String) -> HabitLifetimeSummary {
        let habitEntries = entries.filter { $0.habitID == habitID }
        return HabitLifetimeSummary(
            totalValue: habitEntries.reduce(0) { $0 + $1.value },
            firstEntryDate: habitEntries.map(\.date).min()
        )
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

    private func persist(habits: [Habit], entries: [HabitEntry]) async throws {
        let store = HabitStore(habits: habits, entries: entries)
        try await repository.save(store)
        self.habits = habits
        self.entries = entries
        errorMessage = nil
    }

    private func isValid(_ value: Double, for type: HabitValueType) -> Bool {
        switch type {
        case .number: true
        case .timeOfDay: value < 24 * 60
        case .rating: (1...5).contains(value) && value.rounded() == value
        }
    }
}

enum HabitError: LocalizedError {
    case invalidValue

    var errorDescription: String? { "Enter a valid value before saving." }
}
