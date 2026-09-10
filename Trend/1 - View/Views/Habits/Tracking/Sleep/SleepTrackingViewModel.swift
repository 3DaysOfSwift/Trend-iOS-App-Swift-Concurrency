// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class SleepTrackingViewModel {
    private let habitsFeature: HabitsManager

    let habit = Habit(type: .sleep)
    var errorMessage: String?

    init(
        habitsFeature: HabitsManager = AppModel.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayValue: Double {
        habitsFeature.todaysEntry(for: habit.id)?.value ?? 0
    }

    var hasCheckedInToday: Bool {
        habitsFeature.todaysEntry(for: habit.id) != nil
    }

    // Observation dependency: `weekSummaries`
    var weekSummary: HabitWeekSummary {
        habitsFeature.currentWeekSummary(for: habit.id)
    }

    func recordSleep(hours: Double) async -> Bool {
        do {
            try await habitsFeature.recordSleep(hours: hours)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
