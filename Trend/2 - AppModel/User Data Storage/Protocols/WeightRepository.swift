// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

protocol WeightRepository: Sendable {
    func load() async throws -> WeightStore
    func save(_ store: WeightStore) async throws
}

struct WeightStore: Codable, Sendable {
    var entries: [WeightEntry]
    var goalKilograms: Double?
}
