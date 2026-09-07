// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
@testable import Trend

@MainActor
enum TestAppModelFactory {
    static func make(
        repository: any WeightRepository & CloudSyncStatusProviding = InMemoryWeightRepository(),
        unit: WeightUnit = .kilograms,
        currentDate: @escaping @MainActor () -> Date = { .now }
    ) -> AppModel {
        let suiteName = "TrendTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(unit.rawValue, forKey: "weightUnit")
        let dailyTrend = DailyTrendManager()
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker()
        let settings = UserSettingsStore(cloudSync: repository, defaults: defaults)
        let dailyTips = DailyTipManager(defaults: defaults)
        let dailyStreak = DailyStreakManager(trend: dailyTrend)
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
            habitsFeature: HabitsManager(repository: InMemoryHabitRepository()),
            purchaseFeature: PurchaseManager(client: InMemoryPurchaseClient()),
            dailyTips: dailyTips
        )
    }
}
