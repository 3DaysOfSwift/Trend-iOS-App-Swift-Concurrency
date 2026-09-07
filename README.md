# Trend

Trend is a complete, local-first weight tracker and a reference architecture for a greenfield SwiftUI app.

## The architectural sentence

`View → ViewModel → Feature API → Feature Manager → Repository`

That sentence is also the folder structure. Open `Trend` in Xcode and the first distinction is between `1 - View` and `2 - AppModel`:

- **1 - View** contains SwiftUI and presentation state. Every screen has a folder containing its View and tightly coupled ViewModel.
- **2 - AppModel** contains the composition root and the layers beneath it: feature APIs, feature managers, domain types, repository contracts, and storage implementations.
- **3 - App Resources** contains assets, privacy metadata, and entitlements.
- **4 - Swift Extensions** contains reusable extensions of Swift and Foundation types. SwiftUI-specific extensions remain in `1 - View`.

ViewModels and UI-readable feature managers use Apple's Observation framework. Views own their `@Observable` ViewModel with `@State` and create an `@Bindable` projection only when a control requires a binding. The project therefore contains no Combine publisher forwarding or `@Published` state.

Read the complete [`AppModel iOS Application Template`](APPMODEL_IOS_APPLICATION_TEMPLATE.md) for the reusable rules and [`ARCHITECTURE.md`](ARCHITECTURE.md) for Trend's concrete implementation. The repository is also an installable [`appmodel-ios-template` skill](SKILL.md) that applies the same rules when an AI coding agent creates, changes, or reviews an iOS application.

## iCloud sync

`CloudKitWeightRepository` stores the weight store in the signed-in user's private CloudKit database. `FileWeightRepository` remains its durable offline cache. A local save completes first, and a pending-upload marker ensures an interrupted CloudKit write is retried on the next launch. If iCloud is unavailable, the app remains usable on that device.

The app has no public records, custom user accounts, analytics, or advertising SDKs. Settings reports whether the current device can access iCloud.

### One-time Apple configuration

1. In Xcode, open **Signing & Capabilities** for the Trend target and confirm the team, bundle identifier, and **iCloud → CloudKit** capability.
2. Allow Xcode to create or attach `iCloud.com.mattharding.Trend`, or configure the explicit App ID in Certificates, Identifiers & Profiles.
3. Run a development build on a device signed into iCloud and save an entry to create the development schema.
4. Before TestFlight or App Store distribution, verify the schema in CloudKit Console and deploy it to Production.

## Running

Open `Trend.xcodeproj`, select an iPhone simulator or device, and run. The target uses a generated modern launch screen and supports the full edge-to-edge viewport on Face ID devices.

The project is generated from `project.yml` with XcodeGen. Regenerate after changing target configuration.
