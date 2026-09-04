![3 Days of Swift Concurrency — learn modern concurrency, async await, tasks and actors in Swift](readme-images/3DaysOfSwift-Concurrency-Header.png)

Created by [3DaysOfSwiftConcurrency.com](https://www.3daysofswiftconcurrency.com).

# Trend

**A complete, local-first iOS weight tracker—and a reference architecture for modern greenfield SwiftUI projects.**

Trend turns a small daily action into a clear sense of direction. Log today’s weight, see whether your longer-term trend is moving the way you want, build a daily streak, and receive a concise piece of encouragement or practical information.

The app is deliberately useful enough to install, while remaining small enough for another developer to understand. Its larger purpose is to demonstrate a strict and teachable boundary between the SwiftUI interface and the application’s behaviour.

> **View → ViewModel → AppBrain → Feature Manager → Repository**

## Why this project exists

Architecture examples are often too small to reveal the decisions that matter in a real app. Trend includes navigation, editing, validation, persistence, iCloud synchronisation, charts, derived insights, settings, failure states, and tests—without turning those concerns into one oversized type.

It is designed to answer practical questions such as:

- Where should asynchronous work begin?
- Who owns screen state, and how long should that state live?
- Where should chart calculations and business rules run?
- How can local persistence remain reliable while iCloud is unavailable?
- How do dependencies stay replaceable in tests without complicating production code?

## What the app does

- Records daily weight check-ins in kilograms or pounds
- Shows a Monday-to-Sunday streak at a glance
- Classifies the latest result as improving, holding steady, or moving upward
- Displays historical entries with edit and delete support
- Charts progress and projects the current trend forward
- Produces a short, data-derived commentary on progress
- Tracks a target weight
- Cycles through small tips and encouragement cards
- Imports and exports a backup of the user’s data
- Stores an offline copy locally and synchronises private records through iCloud
- Keeps health data on the user’s device and private CloudKit database

The informational cards are general educational content, not medical advice.

## Architecture at a glance

```text
┌──────────────────────────────────────────────────────────┐
│ 1 - View                                                 │
│ SwiftUI Views + one screen-owned ViewModel per feature   │
└──────────────────────────┬───────────────────────────────┘
                           │ user intent / observable state
                           ▼
┌──────────────────────────────────────────────────────────┐
│ 2 - AppBrain                                             │
│ Application commands, feature managers and data access   │
└──────────────────────────┬───────────────────────────────┘
                           │ repository contracts
                           ▼
┌──────────────────────────────────────────────────────────┐
│ Local JSON cache                         Private CloudKit │
└──────────────────────────────────────────────────────────┘
```

The top-level folders are numbered intentionally. A developer opening the project can immediately see the application’s principal divide:

```text
Trend/
├── 1 - View/
│   ├── SwiftUI Extensions/
│   └── Views/
│       ├── Root/
│       ├── Today/
│       ├── EntryEditor/
│       ├── Progress/
│       ├── History/
│       ├── Settings/
│       └── MetricCard/
├── 2 - AppBrain/
│   ├── Features/
│   └── User Data Storage/
│       ├── Data Types/
│       ├── Protocols/
│       ├── Local/
│       └── CloudKit/
└── 3 - App Resources/
```

Each screen folder keeps its `View` beside its tightly coupled `ViewModel`. The AppBrain is grouped by responsibility rather than by UI screen.

### 1. Views render; ViewModels present

Views are declarative and own their ViewModels for the lifetime of the screen. A ViewModel exposes presentation-ready state and translates user intent into an AppBrain command. It does not perform persistence, CloudKit work, projection mathematics, or trend classification itself.

Reusable display components can accept plain value types. They do not receive the AppBrain or reach into feature managers.

### 2. AppBrain is the composition root

`AppBrain` is the app’s shared model boundary. Its live instance assembles the feature managers and repositories used in production. ViewModels have a zero-argument-friendly initializer whose dependency defaults to that live AppBrain, while tests can still supply an isolated brain.

```swift
@MainActor
@Observable
final class TodayViewModel {
    private let brain: AppBrain

    init(brain: AppBrain = .shared) {
        self.brain = brain
    }
}
```

The singleton is limited to dependency composition. AppBrain does not own ViewModels, presented sheets, routes, alerts, or other UI lifetime state.

### 3. Feature managers own business rules

Feature managers contain the decisions the UI should not make: saving a weight, calculating a trend, preparing chart points, producing a projection, selecting rotating content, and coordinating backup or synchronisation behaviour.

This keeps business logic testable without rendering a SwiftUI view.

### 4. Repositories own storage details

The weight feature depends on a repository contract rather than CloudKit directly. The production repository coordinates two stores:

- a durable local JSON cache for immediate, offline-first reads and writes;
- the user’s private CloudKit database for iCloud synchronisation.

A save completes locally first. Cloud upload follows asynchronously, and pending work can be retried. Terminating the app therefore does not require it to have entered the background before a weight is retained locally.

## Modern SwiftUI state

Trend targets iOS 17 and uses Apple’s Observation framework:

- `@Observable` for observable reference types
- `@State` when a View owns a ViewModel
- local `@Bindable` projections when a control needs a binding
- computed properties for derived presentation state

The project does not use `ObservableObject` and `@Published` as its default state system. Observation tracks the stored properties read by a View, while ViewModels explicitly expose the state changes that should invalidate their computed values.

## Swift concurrency

The asynchronous path is intentionally visible:

```text
Button tap
  → screen-owned ViewModel starts the unstructured UI task
  → AppBrain command
  → feature manager async function
  → repository async function
  → local persistence and/or CloudKit
  → observable state changes
  → SwiftUI renders the new state
```

The ViewModel owns a task only when the task belongs to that screen interaction. Durable saves are allowed to finish even if the presenting UI disappears. Lower layers expose `async` functions instead of hiding work inside fire-and-forget tasks, which keeps cancellation and error behaviour clear.

UI-facing state is isolated to the main actor. Persistence and CloudKit details remain behind their respective boundaries.

## Testing

The test target mirrors the architectural divide:

```text
TrendTests/
├── View model tests/
└── AppBrain tests/
```

ViewModel tests exercise screen states and user scenarios using injected test dependencies. AppBrain tests cover feature rules, projections, storage behaviour, content rotation, and failure paths independently of SwiftUI.

The tests use Swift Testing and are intended to be readable examples, not merely coverage machinery.

Run them in Xcode with **Product → Test**, or from the command line:

```sh
xcodebuild test \
  -project Trend.xcodeproj \
  -scheme Trend \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Choose any installed simulator if that device is unavailable.

## Running the project

### Requirements

- Xcode 16 or later
- iOS 17 or later
- An Apple Developer account for testing the iCloud path on a signed build

### Setup

1. Clone the repository.
2. Open `Trend.xcodeproj` in Xcode.
3. Select the **Trend** target and choose your development team under **Signing & Capabilities**.
4. Give the app a bundle identifier belonging to your team if necessary.
5. Confirm that **iCloud** and **CloudKit** are enabled and select an iCloud container owned by your account.
6. Build and run on a simulator or device.

The local store works without iCloud. Cloud synchronisation requires valid signing, the iCloud capability, an available container, and a user signed into iCloud.

If you regenerate the Xcode project, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run:

```sh
xcodegen generate
```

The checked-in `project.yml` is the source of truth for generated project structure and build settings.

## Privacy

Trend does not need a custom account. Weight entries are stored locally and, when enabled, in the signed-in user’s private CloudKit database. The project contains no advertising or analytics SDK.

Anyone adapting the project for distribution remains responsible for reviewing its behaviour, privacy disclosures, entitlements, content, and App Store requirements.

## A reference, not a framework

This repository is opinionated on purpose. It is not another architecture package to import. It is a complete example to read, question, modify, and use as a visual mental model for a new SwiftUI application.

The central rule is simple:

> The UI describes what the user sees. The AppBrain decides what the application does.

Built as part of [3 Days of Swift Concurrency](https://3daysofswiftconcurrency.com/).

---

© 2026 3 Days of Swift Concurrency. All rights reserved.
