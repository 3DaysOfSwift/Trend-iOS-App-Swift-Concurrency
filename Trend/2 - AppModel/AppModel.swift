// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

/// The composition root for the application.
///
/// AppModel chooses and connects feature managers. Application behavior lives
/// in those features rather than accumulating in this assembly type.
@MainActor
final class AppModel {
    /// The single production dependency graph used by the running app.
    static let shared = AppModel.live()

    let weightEntries: WeightEntryManager
    let progressFeature: ProgressManager
    let settingsFeature: SettingsManager
    let habitsFeature: HabitsManager
    let purchaseFeature: PurchaseManager
    private let dailyTips: DailyTipManager
    private var hasLaunched = false

    init(
        weightEntries: WeightEntryManager,
        progressFeature: ProgressManager,
        settingsFeature: SettingsManager,
        habitsFeature: HabitsManager,
        purchaseFeature: PurchaseManager,
        dailyTips: DailyTipManager
    ) {
        self.weightEntries = weightEntries
        self.progressFeature = progressFeature
        self.settingsFeature = settingsFeature
        self.habitsFeature = habitsFeature
        self.purchaseFeature = purchaseFeature
        self.dailyTips = dailyTips
    }

    /// Produces the live, non-test AppModel and assembles all production
    /// dependencies in one visible place.
    static func live() -> AppModel {
        // A function, rather than a stored Date, keeps production time moving
        // while allowing tests to provide a fixed clock.
        let currentDate: @MainActor () -> Date = { .now }

        let repository = CloudKitWeightRepository()
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker(currentDate: currentDate)
        let settings = UserSettingsStore(cloudSync: repository)
        let dailyTrend = DailyTrendManager()
        let dailyTips = DailyTipManager(currentDate: currentDate)
        let dailyStreak = DailyStreakManager(trend: dailyTrend, currentDate: currentDate)
        let backupFiles = BackupFileManager()
        let habitDataStore = CloudKitHabitDataStore(
            cache: FileHabitDataStore(), cloud: CloudKitHabitClient())
        let habits = HabitsManager(
            storage: habitDataStore,
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
        return AppModel(
            weightEntries: weightEntries,
            progressFeature: progressFeature,
            settingsFeature: settingsFeature,
            habitsFeature: habits,
            purchaseFeature: purchases,
            dailyTips: dailyTips
        )
    }

    /// Registers observation immediately and starts independent loads once.
    func applicationDidFinishLaunching() {
        guard !hasLaunched else { return }
        hasLaunched = true

        purchaseFeature.observeTransactionUpdates()
        dailyTips.refresh()
        
        Task { await purchaseFeature.refreshStoreState() }
        Task { await settingsFeature.refreshCloudStatus() }
        Task { await weightEntries.refresh() }
        Task { await habitsFeature.load() }
    }
    
    func applicationDidBecomeActive() {
        Task {
            await habitsFeature.updateCurrentDay()
            await habitsFeature.synchronize()
        }
    }

    func applicationSignificantTimeChange() {
        Task { await habitsFeature.updateCurrentDay() }
    }
}
