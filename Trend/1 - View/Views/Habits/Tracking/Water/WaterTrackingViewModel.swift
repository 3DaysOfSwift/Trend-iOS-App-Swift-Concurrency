// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class WaterTrackingViewModel {
    private let habitsFeature: HabitsManager

    let habit = HabitTemplate.water.habit
    var errorMessage: String?

    init(
        habitsFeature: HabitsManager = AppModel.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayGlassCount: Int {
        Int(habitsFeature.todaysEntry(for: habit.id)?.value ?? 0)
    }

    // Observation dependency: `weekSummaries`
    var weekSummary: HabitWeekSummary {
        habitsFeature.currentWeekSummary(for: habit.id)
    }

    func recordGlass() async -> Bool {
        do {
            try await habitsFeature.recordGlassOfWaterToday()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
