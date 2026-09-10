// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class GymTrackingViewModel {
    private let habitsFeature: HabitsManager

    let habit = Habit(type: .gymRepetitions)
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

    func recordRepetitions(_ repetitions: Int) async -> Bool {
        await perform { try await habitsFeature.recordGymRepetitions(repetitions) }
    }

    func clearRepetitions() async {
        _ = await perform { try await habitsFeature.clearGymRepetitions() }
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
