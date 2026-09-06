// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct SleepTrackingViewModelTests {
    @Test func recordingSleepPublishesTodaysHours() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.sleep.id])
        let viewModel = SleepTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordSleep(hours: 7.5))
        #expect(viewModel.todayValue == 7.5)
        #expect(viewModel.hasCheckedInToday)
    }
}
