// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct WakeTimeTrackingViewModelTests {
    @Test func newWakeTimeStartsAtSevenAndStoresMinutesAfterMidnight() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 6, minute: 30))!
        let manager = HabitsManager(
            repository: InMemoryHabitRepository(),
            calendar: calendar,
            currentDate: { date }
        )
        try await manager.selectTemplates([HabitTemplate.wakeTime.id])
        let viewModel = WakeTimeTrackingViewModel(
            habitsFeature: manager,
            calendar: calendar
        )

        #expect(calendar.component(.hour, from: viewModel.timeForPicker) == 7)
        #expect(await viewModel.recordTime(date))
        #expect(calendar.component(.hour, from: viewModel.timeForPicker) == 6)
        #expect(calendar.component(.minute, from: viewModel.timeForPicker) == 30)
    }
}
