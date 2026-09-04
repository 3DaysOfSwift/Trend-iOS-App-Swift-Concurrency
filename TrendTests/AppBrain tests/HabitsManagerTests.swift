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
}
