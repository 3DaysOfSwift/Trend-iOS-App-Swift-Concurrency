// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

actor HabitsWorker {
    struct Update: Sendable {
        let habits: [Habit]
        let entries: [HabitEntry]
        let todayEntries: [String: HabitEntry]
        let entriesByDay: [String: [Date: HabitEntry]]
        let weekSummaries: [String: HabitWeekSummary]
        let lifetimeSummaries: [String: HabitLifetimeSummary]
    }

    private let repository: any HabitRepository
    private let calendar: Calendar

    init(repository: any HabitRepository, calendar: Calendar) {
        self.repository = repository
        self.calendar = calendar
    }

    // The manager supplies its current store after the previous operation has completed.
    // The worker keeps no second mutable feature store.
    func load(on today: Date) async throws -> Update {
        let store = try await repository.load()
        return prepare(store, on: today)
    }

    func synchronize() async throws {
        if let cloud = repository as? any HabitCloudSynchronizing {
            try await cloud.synchronize()
        }
    }

    func selectTemplates(_ ids: Set<String>, store: HabitStore, today: Date) async throws -> Update {
        var updated = store
        updated.selectedHabitIDs = HabitTemplate.allCases.filter { ids.contains($0.id) }.map(\.id)
        let saved = try await repository.save(updated, replacing: store)
        return prepare(saved, on: today)
    }

    func recordCoffee(on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = (entry(in: store.entries, for: HabitTemplate.coffee.id, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: HabitTemplate.coffee.id, on: date,
            store: store, today: today)
    }

    func recordGymRepetitions(_ repetitions: Int, on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = (entry(in: store.entries, for: HabitTemplate.gymRepetitions.id, on: date)?.value ?? 0) + Double(repetitions)
        return try await saveEntry(value, for: HabitTemplate.gymRepetitions.id, on: date,
            store: store, today: today)
    }

    func recordRun(kilometres: Double, on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = kilometres
        return try await saveEntry(value, for: HabitTemplate.runningDistance.id, on: date,
            store: store, today: today, occurrence: true)
    }

    func recordSleep(hours: Double, on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = hours
        return try await saveEntry(value, for: HabitTemplate.sleep.id, on: date,
            store: store, today: today)
    }

    func recordWakeTime(minutesAfterMidnight: Int, on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = Double(minutesAfterMidnight)
        return try await saveEntry(value, for: HabitTemplate.wakeTime.id, on: date,
            store: store, today: today)
    }

    func recordGlassOfWater(on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = (entry(in: store.entries, for: HabitTemplate.water.id, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: HabitTemplate.water.id, on: date,
            store: store, today: today)
    }

    func recordAlcoholicDrink(on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry, update: Update) {
        let value = (entry(in: store.entries, for: HabitTemplate.alcohol.id, on: date)?.value ?? 0) + 1
        return try await saveEntry(value, for: HabitTemplate.alcohol.id, on: date,
            store: store, today: today)
    }

    func removeCoffee(on date: Date, store: HabitStore, today: Date) async throws -> (entry: HabitEntry?, update: Update) {
        let id = HabitTemplate.coffee.id
        guard let existing = entry(in: store.entries, for: id, on: date) else {
            return (nil, prepare(store, on: today))
        }
        if existing.value > 1 {
            let result = try await saveEntry(existing.value - 1, for: id, on: date,
                store: store, today: today)
            return (result.entry, result.update)
        }
        var updated = store
        updated.entries.removeAll { $0.id == existing.id }
        let saved = try await repository.save(updated, replacing: store)
        return (nil, prepare(saved, on: today))
    }

    func clearGymRepetitions(on date: Date, store: HabitStore, today: Date) async throws -> Update {
        var updated = store
        updated.entries.removeAll {
            $0.habitID == HabitTemplate.gymRepetitions.id && calendar.isDate($0.date, inSameDayAs: date)
        }
        let saved = try await repository.save(updated, replacing: store)
        return prepare(saved, on: today)
    }

    private func saveEntry(_ value: Double, for id: String, on date: Date,
                           store: HabitStore, today: Date, occurrence: Bool = false) async throws -> (entry: HabitEntry, update: Update) {
        guard store.selectedHabitIDs.contains(id),
              let template = HabitTemplate(rawValue: id),
              template.recordingPolicy.accumulatesOccurrences == occurrence,
              template.recordingPolicy.accepts(value) else {
            throw HabitError.invalidValue
        }
        let existing = entry(in: store.entries, for: id, on: date)
        let recordedEntry = HabitEntry(
            id: UUID(), habitID: id, date: date,
            value: occurrence ? (existing?.value ?? 0) + value : value,
            occurrenceCount: occurrence ? (existing?.occurrenceCount ?? 0) + 1 : existing?.occurrenceCount
        )
        var updated = store
        updated.entries.removeAll { $0.habitID == id && calendar.isDate($0.date, inSameDayAs: date) }
        updated.entries.append(recordedEntry)
        updated.entries.sort { $0.date > $1.date }
        let saved = try await repository.save(updated, replacing: store)
        return (recordedEntry, prepare(saved, on: today))
    }

    private func entry(in entries: [HabitEntry], for id: String, on date: Date) -> HabitEntry? {
        entries.first { $0.habitID == id && calendar.isDate($0.date, inSameDayAs: date) }
    }

    func prepare(_ store: HabitStore, on today: Date) -> Update {
        var entriesByDay: [String: [Date: HabitEntry]] = [:]
        var lifetimeSummaries: [String: HabitLifetimeSummary] = [:]
        let grouped = Dictionary(grouping: store.entries, by: \.habitID)
        var weeks: [String: HabitWeekSummary] = [:]
        for template in HabitTemplate.allCases {
            let entries = grouped[template.id] ?? []
            var days: [Date: HabitEntry] = [:]
            for entry in entries where days[calendar.startOfDay(for: entry.date)] == nil {
                days[calendar.startOfDay(for: entry.date)] = entry
            }
            entriesByDay[template.id] = days
            weeks[template.id] = weekSummary(entriesByDay: days, on: today)
            lifetimeSummaries[template.id] = HabitLifetimeSummary(
                totalValue: entries.reduce(0) { $0 + $1.value },
                firstEntryDate: entries.map(\.date).min()
            )
        }
        return Update(
            habits: HabitTemplate.allCases.filter { store.selectedHabitIDs.contains($0.id) }.map(\.habit),
            entries: store.entries,
            todayEntries: entriesByDay.compactMapValues { $0[calendar.startOfDay(for: today)] },
            entriesByDay: entriesByDay,
            weekSummaries: weeks, lifetimeSummaries: lifetimeSummaries
        )
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
