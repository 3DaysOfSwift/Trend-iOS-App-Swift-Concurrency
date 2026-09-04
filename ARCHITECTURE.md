# Architecture

## Visual map

```text
┌──────────────────────── View ─────────────────────────┐
│ SwiftUI View → tightly coupled ViewModel              │
└──────────────────────────┬─────────────────────────────┘
                           │ user intent
                           ▼
┌────────────────────── AppBrain ────────────────────────┐
│ AppBrain assembles Feature Managers                   │
│ ViewModel → Feature API → Feature Manager             │
│                              │                         │
│                              ▼                         │
│                    Repository Contract                │
│                                      │                 │
│                                      ▼                 │
│                            Storage Implementation      │
└────────────────────────────────────────────────────────┘
```

## Folder map

```text
Trend
├── 1 - View
│   ├── Root
│   │   ├── RootView.swift
│   │   └── RootViewModel.swift
│   ├── Today
│   │   ├── TodayView.swift
│   │   └── TodayViewModel.swift
│   ├── EntryEditor
│   ├── Progress
│   ├── History
│   └── Settings
├── 2 - AppBrain
│   ├── AppBrain.swift
│   ├── Features
│   │   ├── WeightLog
│   │   ├── Progress
│   │   └── Settings
│   └── User Data Storage
│       ├── Data Types
│       │   ├── WeightEntry
│       │   ├── WeightEntryDraft
│       │   └── WeightUnit
│       ├── Protocols
│       ├── Local
│       └── CloudKit
└── 3 - App Resources
```

The numeric prefixes make the intended reading order explicit in Xcode: presentation first, application behavior second, and supporting app resources last.

There is no generic `Networking` folder because Trend has no HTTP API. CloudKit is a storage implementation and is named accordingly. Add a networking layer only when a real feature requires one.

## Responsibilities

### View

- Renders values supplied by its ViewModel.
- Creates and owns its `@Observable` ViewModel with `@State`, so the model's lifetime follows the screen's lifetime.
- Uses a local `@Bindable` projection only where a SwiftUI control needs a writable binding.
- Owns any sheet or dialog it presents using local SwiftUI state.
- Accepts no service, ViewModel, or callback inputs. A destination may accept the plain data it renders or edits, such as `EntryEditorView(entry:)`.
- Owns ephemeral visual state such as the selected chart point or keyboard focus.
- Contains no repository access and coordinates no feature managers.

### ViewModel

- Is named after and stored beside one View.
- Uses the Observation framework's `@Observable` macro; stored properties need no `@Published` annotation.
- Converts feature state into values convenient for that View.
- Receives user intent and forwards it to its retained feature capability.
- Retains one narrow feature capability, such as `TodayFeature` or `HistoryFeature`, rather than AppBrain itself.
- Defaults that capability to the matching feature supplied by `AppBrain.shared`, allowing production Views to construct it without dependency plumbing.
- Keeps the feature initializer parameter available so tests can substitute an isolated capability.
- Contains presentation validation and file-picker state when those concerns are specific to its View.
- Does not persist data or call another ViewModel.
- Is never cached by RootViewModel or another ViewModel.

### AppBrain

- Is the composition root exposed as the single production instance `AppBrain.shared`.
- Constructs feature managers and supplies their narrow APIs to ViewModels.
- Stores one `WeightEntryFeature` instance shared by Today, Entry Editor, and History, making it impossible to assemble those screens over inconsistent weight state.
- Keeps feature-specific workflows in their managers. Its sole application-wide workflow is `start()`, which initializes the shared graph once.
- Has a fully explicit initializer: every dependency is required and no production implementation is silently created there.
- Confines production construction policy to `live()`; test construction policy lives in `TestAppBrainFactory`.
- Wires production feature managers to production repositories.
- Contains no SwiftUI layout code.

AppBrain and its feature managers are app-scoped; ViewModels are view-scoped. Removing a View releases its ViewModel, while shared feature state remains available through the feature manager retained by AppBrain. Production ViewModels select one capability from `AppBrain.shared` through a defaulted initializer parameter; tests inject the same narrow capability from an isolated application graph.

Presentation remains local to the presenting View. Today logs new measurements directly and presents no editor sheet. History stores the selected entry for its edit sheet, and the editor receives that plain domain value. No View receives AppBrain, a ViewModel, or a navigation closure.

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
- `AppBrain tests` contains coordination, feature-manager, and domain-calculation suites. Its `Test Support` folder contains the shared in-memory repository and AppBrain factory, so production builds never ship test doubles.

Every ViewModel has a dedicated suite named after it. Those tests describe presentation behavior at the ViewModel boundary: initial state, derived display data, user intent callbacks, successful workflows, validation, and recoverable failures. The shared `TestAppBrainFactory` assembles the real AppBrain and feature managers around an `InMemoryWeightRepository`, keeping tests realistic without reaching CloudKit.

The lower layers retain focused tests for chart preparation, canonical unit persistence, feature coordination, and AppBrain construction. Future integration passes can deepen CloudKit conflict resolution and security-scoped file importing; those operating-system boundaries are deliberately kept out of ViewModel unit tests.
