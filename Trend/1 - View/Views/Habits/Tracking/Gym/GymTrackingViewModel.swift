// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class GymTrackingViewModel {
    private let habitsFeature: any HabitsFeature

    let habit = HabitTemplate.gymRepetitions.habit
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

    func recordRepetitions(_ repetitions: Int) async -> Bool {
        await perform { try await habitsFeature.recordGymRepetitionsToday(repetitions) }
    }

    func clearRepetitions() async {
        _ = await perform { try await habitsFeature.clearGymRepetitionsToday() }
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
