// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitsViewModelTests {
    @Test func purchaseReportsOnlyANewUnlockAsNew() async {
        let purchaseManager = PurchaseManager(client: InMemoryPurchaseClient())
        let viewModel = HabitsViewModel(
            habitsFeature: HabitsManager(dataStore: InMemoryHabitDataStore(), currentDate: TestAppModelFactory.currentDate),
            purchaseFeature: purchaseManager
        )

        #expect(await viewModel.purchaseHabits())
        #expect(!(await viewModel.purchaseHabits()))
    }

    @Test func dashboardExposesTodaysRecordedSummary() async throws {
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let manager = HabitsManager(dataStore: InMemoryHabitDataStore(), currentDate: { date })
        try await manager.selectHabits([Habit(type: .coffee).id])
        try await manager.recordCoffee(on: date)
        try await manager.recordCoffee(on: date)
        let viewModel = HabitsViewModel(
            habitsFeature: manager,
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient())
        )

        #expect(viewModel.hasCheckedIn(Habit(type: .coffee)))
        #expect(viewModel.todaySummary(for: Habit(type: .coffee)) == "Today · 2 cups")
    }

    @Test func dashboardShowsAReadyStateBeforeCheckIn() async throws {
        let manager = HabitsManager(dataStore: InMemoryHabitDataStore(), currentDate: TestAppModelFactory.currentDate)
        try await manager.selectHabits([Habit(type: .coffee).id])
        let viewModel = HabitsViewModel(
            habitsFeature: manager,
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient())
        )

        #expect(!viewModel.hasCheckedIn(Habit(type: .coffee)))
        #expect(viewModel.todaySummary(for: Habit(type: .coffee)) == "Ready to check in")
    }
}
