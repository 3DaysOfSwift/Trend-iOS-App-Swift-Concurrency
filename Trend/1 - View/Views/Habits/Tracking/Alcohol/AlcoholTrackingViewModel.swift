// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class AlcoholTrackingViewModel {
    private let habitsFeature: HabitsManager

    let habit = HabitTemplate.alcohol.habit
    var errorMessage: String?

    init(
        habitsFeature: HabitsManager = AppModel.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayDrinkCount: Int {
        Int(habitsFeature.todaysEntry(for: habit.id)?.value ?? 0)
    }

    // Observation dependency: `weekSummaries`
    var weekSummary: HabitWeekSummary {
        habitsFeature.currentWeekSummary(for: habit.id)
    }

    func recordDrink() async -> Bool {
        do {
            try await habitsFeature.recordAlcoholicDrinkToday()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
