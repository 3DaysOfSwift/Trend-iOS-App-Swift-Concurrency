// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitCheckInViewModelTests {
    @Test func newWakeTimeStartsAtSevenInTheMorning() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.wakeTime.id])
        let viewModel = HabitCheckInViewModel(
            template: .wakeTime,
            habitsFeature: manager,
            currentDate: { date }
        )

        #expect(Calendar.current.component(.hour, from: viewModel.timeForPicker) == 7)
        #expect(Calendar.current.component(.minute, from: viewModel.timeForPicker) == 0)
    }

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

    @Test func selectedTimeIsStoredAsMinutesAfterMidnight() async throws {
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

        let saved = await viewModel.recordTime(date)

        let expected = Calendar.current.component(.hour, from: date) * 60
            + Calendar.current.component(.minute, from: date)
        #expect(saved)
        #expect(viewModel.todayValue == Double(expected))
        #expect(
            Calendar.current.component(.hour, from: viewModel.timeForPicker)
                == Calendar.current.component(.hour, from: date)
        )
        #expect(
            Calendar.current.component(.minute, from: viewModel.timeForPicker)
                == Calendar.current.component(.minute, from: date)
        )
    }
}
