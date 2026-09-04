// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitHistoryViewModelTests {
    @Test func formatsNumericHistoryWithItsUnit() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.water.id])
        try await manager.record(6, for: HabitTemplate.water.id, on: .now)
        let viewModel = HabitHistoryViewModel(habitsFeature: manager)

        #expect(viewModel.valueDescription(for: manager.entries[0]) == "6 glasses")
    }

    @Test func resolvesDeselectedHabitFromItsTemplate() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.record(1, for: HabitTemplate.coffee.id, on: .now)
        try await manager.selectTemplates([])
        let viewModel = HabitHistoryViewModel(habitsFeature: manager)

        #expect(viewModel.habit(for: manager.entries[0])?.name == "Coffee")
    }
}
