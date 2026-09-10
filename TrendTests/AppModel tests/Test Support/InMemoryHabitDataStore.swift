// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

actor InMemoryHabitDataStore: HabitDataStore {
    private var data: HabitData

    init(data: HabitData = HabitData(selectedHabitIDs: [], entries: [])) {
        self.data = data
    }

    func load() async throws -> HabitData { data }
    func save(_ data: HabitData, replacing previous: HabitData) async throws -> HabitData {
        self.data = data
        return data
    }
}
