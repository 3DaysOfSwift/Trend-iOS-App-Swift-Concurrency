# Concurrency Warnings

## Trace the operation, not just the Task keyword

For each SwiftUI `.task`, `.task(id:)`, refresh action and event-created Task,
follow the complete live call path through the ViewModel, feature and integration.
Inspect synchronous helpers as well as async calls. A function named load may
write defaults, delete corrupt data or trigger an upload. Resolve the actual
repository implementation before deciding that an operation is read-only.
Record each path in the analysis ledger and import `concurrencyChecks` using the
dashboard tool's Documentation/REVIEWS.md schema. The lexical scanner cannot
resolve these paths; the reviewing AI must read them. Unresolved owned code blocks
completion, not merely a warning-free score.

For each operation, record source evidence for the trigger, every intervening
layer and the terminal effect, together with:

- **Trigger:** Button action, View appearance, changing `.task(id:)` value or
  another event. Determine actual View identity and ID dependencies.
- **Navigation:** who requests cancellation when the View leaves its lifetime;
  which downstream work remains in that Task and which independent workers live on.
- **Repeated requests:** trace two requests arriving before completion. Check
  guards before the first suspension, input capture, shared-operation joins,
  serialization, coalescing, cancellation/replacement and stale-result checks.
  A disabled button alone is not proof of model-level protection.
- **Waiting/cancellation:** track explicit awaits, structured children, independent
  Task handles, cancellation handlers/checks and error handling. Do not assume an
  awaited handle forwards cancellation. Do not assume cancel immediately finishes
  the old Task; replacement can overlap while cancellation is being handled.
- **Effects:** identify the write/request and commit boundary, partial changes,
  retry semantics, server idempotency where available, and who reports completion
  or failure after navigation. Cancellation is not rollback or proof that a server
  did not accept a request. Persistence completion is not necessarily disk flush.
- **Verification:** cite relevant assertions or explicitly say source inspection
  only and describe a focused regression scenario. Do not invent test execution.

## Apply the correct lifecycle rules

- A synchronous Button callback does not supply a Task. A `Task {}` bridge is a
  valid entry point. Another press does not automatically cancel it; it may create
  another Task unless application code prevents that.
- SwiftUI `.task` supplies framework-managed async execution and requests
  cancellation as its View leaves its lifetime. Reappearance may start it again.
- SwiftUI `.task(id:)` additionally cancels/restarts when its ID changes. A redraw
  with unchanged identity/ID is not itself a restart. A Button can change that ID;
  inspect the actual binding rather than assuming every Button restarts work.
- Direct async calls continue in the calling Task. Unstructured Tasks inside that
  path have independent lifetimes; the creator does not automatically wait or
  propagate cancellation. Explicit waiting can exist without cancellation forwarding.
- Properly owned independent operations can intentionally outlive a caller, for
  example a shared load or committed save. A retained handle alone proves neither
  correctness nor a defect. Inspect duplicate policy, errors and completion too.

## Report outcomes clearly

Group operation reviews under **Concurrency Warnings** with separate counts for:

- **Warning:** cite an actual risky path and explain its consequence. If product
  intent or runtime behaviour is needed to confirm a defect, say so precisely.
- **Managed operation:** the traced path has an explicit appropriate policy for
  the reviewed scenario. Describe that protection; do not claim global race freedom.
- **Unresolved check:** state the missing implementation or evidence. Never count
  this as safe or turn an incomplete set into a whole-project safety rating.

Use clear titles such as “Could leaving this screen interrupt a save?” and
“Can repeated presses submit the request twice?”. Show highlighted source first,
then the call path, navigation/repetition behaviour, result and verification.
Do not display a blanket orange warning merely because a Task is unstructured.
Keep source classification counts separate from reviewed operation outcomes.

References: [SwiftUI task lifecycle](https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:))
and [Swift concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).
