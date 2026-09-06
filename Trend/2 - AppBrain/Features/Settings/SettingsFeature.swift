// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

@MainActor
protocol SettingsFeature: AnyObject {
    var selectedWeightUnit: WeightUnit { get }
    var cloudSyncStatus: CloudSyncStatus { get }
    var goalWeightKilograms: Double? { get }

    func setWeightUnit(_ unit: WeightUnit)
    func refreshCloudStatus() async
    func canSetGoal(from text: String) -> Bool
    func setGoal(from text: String) async throws
    func exportData() async throws -> Data
    func importData(from url: URL) async throws
    func deleteAllData() async throws
}
