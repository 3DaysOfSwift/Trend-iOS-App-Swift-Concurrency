// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation
import Testing
@testable import Trend

struct RecoveryBackupTests {
    @Test func backupsRecordAppVersionBuildAndFormat() throws {
        var backup = snapshot(at: .now)
        backup.appVersion = "1.2.3"
        backup.appBuild = "42"
        let restored = try JSONDecoder().decode(RecoverySnapshot.self, from: JSONEncoder().encode(backup))
        #expect(restored.appVersion == "1.2.3")
        #expect(restored.appBuild == "42")
        #expect(restored.formatVersion == 1)
        try restored.validate()
    }

    @Test func manualBackupUpdatesVersionMetadataEvenWhenRecordsAreUnchanged() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let files = RecoveryBackupFiles(folder: folder, cloudFolder: { nil })
        var backup = snapshot(at: .now)
        backup.appVersion = "1.0"
        backup.appBuild = "1"
        _ = try await files.saveLocal(backup)
        backup.appBuild = "2"
        let file = try await files.prepareBackupIfNeeded(backup, force: true)
        let restored = try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: file))
        #expect(restored.appBuild == "2")
    }
    @Test func changedCloudAccountCannotReceiveExistingRecoveryFiles() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try BackupCloudAccount.verify(NSString(string: "Original account"), in: folder)
        #expect(throws: (any Error).self) {
            try BackupCloudAccount.verify(NSString(string: "Different account"), in: folder)
        }
        try BackupCloudAccount.verify(NSString(string: "Original account"), in: folder)
    }
    private func snapshot(at date: Date, value: Double = 70) -> RecoverySnapshot {
        RecoverySnapshot(revision: UUID().uuidString, createdAt: date,
            weight: WeightStore(entries: [WeightEntry(date: date, kilograms: value)], goalKilograms: nil),
            habits: HabitData(enabledHabits: [Habit(type: .water)], entries: []))
    }

    @Test func retainsWeeklyCopiesAndPreviousGoodSnapshot() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let firstDate = Date(timeIntervalSince1970: 1_788_480_000)
        let first = snapshot(at: firstDate)
        let firstFiles = RecoveryBackupFiles(folder: folder, now: { firstDate }, cloudFolder: { nil })
        _ = try await firstFiles.saveLocal(first)
        let next = snapshot(at: firstDate.addingTimeInterval(86_400), value: 69)
        _ = try await firstFiles.saveLocal(next)
        let week = folder.appending(path: "Weekly")
        #expect(try FileManager.default.contentsOfDirectory(at: week, includingPropertiesForKeys: nil).count == 1)
        let repeated = try await firstFiles.saveLocal(next)
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: repeated)).revision == next.revision)
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: folder.appending(path: "Previous.json"))).revision == first.revision)
        let laterDate = firstDate.addingTimeInterval(8 * 86_400)
        let laterFiles = RecoveryBackupFiles(folder: folder, now: { laterDate }, cloudFolder: { nil })
        _ = try await laterFiles.saveLocal(snapshot(at: laterDate))
        #expect(try FileManager.default.contentsOfDirectory(at: week, includingPropertiesForKeys: nil).count == 2)
    }

    @Test func weeklyCloudSnapshotsAreImmutableWhileLatestAndPreviousRotate() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let cloud = root.appending(path: "Cloud")
        let files = RecoveryBackupFiles(folder: root.appending(path: "Local"), access: DirectBackupFileAccess(), cloudFolder: { cloud })
        let first = snapshot(at: .now)
        let firstURL = try await files.saveLocal(first)
        _ = try await files.upload(firstURL, revision: first.revision)
        let installation = try #require(try FileManager.default.contentsOfDirectory(at: cloud.appending(path: "Backups"), includingPropertiesForKeys: nil).first)
        let cloudFirst = try #require(try FileManager.default.contentsOfDirectory(at: installation.appending(path: "Weekly"), includingPropertiesForKeys: nil).first)
        let bytes = try Data(contentsOf: cloudFirst)
        let second = snapshot(at: .now, value: 69)
        let secondURL = try await files.saveLocal(second)
        _ = try await files.upload(secondURL, revision: second.revision)
        #expect(try Data(contentsOf: cloudFirst) == bytes)
        #expect(try FileManager.default.contentsOfDirectory(at: installation, includingPropertiesForKeys: nil).count == 3)
        #expect(try await files.preview(installation.appending(path: "Latest.json")).revision == second.revision)
        #expect(try await files.preview(installation.appending(path: "Previous.json")).revision == first.revision)
        #expect(try await files.preview(cloudFirst).weight.entries.first?.kilograms == 70)
    }

    @Test func automaticChecksAreThrottledButManualBackupIsImmediate() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let date = Date(timeIntervalSince1970: 1_788_480_000)
        let files = RecoveryBackupFiles(folder: folder, now: { date.addingTimeInterval(60) }, cloudFolder: { nil })
        let first = snapshot(at: date)
        _ = try await files.prepareBackupIfNeeded(first, force: false)
        let second = snapshot(at: date.addingTimeInterval(60), value: 69)
        let unchanged = try await files.prepareBackupIfNeeded(second, force: false)
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: unchanged)).revision == first.revision)
        let manual = try await files.prepareBackupIfNeeded(second, force: true)
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: manual)).revision == second.revision)
        let later = date.addingTimeInterval(2 * 86_400)
        let laterFiles = RecoveryBackupFiles(folder: folder, now: { later }, cloudFolder: { nil })
        let third = snapshot(at: later, value: 68)
        let daily = try await laterFiles.prepareBackupIfNeeded(third, force: false)
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: daily)).revision == third.revision)
    }

    @Test func newInstallationCannotOverwriteOldPhoneRecoveryFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let cloud = root.appending(path: "Cloud")
        for name in ["OldPhone", "NewPhone"] {
            let files = RecoveryBackupFiles(folder: root.appending(path: name), access: DirectBackupFileAccess(), cloudFolder: { cloud })
            let value = snapshot(at: .now)
            let file = try await files.saveLocal(value)
            _ = try await files.uploadPreparedBackup(file)
        }
        #expect(try FileManager.default.contentsOfDirectory(at: cloud.appending(path: "Backups"), includingPropertiesForKeys: nil).count == 2)
    }

    @Test func unavailableCloudDoesNotPreventLocalBackup() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let files = RecoveryBackupFiles(folder: root, cloudFolder: { nil })
        let backup = snapshot(at: .now)
        let file = try await files.saveLocal(backup)
        await #expect(throws: (any Error).self) { try await files.upload(file, revision: backup.revision) }
        #expect(try JSONDecoder().decode(RecoverySnapshot.self, from: Data(contentsOf: file)).revision == backup.revision)
    }
}

private struct DirectBackupFileAccess: BackupFileAccess {
    func replaceSnapshot(_ data: Data, at target: URL) throws { try data.write(to: target, options: .atomic) }
    func writeNewSnapshot(_ data: Data, to target: URL) throws {
        if !FileManager.default.fileExists(atPath: target.path) { try data.write(to: target, options: .atomic) }
    }
    func read(_ url: URL) throws -> Data { try Data(contentsOf: url) }
}
