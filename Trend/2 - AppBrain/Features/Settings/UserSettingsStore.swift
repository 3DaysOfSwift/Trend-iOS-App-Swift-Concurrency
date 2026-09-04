// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Observation

@MainActor
@Observable
final class UserSettingsStore {
    private let cloudSync: any CloudSyncStatusProviding
    private let defaults: UserDefaults

    private(set) var cloudStatus: CloudSyncStatus = .checking
    var unit: WeightUnit {
        didSet { defaults.set(unit.rawValue, forKey: "weightUnit") }
    }

    init(cloudSync: any CloudSyncStatusProviding, defaults: UserDefaults = .standard) {
        self.cloudSync = cloudSync
        self.defaults = defaults
        unit = WeightUnit(rawValue: defaults.string(forKey: "weightUnit") ?? "") ?? .kilograms
    }

    func refreshCloudStatus() async { cloudStatus = await cloudSync.cloudStatus() }
}
