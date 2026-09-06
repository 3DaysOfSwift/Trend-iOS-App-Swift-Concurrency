// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class RunningTrackingViewModel {
    private let habitsFeature: any HabitsFeature

    let habit = HabitTemplate.runningDistance.habit
    var errorMessage: String?

    init(
        habitsFeature: any HabitsFeature = AppBrain.shared.habitsFeature
    ) {
        self.habitsFeature = habitsFeature
    }

    var todayValue: Double {
        habitsFeature.todaysEntry(for: habit.id)?.value ?? 0
    }

    var hasCheckedInToday: Bool {
        habitsFeature.todaysEntry(for: habit.id) != nil
    }

    var todayRunCount: Int {
        habitsFeature.todaysEntry(for: habit.id)?.occurrenceCount ?? 0
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.currentWeekSnapshot(for: habit.id)
    }

    func recordRun(kilometres: Double) async -> Bool {
        do {
            try await habitsFeature.recordRunToday(kilometres: kilometres)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
