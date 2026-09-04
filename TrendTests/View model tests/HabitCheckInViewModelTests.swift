// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitCheckInViewModelTests {
    @Test func incrementAddsToTodaysExistingValue() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        let viewModel = HabitCheckInViewModel(
            template: .coffee,
            habitsFeature: manager,
            currentDate: { date }
        )

        await viewModel.increment()
        await viewModel.increment()

        #expect(viewModel.todayValue == 2)
        #expect(viewModel.hasCheckedInToday)
    }

    @Test func removingTheLastCoffeeRemovesTodaysCheckIn() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        let viewModel = HabitCheckInViewModel(
            template: .coffee,
            habitsFeature: manager,
            currentDate: { date }
        )

        await viewModel.increment()
        await viewModel.removeOne()

        #expect(viewModel.todayValue == 0)
        #expect(!viewModel.hasCheckedInToday)
    }

    @Test func currentTimeIsStoredAsMinutesAfterMidnight() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 6, minute: 30))!
        try await manager.selectTemplates([HabitTemplate.wakeTime.id])
        let viewModel = HabitCheckInViewModel(
            template: .wakeTime,
            habitsFeature: manager,
            currentDate: { date }
        )

        await viewModel.recordCurrentTime()

        let expected = Calendar.current.component(.hour, from: date) * 60
            + Calendar.current.component(.minute, from: date)
        #expect(viewModel.todayValue == Double(expected))
    }
}
