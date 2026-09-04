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

    func entry(for habitID: String, on date: Date) -> HabitEntry? {
        entries.first { $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: date) }
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
