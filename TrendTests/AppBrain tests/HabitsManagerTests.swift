// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitsManagerTests {
    @Test func selectionUsesTemplatesAsTheActiveHabitList() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())

        try await manager.selectTemplates([HabitTemplate.coffee.id, HabitTemplate.mood.id])

        #expect(manager.habits.map(\.id) == [HabitTemplate.coffee.id, HabitTemplate.mood.id])
    }

    @Test func secondCheckInOnTheSameDayReplacesTheFirst() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])

        try await manager.record(3, for: HabitTemplate.coffee.id, on: date)
        try await manager.record(2, for: HabitTemplate.coffee.id, on: date.addingTimeInterval(60))

        #expect(manager.entries.count == 1)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date)?.value == 2)
    }

    @Test func removingAndReselectingAHabitPreservesItsHistory() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.water.id])
        try await manager.record(6, for: HabitTemplate.water.id, on: date)

        try await manager.selectTemplates([])
        try await manager.selectTemplates([HabitTemplate.water.id])

        #expect(manager.entry(for: HabitTemplate.water.id, on: date)?.value == 6)
    }

    @Test func ratingRejectsValuesOutsideItsFivePointScale() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.mood.id])

        await #expect(throws: HabitError.self) {
            try await manager.record(6, for: HabitTemplate.mood.id, on: .now)
        }
    }

    @Test func removingOneDecrementsThenRemovesTheDailyEntry() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.record(2, for: HabitTemplate.coffee.id, on: date)

        try await manager.removeOne(for: HabitTemplate.coffee.id, on: date)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date)?.value == 1)

        try await manager.removeOne(for: HabitTemplate.coffee.id, on: date)
        #expect(manager.entry(for: HabitTemplate.coffee.id, on: date) == nil)
    }

    @Test func lifetimeSummaryTotalsEntriesAndKeepsTheFirstDate() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let firstDate = Date(timeIntervalSince1970: 1_788_480_000)
        let secondDate = firstDate.addingTimeInterval(86_400)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.record(2, for: HabitTemplate.coffee.id, on: firstDate)
        try await manager.record(3, for: HabitTemplate.coffee.id, on: secondDate)

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
        try await manager.record(1, for: HabitTemplate.coffee.id, on: friday)

        let snapshot = manager.weekSnapshot(for: HabitTemplate.coffee.id, on: friday)

        #expect(snapshot.days.count == 7)
        #expect(calendar.component(.weekday, from: snapshot.days[0].date) == 2)
        #expect(snapshot.days[4].isToday)
        #expect(snapshot.days[4].hasCheckIn)
        #expect(snapshot.totalValue == 1)
        #expect(snapshot.currentStreak == 1)
    }
}
