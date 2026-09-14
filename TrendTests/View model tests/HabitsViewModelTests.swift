// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitsViewModelTests {
    @Test func purchaseReportsOnlyANewUnlockAsNew() async {
        let purchaseManager = PurchaseManager(client: InMemoryPurchaseClient())
        let viewModel = HabitsViewModel(
            habitsFeature: HabitsManager(storage: InMemoryHabitDataStore(), currentDate: TestAppModelFactory.currentDate),
            purchaseFeature: purchaseManager
        )

        #expect(await viewModel.purchaseHabits())
        #expect(!(await viewModel.purchaseHabits()))
    }

    @Test func dashboardReflectsSelectedHabits() async throws {
        let manager = HabitsManager(storage: InMemoryHabitDataStore(), currentDate: TestAppModelFactory.currentDate)
        let habit = Habit(type: .water)
        let viewModel = HabitsViewModel(
            habitsFeature: manager,
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient())
        )
        #expect(viewModel.habits.isEmpty)
        try await manager.enableSelectedHabits([habit.id])
        #expect(viewModel.habits == [habit])
        try await manager.enableSelectedHabits([])
        #expect(viewModel.habits.isEmpty)
    }
}
