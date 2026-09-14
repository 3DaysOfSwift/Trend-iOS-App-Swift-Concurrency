# SwiftData synchronization and recovery acceptance checks

Do not uninstall the existing app or clear its container to begin testing. Keep
the bundle identifier com.3DaysOfSwiftConcurrency.Trend. Existing SwiftData
records remain usable. Pre-SwiftData development records are not imported.

## Signing and schema — required on the developer account

1. In Signing & Capabilities, enable CloudKit for
   iCloud.com.3DaysOfSwiftConcurrency.Trend.SwiftData. Create this new container
   and associate it with the app identifier. Do not reuse the old custom schema.
2. Keep iCloud Documents enabled for iCloud.com.3DaysOfSwiftConcurrency.Trend.
   Configuration/Info.plist exposes its Documents folder as Trend in Files and
   enables background remote notifications.
3. Refresh the signing profile. Merely editing an entitlement file does not
   provision the capability on Apple's servers.
4. Initialize the development CloudKit schema using Apple's SwiftData setup
   guidance, exercise every stored model, and deploy the schema to Production
   before testing through TestFlight/App Store. Development and Production are
   separate databases.
5. Use signed devices with the same iCloud account, iCloud enabled for Trend and
   available storage. Native unit tests do not establish cloud transfer success.

[Apple's SwiftData CloudKit setup](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)

## Local persistence — must pass first

1. Turn off Wi-Fi and cellular data, keeping the same installed app.
2. Record weight, select water and morning mood, and record both habits.
3. Confirm the records appear in history.
4. Force-quit and reopen. Confirm values and selections remain.
5. Repeat with edits, deletions, custom habits and goal changes.
6. A backup/sync failure must not turn a successful local save into missing data.

## Apple synchronization and replacement-phone recovery

1. Reconnect the original phone. Verify its records reach the new CloudKit
   container; an export event is not proof that all later edits uploaded.
2. Install the same build/environment on a spare device signed into the same
   iCloud account. Never delete the only working installation to test this.
3. Open Trend and allow synchronization. Records and selections should appear
   without importing a JSON file or restarting the app.
4. Make an edit on each device; verify the other eventually reflects it. Test
   different records and a deliberate same-record conflict separately.
5. Delete one test record; verify the deletion synchronizes too.
6. Keep one screen open while the other device adds a record, then record a new
   entry on the first. The unseen record must not be removed.
7. Test offline recording and reconnecting. Also test account unavailable,
   storage full and account changes. Verify errors/status and data isolation.
   Recovery uploads pause if the iCloud identity differs from the account
   originally used for backups; returning to that account permits retries.
8. Verify the initial empty local store never uploads blanket deletions or
   default empty habit selections while cloud history is downloading.

## Independent recovery files

1. Open Settings → Backups and recovery → Back up now.
2. Wait for uploaded status. Pending means files are staged, not yet safe in cloud.
3. Inspect iCloud Drive → Trend → Backups → installation folder:
   Latest.json, Previous.json (after another changed snapshot) and Weekly.
4. Make rapid edits. Automatic checks must not create a new snapshot per tap:
   changed snapshots are limited to one per 24 hours while the app is used.
5. Back up now must capture current records regardless of the daily interval.
6. Test an unavailable Drive container and retry on return. Existing local
   snapshots and edits must remain intact.
7. Verify a weekly snapshot after seven days, including an unchanged history.
   Previous weekly copies must still be present locally and in Drive.
8. A new installation must use a different folder, preserving old-phone backups
   even when its first CloudKit download is only partially complete.
9. Removing a JSON recovery file in Files must not delete live SwiftData records.

## Explicit restore

Each new snapshot includes appVersion, appBuild and formatVersion. The first
two identify the producing app; formatVersion selects the supported file layout.
Unsupported formats must fail before any records change.

1. Choose a JSON file through Files. Check date, entry counts and selections.
2. Cancel first: no data should change. Then confirm and inspect histories,
   selections, custom names, goal and weight unit.
3. Restore changes also synchronize to CloudKit. Verify this on the spare device.
4. Force-quit and reopen after restoration.
5. Try invalid/truncated JSON. It must fail without changing records.
6. Verify a pre-restore snapshot in Application Support/Trend/Backups/Before-restore.

## Limits and retention

Synchronization is eventual, not a guaranteed immediate cloud save. Recovery
snapshots can lag edits by up to 24 hours while the app is used, or longer if the
app is not running or iCloud is unavailable. No background timer is promised.
Latest/Previous rotate; weekly snapshots are kept indefinitely. Separate
installation folders and pre-restore copies also remain. No existing cloud files
are deleted as part of this upgrade. A local-only copy cannot protect against
losing the device.
