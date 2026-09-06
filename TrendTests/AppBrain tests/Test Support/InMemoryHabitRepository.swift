// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

actor InMemoryHabitRepository: HabitRepository {
    private var store: HabitStore

    init(store: HabitStore = HabitStore(selectedHabitIDs: [], entries: [])) {
        self.store = store
    }

    func load() async throws -> HabitStore { store }
    func save(_ store: HabitStore) async throws { self.store = store }
}
