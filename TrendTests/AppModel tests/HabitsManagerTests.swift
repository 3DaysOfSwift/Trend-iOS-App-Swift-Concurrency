// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitsManagerTests {
    @Test func selectionUsesTemplatesAsTheActiveHabitList() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())

        try await manager.selectTemplates([HabitTemplate.coffee.id, HabitTemplate.water.id])

        #expect(manager.habits.map(\.id) == [HabitTemplate.coffee.id, HabitTemplate.water.id])
    }

    @Test func twoCoffeesOnTheSameDayAccumulate() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])

        try await manager.recordCoffee(on: date)
        try await manager.recordCoffee(on: date)

        #expect(manager.entries.count == 1)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date)?.value == 2)
    }

    @Test func removingAndReselectingAHabitPreservesItsHistory() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.water.id])
        for _ in 0..<6 { try await manager.recordGlassOfWater(on: date) }

        try await manager.selectTemplates([])
        try await manager.selectTemplates([HabitTemplate.water.id])

        #expect(manager.entry(for: HabitTemplate.water.id, on: date)?.value == 6)
    }

    @Test func separateRunsAccumulateDistanceAndOccurrenceCount() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.runningDistance.id])

        try await manager.recordRun(kilometres: 3, on: date)
        try await manager.recordRun(kilometres: 2, on: date)

        let entry = manager.entry(for: HabitTemplate.runningDistance.id, on: date)
        #expect(entry?.value == 5)
        #expect(entry?.occurrenceCount == 2)
    }

    @Test func clearingTodayRemovesTheHabitEntry() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.gymRepetitions.id])
        try await manager.recordGymRepetitions(20, on: date)

        try await manager.clearGymRepetitions(on: date)

        #expect(manager.entry(for: HabitTemplate.gymRepetitions.id, on: date) == nil)
    }

    @Test func distanceUnitsConvertToAndFromCanonicalKilometres() {
        let kilometres = RunningDistanceUnit.miles.kilometres(from: 1)

        #expect(abs(kilometres - 1.609_344) < 0.000_001)
        #expect(abs(RunningDistanceUnit.miles.value(fromKilometres: kilometres) - 1) < 0.000_001)
    }

    @Test func removingOneDecrementsThenRemovesTheDailyEntry() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.recordCoffee(on: date)
        try await manager.recordCoffee(on: date)

        try await manager.removeCoffee(on: date)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date)?.value == 1)

        try await manager.removeCoffee(on: date)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date) == nil)
    }

    @Test func lifetimeSummaryTotalsEntriesAndKeepsTheFirstDate() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let firstDate = Date(timeIntervalSince1970: 1_788_480_000)
        let secondDate = firstDate.addingTimeInterval(86_400)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        for _ in 0..<2 { try await manager.recordCoffee(on: firstDate) }
        for _ in 0..<3 { try await manager.recordCoffee(on: secondDate) }

        let summary = manager.lifetimeSummary(for: HabitTemplate.coffee.id)

        #expect(summary.totalValue == 5)
        #expect(summary.firstEntryDate == firstDate)
    }

    @Test func weeklySnapshotAlwaysRunsFromMondayToSunday() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let friday = calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 12))!
        let manager = HabitsManager(repository: InMemoryHabitRepository(), calendar: calendar)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.recordCoffee(on: friday)

        let snapshot = manager.weekSnapshot(for: HabitTemplate.coffee.id, on: friday)

        #expect(snapshot.days.count == 7)
        #expect(calendar.component(.weekday, from: snapshot.days[0].date) == 2)
        #expect(snapshot.days[4].isToday)
        #expect(snapshot.days[4].hasCheckIn)
        #expect(snapshot.totalValue == 1)
        #expect(snapshot.currentStreak == 1)
    }

    @Test func appModelRejectsValuesOutsideEachHabitPolicy() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.sleep.id, HabitTemplate.wakeTime.id])

        await #expect(throws: HabitError.self) {
            try await manager.recordSleep(hours: 25, on: date)
        }
        await #expect(throws: HabitError.self) {
            try await manager.recordWakeTime(minutesAfterMidnight: 1_440, on: date)
        }
    }

    @Test func namedCoffeeCommandsKeepTheStoredCountConsistent() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])

        try await manager.recordCoffee(on: date)
        try await manager.recordCoffee(on: date)
        try await manager.removeCoffee(on: date)

        let entry = manager.entry(for: HabitTemplate.coffee.id, on: date)
        #expect(entry?.value == 1)
        #expect(entry?.occurrenceCount == nil)
    }
}
