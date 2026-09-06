// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// The composition root for the application.
///
/// AppBrain chooses and connects feature managers. Application behavior lives
/// in those features rather than accumulating in this assembly type.
@MainActor
final class AppBrain {
    /// The single production dependency graph used by the running app.
    static let shared = AppBrain.live()

    let weightEntries: any WeightEntryFeature
    let progressFeature: any ProgressFeature
    let settingsFeature: any SettingsFeature
    let habitsFeature: any HabitsFeature
    let purchaseFeature: any PurchaseFeature
    private let dailyTips: DailyTipManager
    private var applicationLaunchTask: Task<Void, Never>?

    init(
        weightEntries: any WeightEntryFeature,
        progressFeature: any ProgressFeature,
        settingsFeature: any SettingsFeature,
        habitsFeature: any HabitsFeature,
        purchaseFeature: any PurchaseFeature,
        dailyTips: DailyTipManager
    ) {
        self.weightEntries = weightEntries
        self.progressFeature = progressFeature
        self.settingsFeature = settingsFeature
        self.habitsFeature = habitsFeature
        self.purchaseFeature = purchaseFeature
        self.dailyTips = dailyTips
    }

    /// Produces the live, non-test AppBrain and assembles all production
    /// dependencies in one visible place.
    static func live() -> AppBrain {
        // A function, rather than a stored Date, keeps production time moving
        // while allowing tests to provide a fixed clock.
        let currentDate: @MainActor () -> Date = { .now }

        let repository = CloudKitWeightRepository()
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker()
        let settings = UserSettingsStore(cloudSync: repository)
        let dailyTrend = DailyTrendManager()
        let dailyTips = DailyTipManager()
        let dailyStreak = DailyStreakManager(trend: dailyTrend)
        let backupFiles = BackupFileManager()
        let habits = HabitsManager(
            repository: CloudKitHabitRepository(),
            currentDate: currentDate
        )
        let purchases = PurchaseManager(client: StoreKitPurchaseClient())

        let weightEntries = WeightEntryManager(
            weightLog: weightLog,
            progress: progress,
            settings: settings,
            dailyTrend: dailyTrend,
            dailyTips: dailyTips,
            dailyStreak: dailyStreak,
            currentDate: currentDate
        )
        let progressFeature = ProgressManager(
            progress: progress,
            weightLog: weightLog,
            settings: settings
        )
        let settingsFeature = SettingsManager(
            settings: settings,
            weightLog: weightLog,
            progress: progress,
            dailyStreak: dailyStreak,
            backupFiles: backupFiles
        )
        return AppBrain(
            weightEntries: weightEntries,
            progressFeature: progressFeature,
            settingsFeature: settingsFeature,
            habitsFeature: habits,
            purchaseFeature: purchases,
            dailyTips: dailyTips
        )
    }

    /// Responds to the application completing its launch. AppBrain refreshes
    /// feature data and installs long-lived observers in one central place.
    /// Every scene may call this safely; all callers await the same work.
    func applicationDidFinishLaunching() async {
        if let applicationLaunchTask {
            await applicationLaunchTask.value
            return
        }

        let task = Task { @MainActor [
            dailyTips,
            settingsFeature,
            weightEntries,
            habitsFeature,
            purchaseFeature
        ] in
            dailyTips.refresh() // requires immediate execution - no async behaviour required
            purchaseFeature.observeTransactionUpdates() // requires immediate execution

            let cloudStatusTask = Task { @MainActor in
                await settingsFeature.refreshCloudStatus()
            }
            let weightEntriesTask = Task { @MainActor in
                await weightEntries.refresh()
            }
            let habitsTask = Task { @MainActor in
                await habitsFeature.refresh()
            }
            let purchasesTask = Task { @MainActor in
                await purchaseFeature.refreshStoreState()
            }

            await cloudStatusTask.value
            await weightEntriesTask.value
            await habitsTask.value
            await purchasesTask.value
        }
        applicationLaunchTask = task
        await task.value
    }
}
