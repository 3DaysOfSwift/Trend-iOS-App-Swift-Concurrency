// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class CoffeeTrackingViewModel {
    private let habitsFeature: any HabitsFeature

    let habit = HabitTemplate.coffee.habit
    var errorMessage: String?

    init(
        habitsFeature: any HabitsFeature = AppModel.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayValue: Double {
        habitsFeature.todaysEntry(for: habit.id)?.value ?? 0
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.currentWeekSnapshot(for: habit.id)
    }

    var weeklyTotal: Int { Int(weekSnapshot.totalValue) }

    var lifetimeSummary: HabitLifetimeSummary {
        habitsFeature.lifetimeSummary(for: habit.id)
    }

    func recordCoffee() async -> Bool {
        await perform { try await habitsFeature.recordCoffeeToday() }
    }

    func removeCoffee() async -> Bool {
        await perform { try await habitsFeature.removeCoffeeToday() }
    }

    private func perform(_ operation: () async throws -> Void) async -> Bool {
        do {
            try await operation()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
