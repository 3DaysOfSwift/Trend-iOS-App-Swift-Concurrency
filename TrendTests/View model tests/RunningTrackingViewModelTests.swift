// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct RunningTrackingViewModelTests {
    @Test func multipleRunsPreserveTodaysDistanceAndRunCount() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(repository: InMemoryHabitRepository(), currentDate: { date })
        try await manager.selectTemplates([HabitTemplate.runningDistance.id])
        let viewModel = RunningTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordRun(kilometres: 5))
        #expect(await viewModel.recordRun(kilometres: 2.5))
        #expect(viewModel.todayValue == 7.5)
        #expect(viewModel.todayRunCount == 2)
    }
}
