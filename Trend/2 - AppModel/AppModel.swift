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
    let backupFeature: BackupManager
    let importFeature: WeightImportManager
    private let dailyTips: DailyTipManager
    private var hasLaunched = false

    init(
        weightEntries: WeightEntryManager,
        progressFeature: ProgressManager,
        settingsFeature: SettingsManager,
        habitsFeature: HabitsManager,
        purchaseFeature: PurchaseManager,
        dailyTips: DailyTipManager,
        backupFeature: BackupManager,
        importFeature: WeightImportManager
    ) {
        self.weightEntries = weightEntries
        self.progressFeature = progressFeature
        self.settingsFeature = settingsFeature
        self.habitsFeature = habitsFeature
        self.purchaseFeature = purchaseFeature
        self.dailyTips = dailyTips
        self.backupFeature = backupFeature
        self.importFeature = importFeature
    }

    /// Produces the live, non-test AppModel and assembles all production
    /// dependencies in one visible place.
    static func live() -> AppModel {
        // A function, rather than a stored Date, keeps production time moving
        // while allowing tests to provide a fixed clock.
        let currentDate: @MainActor () -> Date = { .now }

        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Trend", directoryHint: .isDirectory)
        let storage = LocalDataStore(directory: directory,
            cloudContainerIdentifier: "iCloud.com.3DaysOfSwiftConcurrency.Trend.SwiftData")
        let repository = LocalWeightRepository(storage: storage)
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker(currentDate: currentDate)
        let settings = UserSettingsStore(cloudSync: ICloudDriveAvailability())
        let dailyTrend = DailyTrendManager()
        let dailyTips = DailyTipManager(currentDate: currentDate)
        let dailyStreak = DailyStreakManager(trend: dailyTrend, currentDate: currentDate)
        let backupFiles = BackupFileManager()
        let habitDataStore = LocalHabitRepository(storage: storage)
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
        let backups = BackupManager(storage: storage,
            files: RecoveryBackupFiles(folder: directory.appending(path: "Backups")), settings: settings) {
                await weightEntries.refresh()
                await habits.reload()
            }
        return AppModel(
            weightEntries: weightEntries,
            progressFeature: progressFeature,
            settingsFeature: settingsFeature,
            habitsFeature: habits,
            purchaseFeature: purchases,
            dailyTips: dailyTips,
            backupFeature: backups,
            importFeature: WeightImportManager(weightLog: weightLog) { await weightEntries.refresh() }
        )
    }

    /// Registers observation immediately and starts independent loads once.
    func applicationDidFinishLaunching() {
        guard !hasLaunched else { return }
        hasLaunched = true

        purchaseFeature.observeTransactionUpdates()
        dailyTips.refresh()
        backupFeature.observeLocalChanges()
        backupFeature.observeCloudChanges()
        Task { await backupFeature.triggerDataBackupIfNeeded() }
        
        Task { await purchaseFeature.refreshStoreState() }
        Task { await settingsFeature.refreshCloudStatus() }
        Task { await weightEntries.refresh() }
        Task { await habitsFeature.load() }
    }
    
    func applicationDidBecomeActive() {
        Task {
            await weightEntries.refresh()
            await habitsFeature.reload()
            await backupFeature.triggerDataBackupIfNeeded()
        }
    }

    func applicationSignificantTimeChange() {
        Task { await habitsFeature.updateCurrentDay() }
    }
}
