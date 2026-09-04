// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class HabitCheckInViewModel {
    private let habitsFeature: any HabitsFeature
    private let currentDate: () -> Date

    let habit: Habit
    var errorMessage: String?

    init(
        template: HabitTemplate,
        habitsFeature: any HabitsFeature = AppBrain.shared.habitsFeature,
        currentDate: @escaping () -> Date = { .now }
    ) {
        habit = template.habit
        self.habitsFeature = habitsFeature
        self.currentDate = currentDate
    }

    var todayValue: Double {
        habitsFeature.entry(for: habit.id, on: currentDate())?.value ?? 0
    }

    var hasCheckedInToday: Bool {
        habitsFeature.entry(for: habit.id, on: currentDate()) != nil
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.weekSnapshot(for: habit.id, on: currentDate())
    }

    var weeklyTotal: Int {
        Int(weekSnapshot.totalValue)
    }

    var lifetimeSummary: HabitLifetimeSummary {
        habitsFeature.lifetimeSummary(for: habit.id)
    }

    func increment(by amount: Double = 1) async {
        await record(todayValue + amount)
    }

    func removeOne() async {
        do {
            try await habitsFeature.removeOne(for: habit.id, on: currentDate())
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func record(_ value: Double) async {
        do {
            try await habitsFeature.record(value, for: habit.id, on: currentDate())
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordCurrentTime() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: currentDate())
        await record(Double((components.hour ?? 0) * 60 + (components.minute ?? 0)))
    }

    func dismissError() { errorMessage = nil }
}

extension View {
    func habitErrorAlert(_ viewModel: HabitCheckInViewModel) -> some View {
        alert("Couldn’t record check-in", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
