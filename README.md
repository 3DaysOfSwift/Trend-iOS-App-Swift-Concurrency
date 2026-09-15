# Trend

Trend is a complete, local-first weight tracker and a reference architecture for a greenfield SwiftUI app.

## Cooperative Feature Architecture (CFA)
This repository uses Cooperative Feature Architecture (CFA) which is reflected in the Xcode folder structure. This architecture has been evolved for use with AI copilots to reduce AI-written component-based architecture which can become less maintainable and messy with no clear relationships visible between how components are used in features.

Open Source CFA Skill Repository
[https://github.com/3DaysOfSwift/cooperative-feature-architecture](https://github.com/3DaysOfSwift/cooperative-feature-architecture)

## The architectural sentence

`View → ViewModel → Feature API → Feature Manager → Repository`

That sentence is also the folder structure. Open `Trend` in Xcode and the first distinction is between `1 - View` and `2 - AppModel`:

- **1 - View** contains SwiftUI and presentation state. Every screen has a folder containing its View and tightly coupled ViewModel.
- **2 - AppModel** contains the composition root and the layers beneath it: feature APIs, feature managers, domain types, repository contracts, and storage implementations.
- **3 - App Resources** contains assets, privacy metadata, and entitlements.
- **4 - Swift Extensions** contains reusable extensions of Swift and Foundation types. SwiftUI-specific extensions remain in `1 - View`.

ViewModels and UI-readable feature managers use Apple's Observation framework. Views own their `@Observable` ViewModel with `@State` and create an `@Bindable` projection only when a control requires a binding. The project therefore contains no Combine publisher forwarding or `@Published` state.

Read the complete [`AppModel iOS Application Template`](Documentation/APPMODEL_IOS_APPLICATION_TEMPLATE.md) for the reusable rules and [`ARCHITECTURE.md`](Documentation/ARCHITECTURE.md) for Trend's concrete implementation. The [Swift Concurrency Migration skill](Skills/swift-concurrency-migration/SKILL.md) applies the same rules when an AI coding agent creates, changes, or reviews an iOS application.

## AI skills

This repository includes two reusable skills:

- [Swift Concurrency Migration](Skills/swift-concurrency-migration/SKILL.md): build, review or migrate an application using the AppModel and Feature Manager architecture.
- [Xcode Project Dashboard](Skills/xcode-project-dashboard/SKILL.md): read an application's code and draw understandable task journeys, including child tasks, suspension, cancellation and operation ordering. Includes the interactive Load Habits example from Trend.

`Skills` contains exactly one folder per skill. Supporting references, metadata and assets stay with their owning skill. Project documents live in `Documentation`; this README remains the repository entry point. The architecture skill currently reads canonical documents from `Documentation`, so its folder alone is not a standalone installation package. The overview skill can explain other Swift architectures without changing them.

```text
Trend/
├── Skills/
│   ├── swift-concurrency-migration/
│   └── xcode-project-dashboard/
├── Documentation/
├── Trend/
├── TrendTests/
└── Trend.xcodeproj/
```

## SwiftData, iCloud synchronization and recovery backups

Trend saves records with SwiftData behind its repository boundary. Apple's
CloudKit integration synchronizes those records, including edits and deletions,
with the user's private iCloud database. Habit preference writes remain separate
from recording entries. No SwiftData objects or contexts escape into the UI.

Separately, launch, foreground entry and successful edits call
`triggerDataBackupIfNeeded()`. Changed data produces an automatic JSON recovery
snapshot at most once every 24 hours while the app is used. Back up now bypasses
that interval. Latest, Previous and retained weekly snapshots are copied to
iCloud Drive → Trend → Backups, in a separate folder for each installation.
CloudKit sync is independent of this backup schedule; recovery files can lag
recent edits by a day. Weekly snapshots are not automatically pruned.

Settings → Backups and recovery shows status and offers explicit restore through
Files, with a date/count preview and confirmation. Restore changes synchronize
too. A local pre-restore snapshot is preserved. A replacement phone cannot
overwrite another installation's recovery files while downloading its history.

### One-time Apple configuration

1. Keep the existing bundle identifier, `com.3DaysOfSwiftConcurrency.Trend`.
2. Create/enable the **CloudKit** container
   `iCloud.com.3DaysOfSwiftConcurrency.Trend.SwiftData` for this app. A new
   container avoids reusing the old hand-written CloudKit schema.
3. Keep **iCloud Documents** enabled for
   `iCloud.com.3DaysOfSwiftConcurrency.Trend`. Its Documents folder appears as
   **Trend** in Files. Refresh provisioning for both capabilities; remote
   notifications are configured in the app's Info.plist.
4. Verify a signed-device upload and restore using
   [the acceptance checklist](Documentation/BACKUP_VERIFICATION.md).

Initialize and deploy the SwiftData-managed CloudKit schema before distributing
through TestFlight or the App Store, following
[Apple's setup guide](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).
Pre-SwiftData development stores are not imported. There is no direct SQLite
code or compatibility bridge. Existing SwiftData records continue to load normally.
Recovery files include the producing app version, build number and a separate
backup-format version. The format determines how to decode the data; app metadata
identifies the build that produced it.

## Running

Open `Trend.xcodeproj`, select an iPhone simulator or device, and run. The target uses a generated modern launch screen and supports the full edge-to-edge viewport on Face ID devices.

The project is generated from `project.yml` with XcodeGen. Regenerate after changing target configuration.
