# Example: Trend — Load Habits

This source-derived example was traced on 13 September 2026 from a working tree
with uncommitted changes. It is not a runtime recording or a permanent assertion
about future Trend versions. Re-read the repository before reusing its claims.

## Evidence to Revisit

Paths below are relative to the Trend repository, not this skill directory:

- `Trend/2 - AppModel/AppModel.swift`: application launch creates a task calling
  `habitsFeature.load()`.
- `Trend/2 - AppModel/Features/Habits/HabitsManager.swift`: `load()`,
  `loadLocalData()`, `waitForPreviousOperation()`, `finishOperation()` and
  `publishSuccessfulResult(_:)`.
- `Trend/2 - AppModel/Features/Habits/HabitsWorker.swift`: `load(on:)` and
  `calculateSummaries(_:on:)`.
- `Trend/2 - AppModel/User Data Storage/CloudKit/CloudKitHabitDataStore.swift`:
  `load()` delegates to the local cache, not the network.
- `Trend/2 - AppModel/User Data Storage/Local/FileHabitDataStore.swift`:
  `load()` and `readDocument()` read and decode the local JSON document.

## What the Journey Shows

Task A is the unstructured launch request. On a first load, HabitsManager creates
and retains unstructured Task B, then A awaits B's value. B takes the manager's
local operation gate, waiting in a FIFO continuation list only if needed. After
acquiring the gate, B sets loading state and captures the date. The same B calls
the worker, storage wrapper and file actor; none of these calls creates a child.
The file actor synchronously reads and decodes local data, or returns empty data
if no file exists. The worker calculates daily, weekly, streak and lifetime
summaries. B returns to MainActor, publishes data and ready state, releases the
gate, clears its handle and completes. A can then resume and finish.

Repeated callers await the existing B. A ready manager can return immediately.
Read errors become observable failed state rather than escaping `load()`.
A caught CancellationError restores the previous load state. Cleanup still runs.
Cancelling A does not automatically cancel B. Cloud synchronization is separate.

## Included Visual

[Load Habits journey](../assets/load-habits-journey.html) is the compact two-lane
interactive example approved by the user. It highlights seven steps, keeping
A's waiting period aligned with B's work. It intentionally groups intermediate
actor hops rather than displaying a column for every type.

The asset is an HTML fragment for a host providing visualization styles and
theme variables; it is not a standalone website. Adapt its labels and stages to
fresh source evidence. Use the available visualization renderer, or supply a
standalone wrapper/styles when exporting elsewhere. Never copy Trend's task
count, ownership or local-only loading assumptions into an unrelated app.
