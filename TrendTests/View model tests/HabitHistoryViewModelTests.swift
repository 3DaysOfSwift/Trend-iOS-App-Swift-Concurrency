// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

@MainActor
struct HabitHistoryViewModelTests {
    @Test func formatsNumericHistoryWithItsUnit() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.water.id])
        for _ in 0..<6 { try await manager.recordGlassOfWater(on: .now) }
        let viewModel = HabitHistoryViewModel(habitsFeature: manager)

        #expect(viewModel.valueDescription(for: manager.entries[0]) == "6 glasses")
    }

    @Test func resolvesDeselectedHabitFromItsTemplate() async throws {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        try await manager.selectTemplates([HabitTemplate.coffee.id])
        try await manager.recordCoffee(on: .now)
        try await manager.selectTemplates([])
        let viewModel = HabitHistoryViewModel(habitsFeature: manager)

        #expect(viewModel.habit(for: manager.entries[0])?.name == "Coffee")
    }
}
