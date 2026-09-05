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

    var todayOccurrenceCount: Int {
        guard let entry = habitsFeature.entry(for: habit.id, on: currentDate()) else { return 0 }
        return entry.occurrenceCount ?? 1
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

    func recordOccurrence(_ value: Double) async -> Bool {
        do {
            try await habitsFeature.recordOccurrence(value, for: habit.id, on: currentDate())
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearToday() async {
        do {
            try await habitsFeature.clearEntry(for: habit.id, on: currentDate())
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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

    var timeForPicker: Date {
        guard hasCheckedInToday else {
            return Calendar.current.date(
                bySettingHour: 7,
                minute: 0,
                second: 0,
                of: currentDate()
            ) ?? currentDate()
        }
        let hour = Int(todayValue) / 60
        let minute = Int(todayValue) % 60
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: currentDate()
        ) ?? currentDate()
    }

    func recordTime(_ time: Date) async -> Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        await record(Double((components.hour ?? 0) * 60 + (components.minute ?? 0)))
        return errorMessage == nil
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
