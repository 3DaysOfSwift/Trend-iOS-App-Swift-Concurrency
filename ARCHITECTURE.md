# Architecture

## Visual map

```text
┌──────────────────────── View ─────────────────────────┐
│ SwiftUI View → tightly coupled ViewModel              │
└──────────────────────────┬─────────────────────────────┘
                           │ user intent
                           ▼
┌────────────────────── AppModel ────────────────────────┐
│ AppModel                                               │
│    │ references                                        │
│    ▼                                                   │
│ Feature Managers                                       │
│    │                                                   │
│    ▼                                                   │
│ Repository Contracts                                  │
│    │                                                   │
│    ▼                                                   │
│ Storage Implementations                               │
└────────────────────────────────────────────────────────┘
```

The boundary between the View and the Model is intentionally explicit:

```text
ViewModel → Feature API → Feature Manager
```

The ViewModel communicates only through the narrow Feature API it needs. The
Feature Manager implements that API inside the AppModel layer, owns the feature
behaviour, and reaches external systems through a repository contract. This
keeps the ViewModel on the presentation side of the boundary while allowing
AppModel to assemble and retain the real Feature Managers and storage
implementations.

## Folder map

```text
Trend
├── 1 - View
│   ├── TrendApp.swift
│   ├── Theme
│   │   ├── AppColourTheme.swift
│   │   └── ThemeManager.swift
│   ├── SwiftUI Extensions
│   │   └── HabitErrorAlert.swift
│   └── Views
│       ├── Root
│       │   ├── RootView.swift
│       ├── Today
│       │   ├── TodayView.swift
│       │   └── TodayViewModel.swift
│       ├── EntryEditor
│       │   ├── EntryEditorView.swift
│       │   └── EntryEditorViewModel.swift
│       ├── Progress
│       │   ├── ProjectionView.swift
│       │   └── ProgressViewModel.swift
│       ├── History
│       │   ├── HistoryView.swift
│       │   └── HistoryViewModel.swift
│       ├── Settings
│       │   ├── SettingsView.swift
│       │   └── SettingsViewModel.swift
│       └── Habits
│           ├── HabitsView.swift
│           ├── HabitsViewModel.swift
│           ├── HabitLibraryView.swift
│           ├── HabitLibraryViewModel.swift
│           ├── History
│           │   ├── HabitHistoryView.swift
│           │   └── HabitHistoryViewModel.swift
│           └── Tracking
│               ├── Coffee
│               │   ├── CoffeeTrackingView.swift
│               │   └── CoffeeTrackingViewModel.swift
│               ├── Gym
│               │   ├── GymTrackingView.swift
│               │   └── GymTrackingViewModel.swift
│               ├── Alcohol
│               │   ├── AlcoholTrackingView.swift
│               │   └── AlcoholTrackingViewModel.swift
│               ├── Running
│               │   ├── RunningTrackingView.swift
│               │   └── RunningTrackingViewModel.swift
│               ├── Sleep
│               │   ├── SleepTrackingView.swift
│               │   └── SleepTrackingViewModel.swift
│               ├── Wake Time
│               │   ├── WakeTimeTrackingView.swift
│               │   └── WakeTimeTrackingViewModel.swift
│               └── Water
│                   ├── WaterTrackingView.swift
│                   └── WaterTrackingViewModel.swift
├── 2 - AppModel
│   ├── AppModel.swift
│   ├── Features
│   │   ├── Daily Streak
│   │   ├── Daily Tips
│   │   ├── Daily Trend
│   │   ├── Habits
│   │   ├── Progress
│   │   ├── Purchases
│   │   ├── Settings
│   │   └── WeightLog
│   │       ├── WeightEntry
│   │       ├── WeightEntryDraft
│   │       └── WeightUnit
│   └── User Data Storage
│       ├── Protocols
│       ├── Local
│       └── CloudKit
├── 3 - App Resources
│   ├── Assets.xcassets
│   ├── PrivacyInfo.xcprivacy
│   └── Trend.entitlements
└── 4 - Swift Extensions
```

The numeric prefixes make the intended reading order explicit in Xcode:
presentation first, application behaviour second, supporting app resources
third, and reusable Swift language extensions fourth.

## Responsibilities

### View

- Renders values supplied by its ViewModel.
- Remains a lightweight, declarative description that is quick to create and discard without starting work as a side effect.
- Creates and owns its `@Observable` ViewModel as `@State private var viewModel = FeatureViewModel()`, so the model's lifetime follows the screen's lifetime.
- Uses a local `@Bindable` projection only where a SwiftUI control needs a writable binding.
- Owns any sheet or dialog it presents using local SwiftUI state.
- Accepts no service, ViewModel, or callback inputs. A destination may accept the plain data it renders or edits, such as `EntryEditorView(entry:)`.
- Owns ephemeral visual state such as the selected chart point or keyboard focus.
- May create an unretained `Task` to bridge a synchronous UI event to an async method, but never stores a Task handle.
- Contains no repository access and coordinates no feature managers.

### ViewModel

- Is named after and stored beside one View.
- Uses the Observation framework's `@Observable` macro; stored properties need no `@Published` annotation.
- Converts feature state into values convenient for that View.
- Receives user intent and forwards it to its retained feature capability.
- Owns any Task that must be tracked, cancelled, replaced, or inspected later.
- Retains the smallest coherent set of narrow feature capabilities required by its screen, rather than AppModel itself.
- Defaults that capability to the matching feature supplied by `AppModel.shared`, allowing production Views to construct it without dependency plumbing.
- Keeps the feature initializer parameter available so tests can substitute an isolated capability.
- Contains presentation validation and file-picker state when those concerns are specific to its View.
- Does not persist data or call another ViewModel.
- Is never cached by another ViewModel.

### Colour Theme

`AppColourTheme` is the single reviewable palette shared with the design team,
and `ThemeManager` supplies the selected theme to every screen. Trend supports
multiple themes during development so every View is forced to use the shared
palette rather than accumulating independent colour literals. Both types remain
in `1 - View` because they control presentation.

### AppModel

- Is the composition root exposed as the single production instance `AppModel.shared`.
- Constructs feature managers and supplies their narrow APIs to ViewModels.
- Stores one `WeightEntryManager` instance shared by Today, Entry Editor, and History, making it impossible to assemble those screens over inconsistent weight state.
- Keeps feature-specific workflows in their managers. Its sole application-wide workflow is `applicationDidFinishLaunching()`, which uses the first moments after launch as an opportunity to begin loading app-scoped features and install long-lived observers once.
- Has a fully explicit initializer: every dependency is required and no production implementation is silently created there.
- Confines production construction policy to `live()`; test construction policy lives in `TestAppModelFactory`.
- Wires production feature managers to production repositories.
- Contains no SwiftUI layout code.

AppModel and its feature managers are app-scoped; ViewModels are view-scoped. Removing a View releases its ViewModel, while shared feature state remains available through the feature manager retained by AppModel. Production ViewModels obtain concrete feature managers from `AppModel.shared` through defaulted initializer parameters; tests inject managers from an isolated application graph. Repository and client protocols remain at boundaries with replaceable implementations.

The app delegate calls `applicationDidFinishLaunching()` synchronously. A single boolean prevents duplicate startup. Purchase observation is set up first, then independent tasks load feature data. RootView does not trigger startup, and the test host skips the production graph.

`applicationDidFinishLaunching()` does not own or interpret the result of those loads. Each feature manager owns its idle, loading, loaded, empty, or failed state. A ViewModel exposes that state when its screen appears, and the screen offers retry when recovery is possible. Launch simply gives independent features a head start while the user is looking at the first screen.

Presentation remains local to the presenting View. Today logs new measurements directly and presents no editor sheet. History stores the selected entry for its edit sheet, and the editor receives that plain domain value. No View receives AppModel, a ViewModel, or a navigation closure.

### Feature Manager

- Owns one coherent application capability and its asynchronous workflows.
- May coordinate lower-level managers needed to complete that feature, while hiding those collaborators from its callers.
- Runs on `@MainActor` when it publishes UI-observable state.
- Uses `@Observable` for UI-readable feature state, allowing SwiftUI to track only the properties a View actually reads.
- Publishes persisted state only after persistence succeeds.
- Owns feature-specific rules such as permitted entry dates and semantic progress classifications.

### Repository and storage implementation

- A repository contract describes storage in domain language.
- Implementations isolate files, CloudKit, HTTP, or other external systems.
- Actor isolation protects mutable storage and makes concurrency boundaries explicit.

## Example: saving a weight

```text
TodayView
  → TodayViewModel.save()
    → WeightEntryManager.checkIn(_:)
      → WeightLogManager.add/update
        → WeightRepository.save
          → CloudKitWeightRepository
            ├── FileWeightRepository (offline cache)
            └── private CloudKit database
      → ProgressTracker.refresh
```

The View decides how saving looks. The ViewModel owns editor state. `WeightEntryManager` coordinates the complete feature workflow. `WeightLogManager` owns the canonical log, and the repository owns storage.

`WeightEntryManager` creates drafts using its injected clock and rejects future-dated entries before they reach storage. A ViewModel exposes the permitted date boundary for its DatePicker; the View only renders that boundary. Tests replace the live clock with a fixed date, keeping time-dependent behavior deterministic.

## Testing

`TrendTests` has two visible branches that match the architectural boundary:

- `View model tests` contains one intent-focused suite for every ViewModel.
- `AppModel tests` contains coordination, feature-manager, and domain-calculation suites. Its `Test Support` folder keeps shared testing tools, such as the in-memory repository and AppModel factory, together and clearly separated from the application code.

Every ViewModel has a dedicated suite named after it. Those tests describe presentation behavior at the ViewModel boundary: initial state, derived display data, user intent callbacks, successful workflows, validation, and recoverable failures. The shared `TestAppModelFactory` assembles the real AppModel and feature managers around an `InMemoryWeightRepository`, keeping tests realistic without reaching CloudKit.

The lower layers retain focused tests for chart preparation, canonical unit persistence, feature coordination, and AppModel construction. Future integration passes can deepen CloudKit conflict resolution and security-scoped file importing; those operating-system boundaries are deliberately kept out of ViewModel unit tests.

### Habits: observable manager and worker actor

`HabitsManager` stores one observable `HabitData` containing the selected habit IDs
and recorded entries. Its public `habits` and `entries` getters read that store;
they do not keep separate copies. Prepared weekly and lifetime summaries remain
calculated results.
Its private `HabitsWorker` actor validates commands, saves and loads data, and
calculates those results. ViewModels retain the manager; they never access the worker.
The worker keeps no persistent copy of the manager's state. Named worker methods load, record, or remove entries directly; there is no action dispatcher. Recording methods return the saved entry after the manager publishes the completed result.

Habit operations wait their turn through persistence and publication, so concurrent
recordings cannot overwrite each other. A failed save leaves the previous results
intact. Cancellation is checked before work starts; a successfully saved result is
published even if cancellation arrives during the save. Calendar-day and foreground
callbacks recalculate dated results without loading storage. This is the first
feature using the pattern; the other features have not yet been migrated.

Today renders its form and a fixed-size empty streak bar immediately. Saving and automatic keyboard focus wait for local weight data and derived values to be ready. Cloud synchronization follows local preparation without replacing the screen with a loading indicator.


### Habit storage and iCloud

Local loading and saving never wait for iCloud. `HabitsManager.load()` reads saved
habits once at launch and allows retry after a failed load. `synchronize()` checks
iCloud when the app becomes active, loading local data first if needed. Screens
observe the manager and do not reload it on appearance. Calendar changes call
`updateCurrentDay()` without a file reload or network request. Recording an entry can
complete while synchronization is waiting for the network. Local changes still take turns
because they modify the same file. This is a habit-storage rule, not an app-wide queue.

`FileHabitDataStore` writes the current entries and the last synchronized store
in one atomic JSON write. The stored comparison version identifies pending edits
and deletions; it is storage information, not another observable feature manager.
There is no separate pending-upload marker to fail after an otherwise successful save.
The app is unreleased. Use the current JSON format without compatibility code for
earlier development versions.

`CloudKitHabitClient` merges changes to different habits and days. A pending local
edit or deletion wins when both devices changed the same habit/day; counts are not
added together. It uses CloudKit's record-change check and retries a conflicting
save at most three times. Other failures leave local data available and set the
manager's `synchronizationError`; a later synchronization request or edit retries iCloud.

An upload can finish after another local edit. The file repository preserves that
new edit when accepting the uploaded result. Likewise, saving a manager's older
copy applies only its changes to the latest file, preserving downloaded entries.
Tests exercise these overlaps with a paused cloud client and real temporary files.
Live CloudKit behavior still needs verification using two signed-in devices.
