// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class SleepTrackingViewModel {
    private let habitsFeature: any HabitsFeature

    let habit = HabitTemplate.sleep.habit
    var errorMessage: String?

    init(
        habitsFeature: any HabitsFeature = AppModel.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayValue: Double {
        habitsFeature.todaysEntry(for: habit.id)?.value ?? 0
    }

    var hasCheckedInToday: Bool {
        habitsFeature.todaysEntry(for: habit.id) != nil
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.currentWeekSnapshot(for: habit.id)
    }

    func recordSleep(hours: Double) async -> Bool {
        do {
            try await habitsFeature.recordSleepToday(hours: hours)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
