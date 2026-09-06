// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

@MainActor
protocol HabitsFeature: AnyObject {
    var loadState: HabitLoadState { get }
    var habits: [Habit] { get }
    var entries: [HabitEntry] { get }
    var errorMessage: String? { get }

    func refresh() async
    func selectTemplates(_ templateIDs: Set<String>) async throws
    func todaysEntry(for habitID: String) -> HabitEntry?
    func currentWeekSnapshot(for habitID: String) -> HabitWeekSnapshot
    func lifetimeSummary(for habitID: String) -> HabitLifetimeSummary

    func recordCoffeeToday() async throws
    func removeCoffeeToday() async throws
    func recordGymRepetitionsToday(_ repetitions: Int) async throws
    func clearGymRepetitionsToday() async throws
    func recordRunToday(kilometres: Double) async throws
    func recordSleepToday(hours: Double) async throws
    func recordWakeTimeToday(minutesAfterMidnight: Int) async throws
    func recordGlassOfWaterToday() async throws
    func recordAlcoholicDrinkToday() async throws
}
