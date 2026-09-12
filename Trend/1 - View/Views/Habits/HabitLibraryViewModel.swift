// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitLibraryViewModel {
    private let habitsFeature: HabitsManager

    var selection: Set<String>
    var errorMessage: String?
    var isSaving = false

    init(habitsFeature: HabitsManager = AppModel.shared.habitsFeature) {
        self.habitsFeature = habitsFeature
        selection = Set(habitsFeature.enabledHabits.map(\.id))
    }

    var habits: [Habit] = Habit.allHabits

    func toggle(_ habit: Habit) {
        if selection.contains(habit.id) {
            selection.remove(habit.id)
        } else {
            selection.insert(habit.id)
        }
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await habitsFeature.enableSelectedHabits(selection)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
