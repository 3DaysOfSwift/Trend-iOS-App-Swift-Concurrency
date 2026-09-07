// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitHistoryViewModel {
    private let habitsFeature: any HabitsFeature

    init(habitsFeature: any HabitsFeature = AppModel.shared.habitsFeature) {
        self.habitsFeature = habitsFeature
    }

    var entries: [HabitEntry] { habitsFeature.entries }

    func habit(for entry: HabitEntry) -> Habit? {
        HabitTemplate(rawValue: entry.habitID)?.habit
    }

    func valueDescription(for entry: HabitEntry) -> String {
        guard let habit = habit(for: entry) else { return entry.value.formatted() }
        switch habit.valueType {
        case .timeOfDay:
            let hour = Int(entry.value) / 60
            let minute = Int(entry.value) % 60
            let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: entry.date) ?? entry.date
            return date.formatted(date: .omitted, time: .shortened)
        case .rating:
            return "\(Int(entry.value)) of 5"
        case .number:
            let value = entry.value.formatted(.number.precision(.fractionLength(0...1)))
            return "\(value) \(habit.unit)"
        }
    }
}
