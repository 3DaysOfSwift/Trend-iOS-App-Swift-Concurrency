// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class WaterTrackingViewModel {
    private let habitsFeature: any HabitsFeature

    let habit = HabitTemplate.water.habit
    var errorMessage: String?

    init(
        habitsFeature: any HabitsFeature = AppBrain.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayGlassCount: Int {
        Int(habitsFeature.todaysEntry(for: habit.id)?.value ?? 0)
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.currentWeekSnapshot(for: habit.id)
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
