import Foundation

protocol WeightRepository: Sendable {
    func load() async throws -> WeightStore
    func save(_ store: WeightStore) async throws
}

/// A repository that can expose its durable on-device value before slower remote
/// reconciliation completes. Feature managers use this boundary to make launch
/// independent of network and account availability.
protocol LocallyCachedWeightRepository: WeightRepository {
    func loadCached() async throws -> WeightStore
    func synchronize(_ localStore: WeightStore) async -> WeightStore
}

struct WeightStore: Codable, Sendable {
    var entries: [WeightEntry]
    var goalKilograms: Double?
}
