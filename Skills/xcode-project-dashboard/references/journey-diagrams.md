# Journey Diagrams

## Trace Before Drawing

For each meaningful stage, collect this small evidence record (an internal working
note is sufficient; do not create another document unless useful to the user):

- Task identity and creation site; structured parent only if one actually exists.
- Action in ordinary English, source symbol, file and line.
- Actor/isolation at that stage, or an explicitly unknown executor boundary.
- Entry condition, data read or changed, and possible suspension.
- Success, failure and cancellation exits; effects on shared state and waiting callers.

Follow the workflow to its actual completion. For example, does "saved" mean
local persistence, cloud acknowledgement, or just an optimistic UI update?
Follow cleanup too: releasing a gate and clearing a task handle matter to the
next request. Identify the state the screen observes without inventing a new
task for SwiftUI drawing.

## Visual Grammar

- Give each task a persistent identity, such as A and B, with a short role name.
  Use colour plus labels, not colour alone.
- Use aligned lanes and a shared sequence direction. With two tasks, a vertical
  journey often reads better than a wide diagram full of class names.
- Label creation arrows "creates"; label structured relationships "child";
  label completion dependencies "awaits". These relationships are not synonyms.
- Put actor/location names underneath the action, not in place of it. More
  actors do not mean more task lanes.
- Depict waiting as a quiet interval. Explain whether it is awaiting another
  task, awaiting an actor call, or queued behind an explicit operation gate.
- A schematic wait interval shows dependency, not measured duration. Distinguish
  a possible suspension from a known wait in the selected illustrative scenario.
- Start with the primary journey. Cover already-loaded, duplicate-call, failure
  and cancellation paths in concise notes or selectable detail as needed.
- For an interactive walkthrough, keep the full journey visible and highlight
  one stage at a time. Previous/Next controls and one selected-stage explanation
  are usually enough. No autoplay is necessary. Respect reduced motion if animated.

## Validate the Meaning

Use these contrasting cases when checking the diagram:

- `await repository.load()` introduces a call and potential suspension, not a child.
- `async let data = repository.load()` introduces a structured child.
- `Task { await repository.load() }` introduces an unstructured task regardless
  of whether its creator is already executing inside another task.
- Two callers awaiting one stored task are two waiters, not two duplicate loads.
- A manager awaiting an actor can be reentered by other work unless its own
  operation policy prevents it. The whole operation is not automatically atomic.
- Synchronous disk reading may run between suspension points; do not animate it
  as though the task has suspended for the duration of the read.

The final picture should let the reader answer: what triggered this, who owns
the work, where can it pause, what may interleave, what state changes, and what
actually counts as finished?
