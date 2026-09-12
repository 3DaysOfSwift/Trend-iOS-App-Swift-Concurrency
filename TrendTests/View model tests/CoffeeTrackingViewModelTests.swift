// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct CoffeeTrackingViewModelTests {
    @Test func recordingAndRemovingCoffeeUpdatesToday() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(storage: InMemoryHabitDataStore(), currentDate: { date })
        try await manager.enableSelectedHabits([Habit(type: .coffee).id])
        let viewModel = CoffeeTrackingViewModel(habitsFeature: manager)

        #expect(await viewModel.recordCoffee())
        #expect(await viewModel.recordCoffee())
        #expect(viewModel.todayValue == 2)

        #expect(await viewModel.removeCoffee())
        #expect(viewModel.todayValue == 1)
    }
}
