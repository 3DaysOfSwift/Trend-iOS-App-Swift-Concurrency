// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct WaterTrackingViewModelTests {
    @Test func recordingGlassesIncrementsTodaysCount() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.water.id])
        let viewModel = WaterTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordGlass())
        #expect(await viewModel.recordGlass())
        #expect(viewModel.todayGlassCount == 2)
    }
}
