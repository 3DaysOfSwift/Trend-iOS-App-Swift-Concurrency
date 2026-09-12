---
name: swift-concurrency-overview
description: Read a Swift repository and create rendered visual overviews of its tasks, structured child tasks, actor isolation, suspension points, cancellation, and operation ordering. Use when a developer asks to understand or diagram Swift Concurrency behaviour across an app or through a particular workflow. Analysis is read-only; this skill does not migrate or refactor the application.
metadata:
  short-description: Visualise Swift tasks and their full journeys
---

# Swift Concurrency Overview

Make concurrent behaviour understandable without requiring the reader to decode
source code or a dense sequence diagram. Start with the developer's requested
scope: an app-wide task map or a detailed journey through one operation.
Use plain-English actions, with source symbols available as secondary detail.

## Read the Actual Code

- Respect repository instructions. Identify production targets, generated code,
  tests, and the current revision or dirty working-tree state before scanning.
- Find task creation with source search, then inspect each match and its callers.
  Include `Task {}`, explicit Task initializers, detached tasks, `async let`, task
  groups, SwiftUI `.task`, `.task(id:)`, and `.refreshable` as applicable. Inspect
  wrappers too; text matches alone are not a complete inventory.
- Distinguish creation sites from runtime instances. A button's one creation
  site can create many tasks. Report the scope of counts and list framework-owned
  entry points separately rather than inventing their internal task trees.
- Trace implementations through protocols and live dependency wiring. Mark
  unresolved dynamic dispatch or external SDK internals as unknown boundaries.
  Do not infer a network call from a type name such as CloudKit storage.
- Record each task's trigger, handle owner, isolation, calls, waits, state
  changes, completion, error handling, cancellation and repeated-request policy.
  Read relevant tests for intended ordering, but distinguish tested behaviour
  from observed runtime evidence.

## Preserve Concurrency Meaning

- An ordinary awaited async function runs as part of its calling task. `await`
  marks a potential suspension; it does not itself create a task or block a
  thread. Actor hops do not create tasks either.
- `async let` and task-group children are structured child tasks. `Task {}` and
  `Task.detached {}` create unstructured tasks, even when created inside another
  task. Creation and awaiting a handle do not establish structured parenthood.
- Separate handle ownership, task lifetime, actor isolation and physical threads.
  Do not draw a dedicated thread for every actor or claim each resumed segment
  returns to the same thread. Check language settings and annotations when
  determining async-function isolation; mark uncertainty instead of guessing.
- Cancellation is cooperative. Show who requests it, where it is checked, and
  what happens afterward. A dropped handle or an awaited unstructured task does
  not imply cancellation propagation. Distinguish SwiftUI lifecycle cancellation
  from a Task created by a button.
- Actor isolation serialises isolated execution segments, not necessarily an
  entire operation across awaits. Show real gates, continuation queues, shared
  tasks, task chains, generations or stale-result checks when present. Verify
  exactly when a gate is acquired and released, including failure paths.
- Do not claim FIFO scheduling, parallel execution, exact timings or a particular
  interleaving from static code alone. Label illustrative schedules accordingly.
- Distinguish synchronous file/CPU work from suspension. Distinguish a local save
  finishing from a separate upload finishing. Do not recommend a queue for every
  save: explain the actual ordering contract and mechanism found in the code.

## Choose a Useful Diagram

For an app-wide request, group task creation sites by recognisable feature and
trigger. Show creation edges, structured-child edges, and await/join relationships
with distinct labels. Keep a source-linked inventory alongside the overview when
the full list would overwhelm the picture.

For a workflow, read [Journey diagrams](references/journey-diagrams.md) and trace
the complete path before drawing it. Prefer a small number of task lanes with
plain-English steps. Keep the same task identity as it crosses actor boundaries.
Show alternative paths separately or on demand rather than making the primary
journey unreadable.

Deliver a rendered visual, not just its source. Mermaid is suitable only when
the delivery surface actually renders it. If it appears as code, use a rendered
image or a self-contained interactive visual instead. When an available
visualization skill applies, follow its rendering and accessibility instructions.
The workflow must also work without that skill: use available rendering tools
and provide the resulting viewable output.

## Verify and Hand Off

When using Swift Architecture Explorer, read its `OBSERVATIONS.md` format before
writing journey notes. Generate an inventory first; bind notes to its exact
source fingerprint and creation-site IDs, then import with `--observations`.
Keep steps source-linked and list uninspected paths explicitly. Coverage counts
sites with notes, not fully verified tasks. Do not add quality rankings or scores
to this observational dashboard. If the Explorer is unavailable, still deliver
the requested visual and source inventory without claiming an imported report.

- Cross-check task boundaries, gates and completion ordering against source.
  Include paths and line references in the accompanying inventory or explanation.
- Label the diagram as source-derived, illustrative, or runtime-observed. Never
  portray an illustrative animation as a profiler recording.
- Inspect the rendered result for readable text, unclipped labels and usable
  narrow-screen layout. Exercise step controls and alternate states if included.
- State unresolved boundaries and separate potential defects from established
  behaviour. Do not change app code or claim the diagram proves race freedom.
- Keep generated outputs outside app source. Do not collect runtime traces,
  publish diagrams or commit changes unless requested. If observation is needed
  to settle a question, explain the smallest relevant diagnostic next step.

The [Trend Load Habits example](references/trend-load-habits.md) explains the
starting example for this skill. Read it when adapting its included visual asset;
it illustrates the method, not a required architecture for other repositories.
