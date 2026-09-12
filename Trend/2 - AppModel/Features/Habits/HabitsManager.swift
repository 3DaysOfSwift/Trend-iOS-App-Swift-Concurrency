// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class HabitsManager {
    private let worker: HabitsWorker
    private let calendar: Calendar
    private let currentDate: @MainActor () -> Date
    @ObservationIgnored private var synchronizationTask: Task<Void, Never>?
    @ObservationIgnored private var synchronizationRequested = false
    @ObservationIgnored private var loadingTask: Task<Void, Never>?
    @ObservationIgnored private var operationInProgress = false
    @ObservationIgnored private var waitingOperations: [CheckedContinuation<Void, Never>] = []

    enum HabitLoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }
    private(set) var loadState: HabitLoadState = .idle
    
    // the habit data loaded into memory - in memory cache
    private var habitData = HabitData(enabledHabits: [], entries: [])

    // Observation dependency: `habitData`
    var enabledHabits: [Habit] { habitData.enabledHabits }
    
    // Observation dependency: `habitData`
    var entries: [HabitEntry] { habitData.entries }

    // Observation dependency: `habitData`
    var weekSummaries: [String: HabitWeekSummary] { habitData.weekSummaries }
    // Observation dependency: `habitData`
    var lifetimeSummaries: [String: HabitLifetimeSummary] { habitData.lifetimeSummaries }

    private(set) var errorMessage: String?
    private(set) var synchronizationError: String?

    init(storage: any HabitCloudSynchronizing, calendar: Calendar = .current,
         currentDate: @escaping @MainActor () -> Date) {
        worker = HabitsWorker(storage: storage, calendar: calendar)
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func load() async {
        // Read saved habits once. Repeated callers share the load; a failed load can be retried.
        if let loadingTask {
            await loadingTask.value
            return
        }

        guard loadState != .ready else { return }
        let task = Task {
            defer { loadingTask = nil }
            await loadLocalData()
        }
        // The manager owns this request. Cancelling a caller does not cancel it for everyone.
        loadingTask = task
        await task.value
    }

    private func loadLocalData() async {
        await waitForPreviousOperation()
        defer { finishOperation() }
        let previousState = loadState
        if loadState != .ready { loadState = .loading }
        do {
            let today = currentDate()
            let result = try await worker.load(on: today)
            publishSuccessfulResult(result)
        } catch is CancellationError {
            loadState = previousState
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
        }
    }
    
    func synchronize() async {
        await load()
        guard loadState == .ready else { return }
        if let synchronizationTask {
            await synchronizationTask.value
            return
        }
        await requestCloudSynchronization().value
    }

    @discardableResult
    private func requestCloudSynchronization() -> Task<Void, Never> {
        synchronizationRequested = true
        if let synchronizationTask { return synchronizationTask }
        let task = Task {
            defer { synchronizationTask = nil }
            repeat {
                synchronizationRequested = false
                do {
                    // Do not hold the local queue while waiting for iCloud.
                    try await worker.synchronize()
                    synchronizationError = nil
                    await loadLocalData()
                } catch {
                    // Local saves still succeeded. The next synchronization or edit retries iCloud.
                    synchronizationError = error.localizedDescription
                    return
                }
            } while synchronizationRequested
        }
        synchronizationTask = task
        return task
    }

    // Observation dependency: `habitData`
    func entry(for habitID: String, on date: Date) -> HabitEntry? {
        habitData.entriesByDay[habitID]?[calendar.startOfDay(for: date)]
    }

    // Observation dependency: `habitData`
    func todaysEntry(for habitID: String) -> HabitEntry? {
        habitData.todayEntries[habitID]
    }

    func weekSummary(for habitID: String, on date: Date) async -> HabitWeekSummary {
        await worker.weekSummary(entriesByDay: habitData.entriesByDay[habitID] ?? [:], on: date)
    }

    // Observation dependency: `habitData`
    func currentWeekSummary(for habitID: String) -> HabitWeekSummary {
        weekSummaries[habitID] ?? HabitWeekSummary(currentStreak: 0, days: [])
    }

    // Observation dependency: `habitData`
    func lifetimeSummary(for habitID: String) -> HabitLifetimeSummary {
        lifetimeSummaries[habitID] ?? HabitLifetimeSummary(totalValue: 0, firstEntryDate: nil)
    }

    // Called on foreground entry and calendar-day changes; no disk reload is needed.
    func updateCurrentDay() async {
        await waitForPreviousOperation()
        defer { finishOperation() }
        guard !Task.isCancelled, habitData.summaryDate != nil else { return }
        
        let today = currentDate()
        guard habitData.summaryDate != calendar.startOfDay(for: today) else { return }
        habitData = await worker.calculateSummaries(habitData, on: today)
    }

    private func publishSuccessfulResult(_ result: HabitData) {
        habitData = result
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

// MARK: - Habit updates

extension HabitsManager {
    @discardableResult
    func enableSelectedHabits(_ habitIDs: Set<String>) async throws -> [Habit] {
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.selectHabits(habitIDs, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result)
        requestCloudSynchronization()
        return enabledHabits
    }

    @discardableResult
    func recordCoffee(on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordCoffee(on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordGymRepetitions(_ repetitions: Int, on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordGymRepetitions(repetitions, on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordRun(kilometres: Double, on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordRun(kilometres: kilometres, on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordSleep(hours: Double, on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordSleep(hours: hours, on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordWakeTime(minutesAfterMidnight: Int, on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordWakeTime(minutesAfterMidnight: minutesAfterMidnight, on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordGlassOfWater(on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordGlassOfWater(on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func recordAlcoholicDrink(on date: Date? = nil) async throws -> HabitEntry {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.recordAlcoholicDrink(on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    @discardableResult
    func removeCoffee(on date: Date? = nil) async throws -> HabitEntry? {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.removeCoffee(on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result.habitData)
        requestCloudSynchronization()
        return result.entry
    }

    func clearGymRepetitions(on date: Date? = nil) async throws {
        let date = date ?? currentDate()
        await waitForPreviousOperation()
        defer { finishOperation() }
        try Task.checkCancellation()
        
        let result = try await worker.clearGymRepetitions(on: date, habitData: habitData, today: currentDate())
        publishSuccessfulResult(result)
        requestCloudSynchronization()
    }
}

enum HabitError: LocalizedError {
    case invalidValue

    var errorDescription: String? {
        switch self {
        case .invalidValue: "Enter a valid value before saving."
        }
    }
}
