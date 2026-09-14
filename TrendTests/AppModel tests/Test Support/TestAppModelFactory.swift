// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

@MainActor
enum TestAppModelFactory {
    static let currentDate: @MainActor () -> Date = { .now }

    static func make(
        repository: any WeightRepository & CloudSyncStatusProviding = InMemoryWeightRepository(),
        purchaseClient: InMemoryPurchaseClient = InMemoryPurchaseClient(),
        unit: WeightUnit = .kilograms,
        currentDate: @escaping @MainActor () -> Date = TestAppModelFactory.currentDate
    ) -> AppModel {
        let suiteName = "TrendTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(unit.rawValue, forKey: "weightUnit")
        let dailyTrend = DailyTrendManager()
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker(currentDate: currentDate)
        let settings = UserSettingsStore(cloudSync: repository, defaults: defaults)
        let dailyTips = DailyTipManager(defaults: defaults, currentDate: currentDate)
        let dailyStreak = DailyStreakManager(trend: dailyTrend, currentDate: currentDate)
        let weightEntries = WeightEntryManager(
            weightLog: weightLog,
            progress: progress,
            settings: settings,
            dailyTrend: dailyTrend,
            dailyTips: dailyTips,
            dailyStreak: dailyStreak,
            currentDate: currentDate
        )
        return AppModel(
            weightEntries: weightEntries,
            progressFeature: ProgressManager(
                progress: progress,
                weightLog: weightLog,
                settings: settings
            ),
            settingsFeature: SettingsManager(
                settings: settings,
                weightLog: weightLog,
                progress: progress,
                dailyStreak: dailyStreak,
                backupFiles: BackupFileManager()
            ),
            habitsFeature: HabitsManager(storage: InMemoryHabitDataStore(), currentDate: currentDate),
            purchaseFeature: PurchaseManager(client: purchaseClient),
            dailyTips: dailyTips,
            backupFeature: BackupManager(storage: LocalDataStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)),
                files: RecoveryBackupFiles(folder: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString), cloudFolder: { nil }), settings: settings, reload: {})
        )
    }
}
