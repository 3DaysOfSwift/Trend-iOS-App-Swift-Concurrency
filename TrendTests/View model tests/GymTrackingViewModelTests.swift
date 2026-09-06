// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct GymTrackingViewModelTests {
    @Test func repetitionsCanBeRecordedAndCleared() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.gymRepetitions.id])
        let viewModel = GymTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordRepetitions(10))
        #expect(viewModel.todayValue == 10)
        await viewModel.clearRepetitions()
        #expect(!viewModel.hasCheckedInToday)
    }
}
