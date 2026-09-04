// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Testing
@testable import Trend

@MainActor
struct HabitLibraryViewModelTests {
    @Test func toggleAddsAndRemovesASelection() {
        let viewModel = HabitLibraryViewModel(
            habitsFeature: HabitsManager(repository: InMemoryHabitRepository())
        )

        viewModel.toggle(.coffee)
        #expect(viewModel.selection == [HabitTemplate.coffee.id])
        viewModel.toggle(.coffee)
        #expect(viewModel.selection.isEmpty)
    }

    @Test func savePublishesTheSelectedTemplates() async {
        let manager = HabitsManager(repository: InMemoryHabitRepository())
        let viewModel = HabitLibraryViewModel(habitsFeature: manager)
        viewModel.selection = [HabitTemplate.sleep.id, HabitTemplate.water.id]

        let succeeded = await viewModel.save()

        #expect(succeeded)
        #expect(manager.habits.map(\.id) == [HabitTemplate.sleep.id, HabitTemplate.water.id])
    }
}
