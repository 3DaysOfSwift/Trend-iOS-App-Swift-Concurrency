// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct AlcoholTrackingViewModelTests {
    @Test func recordingDrinksIncrementsTodaysCount() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.alcohol.id])
        let viewModel = AlcoholTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordDrink())
        #expect(await viewModel.recordDrink())
        #expect(viewModel.todayDrinkCount == 2)
    }
}
