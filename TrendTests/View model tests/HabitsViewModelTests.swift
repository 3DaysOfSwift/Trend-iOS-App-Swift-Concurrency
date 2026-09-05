// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitsViewModelTests {
    @Test func purchaseReportsOnlyANewUnlockAsNew() async {
        let purchaseManager = PurchaseManager(client: InMemoryPurchaseClient())
        let viewModel = HabitsViewModel(
            habitsFeature: HabitsManager(repository: InMemoryHabitRepository()),
            purchaseFeature: purchaseManager
        )

        #expect(await viewModel.purchaseHabits())
        #expect(!(await viewModel.purchaseHabits()))
    }

    @Test func dashboardExposesTodaysRecordedSummary() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.record(2, for: HabitTemplate.coffee.id, on: date)
        let viewModel = HabitsViewModel(
            habitsFeature: manager,
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient()),
            currentDate: { date }
        )

        #expect(viewModel.hasCheckedIn(HabitTemplate.coffee.habit))
        #expect(viewModel.todaySummary(for: HabitTemplate.coffee.habit) == "Today · 2 cups")
    }

    @Test func dashboardShowsAReadyStateBeforeCheckIn() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        let viewModel = HabitsViewModel(
            habitsFeature: manager,
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient())
        )

        #expect(!viewModel.hasCheckedIn(HabitTemplate.coffee.habit))
        #expect(viewModel.todaySummary(for: HabitTemplate.coffee.habit) == "Ready to check in")
    }
}
