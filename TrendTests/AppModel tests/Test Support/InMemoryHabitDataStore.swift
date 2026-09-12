// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

actor InMemoryHabitDataStore: HabitCloudSynchronizing {
    private var data: HabitData

    init(data: HabitData = HabitData(enabledHabits: [], entries: [])) {
        self.data = data
    }

    func synchronize() async throws {}

    func load() async throws -> HabitData { data }
    func save(_ data: HabitData, replacing previous: HabitData) async throws -> HabitData {
        self.data = data
        return data
    }
}
