// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitsManager {
    private let worker: HabitsWorker
    private let calendar: Calendar
    private let currentDate: @MainActor () -> Date
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var operationInProgress = false
    @ObservationIgnored private var waitingOperations: [CheckedContinuation<Void, Never>] = []

    private(set) var loadState: HabitLoadState = .idle
    private(set) var habits: [Habit] = []
    private(set) var entries: [HabitEntry] = []
    private(set) var weekSummaries: [String: HabitWeekSummary] = [:]
    private(set) var lifetimeSummaries: [String: HabitLifetimeSummary] = [:]
    private var todayEntries: [String: HabitEntry] = [:]
    @ObservationIgnored private var summaryDate: Date?
    private var entriesByDay: [String: [Date: HabitEntry]] = [:]
    private(set) var errorMessage: String?

    init(repository: any HabitRepository, calendar: Calendar = .current,
         currentDate: @escaping @MainActor () -> Date) {
        worker = HabitsWorker(repository: repository, calendar: calendar)
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func refresh() async {
        // Repeated calls wait for the same refresh, including publication of its result.
        if let refreshTask {
            await refreshTask.value
            return
        }

        let task = Task {
            defer { refreshTask = nil }
            // each operation is in a serial queue
            await waitForPreviousOperation()
            defer { finishOperation() }
            let previousState = loadState
            loadState = .loading
            let today = currentDate()
            do {
                let result = try await worker.load(on: today)
                publish(result, on: today)
            } catch is CancellationError {
                loadState = previousState
            } catch {
                errorMessage = error.localizedDescription
                loadState = .failed(error.localizedDescription)
            }
        }
        // The manager owns this request. Cancelling a caller does not cancel it for everyone.
        refreshTask = task
        await task.value
    }

    @discardableResult
    func selectTemplates(_ templateIDs: Set<String>) async throws -> [Habit] {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.selectTemplates(templateIDs, store: store, today: today)
        publish(result, on: today)
        return result.habits
    }

    // Observation dependency: `entriesByDay`
    func entry(for habitID: String, on date: Date) -> HabitEntry? {
        entriesByDay[habitID]?[calendar.startOfDay(for: date)]
    }

    // Observation dependency: `todayEntries`
    func todaysEntry(for habitID: String) -> HabitEntry? {
        todayEntries[habitID]
    }

    func weekSummary(for habitID: String, on date: Date) async -> HabitWeekSummary {
        await worker.weekSummary(entriesByDay: entriesByDay[habitID] ?? [:], on: date)
    }

    // Observation dependency: `weekSummaries`
    func currentWeekSummary(for habitID: String) -> HabitWeekSummary {
        weekSummaries[habitID] ?? HabitWeekSummary(currentStreak: 0, days: [])
    }

    // Observation dependency: `lifetimeSummaries`
    func lifetimeSummary(for habitID: String) -> HabitLifetimeSummary {
        lifetimeSummaries[habitID] ?? HabitLifetimeSummary(totalValue: 0, firstEntryDate: nil)
    }

    @discardableResult
    func recordCoffee(on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordCoffee(on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordGymRepetitions(_ repetitions: Int, on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordGymRepetitions(repetitions, on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordRun(kilometres: Double, on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordRun(kilometres: kilometres, on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordSleep(hours: Double, on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordSleep(hours: hours, on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordWakeTime(minutesAfterMidnight: Int, on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordWakeTime(minutesAfterMidnight: minutesAfterMidnight, on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordGlassOfWater(on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordGlassOfWater(on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func recordAlcoholicDrink(on date: Date) async throws -> HabitEntry {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.recordAlcoholicDrink(on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    @discardableResult
    func removeCoffee(on date: Date) async throws -> HabitEntry? {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.removeCoffee(on: date, store: store, today: today)
        publish(result.update, on: today)
        return result.entry
    }

    func clearGymRepetitions(on date: Date) async throws {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        let today = currentDate()
        let result = try await worker.clearGymRepetitions(on: date, store: store, today: today)
        publish(result, on: today)
    }

    @discardableResult
    func recordCoffeeToday() async throws -> HabitEntry {
        try await recordCoffee(on: currentDate())
    }

    @discardableResult
    func removeCoffeeToday() async throws -> HabitEntry? {
        try await removeCoffee(on: currentDate())
    }

    @discardableResult
    func recordGymRepetitionsToday(_ repetitions: Int) async throws -> HabitEntry {
        try await recordGymRepetitions(repetitions, on: currentDate())
    }

    func clearGymRepetitionsToday() async throws {
        try await clearGymRepetitions(on: currentDate())
    }

    @discardableResult
    func recordRunToday(kilometres: Double) async throws -> HabitEntry {
        try await recordRun(kilometres: kilometres, on: currentDate())
    }

    @discardableResult
    func recordSleepToday(hours: Double) async throws -> HabitEntry {
        try await recordSleep(hours: hours, on: currentDate())
    }

    @discardableResult
    func recordWakeTimeToday(minutesAfterMidnight: Int) async throws -> HabitEntry {
        try await recordWakeTime(minutesAfterMidnight: minutesAfterMidnight, on: currentDate())
    }

    @discardableResult
    func recordGlassOfWaterToday() async throws -> HabitEntry {
        try await recordGlassOfWater(on: currentDate())
    }

    @discardableResult
    func recordAlcoholicDrinkToday() async throws -> HabitEntry {
        try await recordAlcoholicDrink(on: currentDate())
    }

    // Called on foreground entry and calendar-day changes; no disk reload is needed.
    func updateCurrentDay() async {
        await waitForPreviousOperation()
        defer { finishOperation() }
        guard !Task.isCancelled, summaryDate != nil else { return }
        let date = currentDate()
        guard summaryDate != calendar.startOfDay(for: date) else { return }
        let result = await worker.prepare(
            HabitStore(selectedHabitIDs: habits.map(\.id), entries: entries), on: date)
        todayEntries = result.todayEntries
        weekSummaries = result.weekSummaries
        summaryDate = calendar.startOfDay(for: date)
    }

    private var store: HabitStore {
        HabitStore(selectedHabitIDs: habits.map(\.id), entries: entries)
    }

    private func publish(_ result: HabitsWorker.Update, on date: Date) {
        // Publish the completed operation together, with no suspension between assignments.
        habits = result.habits
        entries = result.entries
        entriesByDay = result.entriesByDay
        todayEntries = result.todayEntries
        summaryDate = calendar.startOfDay(for: date)
        weekSummaries = result.weekSummaries
        lifetimeSummaries = result.lifetimeSummaries
        errorMessage = nil
        loadState = .ready
    }

    private func waitForPreviousOperation() async {
        if operationInProgress {
            await withCheckedContinuation { waitingOperations.append($0) }
        } else {
            operationInProgress = true
        }
    }

    // Hand the turn to the next caller, keeping the flag true until the queue is empty.
    private func finishOperation() {
        if waitingOperations.isEmpty {
            operationInProgress = false
        } else {
            waitingOperations.removeFirst().resume()
        }
    }
}

enum HabitError: LocalizedError {
    case invalidValue
    case unsupportedOperation

    var errorDescription: String? {
        switch self {
        case .invalidValue: "Enter a valid value before saving."
        case .unsupportedOperation: "This tracker does not support that action."
        }
    }
}
