// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitLibraryViewModel {
    private let habitsFeature: any HabitsFeature

    var selection: Set<String>
    var errorMessage: String?
    var isSaving = false

    init(habitsFeature: any HabitsFeature = AppModel.shared.habitsFeature) {
        self.habitsFeature = habitsFeature
        selection = Set(habitsFeature.habits.map(\.id))
    }

    var templates: [HabitTemplate] { HabitTemplate.allCases }

    func toggle(_ template: HabitTemplate) {
        if selection.contains(template.id) {
            selection.remove(template.id)
        } else {
            selection.insert(template.id)
        }
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await habitsFeature.selectTemplates(selection)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
