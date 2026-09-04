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
    private let dailyTips: DailyTipManager
    private var hasStarted: Bool

    init(
        weightEntries: any WeightEntryFeature,
        progressFeature: any ProgressFeature,
        settingsFeature: any SettingsFeature,
        dailyTips: DailyTipManager
    ) {
        self.weightEntries = weightEntries
        self.progressFeature = progressFeature
        self.settingsFeature = settingsFeature
        self.dailyTips = dailyTips
        self.hasStarted = false
    }

    /// Produces the live, non-test AppBrain and assembles all production
    /// dependencies in one visible place.
    static func live() -> AppBrain {
        let repository = CloudKitWeightRepository()
        let weightLog = WeightLogManager(repository: repository)
        let progress = ProgressTracker()
        let settings = UserSettingsStore(cloudSync: repository)
        let dailyTrend = DailyTrendManager()
        let dailyTips = DailyTipManager()
        let dailyStreak = DailyStreakManager(trend: dailyTrend)
        let backupFiles = BackupFileManager()

        // A function, rather than a stored Date, keeps production time moving
        // while allowing tests to provide a fixed clock.
        let currentDate: @MainActor () -> Date = { .now }

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
            dailyTips: dailyTips
        )
    }

    /// Starts the shared application graph once. Startup belongs here because it
    /// initializes the application as a whole rather than one individual feature.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        dailyTips.beginLaunch()

        let cloudStatusTask = Task { @MainActor [settingsFeature] in
            await settingsFeature.refreshCloudStatus()
        }
        let weightEntriesTask = Task { @MainActor [weightEntries] in
            await weightEntries.refresh()
        }

        await cloudStatusTask.value
        await weightEntriesTask.value
    }
}
