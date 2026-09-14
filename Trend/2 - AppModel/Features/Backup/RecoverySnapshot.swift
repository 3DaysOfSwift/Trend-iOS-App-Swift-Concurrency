// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

struct RecoverySnapshot: Codable, Sendable {
    var formatVersion = 1
    // The format selects the decoder; the app version/build identify the writer.
    // Optional only because an older backup may not identify its producing app.
    var appVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    var appBuild: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    let revision: String
    let createdAt: Date
    let weight: WeightStore
    let habits: HabitData
    var weightUnit: WeightUnit?

    var hasData: Bool {
        !weight.entries.isEmpty || weight.goalKilograms != nil || !habits.entries.isEmpty
            || !habits.enabledHabits.isEmpty || !habits.customHabits.isEmpty
    }

    func validate() throws {
        guard formatVersion == 1, UUID(uuidString: revision) != nil, createdAt.timeIntervalSince1970.isFinite,
              Set(weight.entries.map(\.id)).count == weight.entries.count,
              Set(habits.entries.map(\.id)).count == habits.entries.count,
              weight.entries.allSatisfy({ $0.kilograms.isFinite && $0.kilograms > 0 && $0.date.timeIntervalSince1970.isFinite }),
              weight.goalKilograms.map({ $0.isFinite && $0 > 0 }) ?? true,
              habits.entries.allSatisfy({ $0.value.isFinite && $0.value >= 0 && $0.date.timeIntervalSince1970.isFinite }) else {
            throw StoreError.failure("This is not a valid Trend recovery backup. Nothing has been changed.")
        }
    }
}
