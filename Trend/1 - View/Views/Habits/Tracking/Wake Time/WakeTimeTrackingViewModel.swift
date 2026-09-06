// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class WakeTimeTrackingViewModel {
    private let habitsFeature: any HabitsFeature
    private let calendar: Calendar

    let habit = HabitTemplate.wakeTime.habit
    var errorMessage: String?

    init(
        habitsFeature: any HabitsFeature = AppBrain.shared.habitsFeature,
        calendar: Calendar = .current
    ) {
        self.habitsFeature = habitsFeature
        self.calendar = calendar
    }

    var hasCheckedInToday: Bool {
        habitsFeature.todaysEntry(for: habit.id) != nil
    }

    var weekSnapshot: HabitWeekSnapshot {
        habitsFeature.currentWeekSnapshot(for: habit.id)
    }

    var timeForPicker: Date {
        guard let entry = habitsFeature.todaysEntry(for: habit.id) else {
            let today = Date.now
            let suggestedMinutes = Int(HabitTemplate.wakeTime.recordingPolicy.defaultValue)
            return calendar.date(
                bySettingHour: suggestedMinutes / 60,
                minute: suggestedMinutes % 60,
                second: 0,
                of: today
            ) ?? today
        }
        let minutesAfterMidnight = Int(entry.value)
        return calendar.date(
            bySettingHour: minutesAfterMidnight / 60,
            minute: minutesAfterMidnight % 60,
            second: 0,
            of: entry.date
        ) ?? entry.date
    }

    func recordTime(_ time: Date) async -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        do {
            try await habitsFeature.recordWakeTimeToday(
                minutesAfterMidnight: (components.hour ?? 0) * 60 + (components.minute ?? 0)
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() { errorMessage = nil }
}
