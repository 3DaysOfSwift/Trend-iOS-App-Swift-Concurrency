# Legacy Application Migration

Use several deliberate passes. Do not combine architectural restructuring and
concurrency conversion into one rewrite. Preserve existing behaviour from the
original starting point.

## Migration as an Opportunity to Renew

A migration begins with a technical objective, but examining an existing
application often reveals unclear responsibilities, defects, missing error
handling, and unnecessary complexity. Treat these discoveries as opportunities—not
as changes to conceal under the word “migration.” Preserve intentional behaviour,
document proposed improvements, and agree on their scope. The same disciplined
process can support either a focused migration or a deliberate renewal of the
application.

## Preserve Existing Product Behaviour

Architecture migration changes the organisation and implementation of the
application; it must not silently redesign the product. Treat existing
observable behaviour as the default contract throughout every pass. Any
difference must be detected, classified, and either corrected or explicitly
approved as an intentional product change.

Before changing production code, create a project-local
`MIGRATION_BEHAVIOUR_CONTRACT.md`. Translate the evidence in the live codebase
into plain-English behavioural requirements and map each requirement to its
legacy evidence, replacement protection, and manual regression result. Follow
[Product Behaviour Contract](product-behaviour-contract.md) when constructing
and maintaining this document.

The contract is a practical change detector, not a claim that a test suite can
prove perfect equivalence. Existing tests may be incomplete, incorrect, or too
closely coupled to implementation. Automated comparison must therefore be
combined with focused characterisation tests, investigation of every detected
difference, and mandatory manual regression testing after the architectural
milestone and the completed concurrency migration. The objective is to make
every broken behaviour visible, traceable, and resolvable.

## Before Pass One

Build the existing application and run its tests. Record current targets,
storage behaviour, external integrations, observable user flows, and failures.
Add focused characterisation tests where important behaviour has no protection.
Do not begin by redesigning working behaviour.

Create a migration ledger and keep it current throughout every pass. For each
item being moved, record:

- its original owner and responsibility;
- its current transitional owner;
- its intended final owner;
- the reason it has not reached that owner; and
- the pass that must resolve it.

After every pass, the application must build, all previously passing tests must
still pass, and every affected requirement in the behaviour contract must have
current evidence. Observable product behaviour must remain unchanged unless an
authorised decision recorded in the contract changes it. Unknown differences
and regressions block the next pass. Do not begin the next pass until its
specific completion gate is also satisfied.

## Pass One: Give Every Screen Its Own ViewModel

Create one custom, tightly coupled ViewModel for every unique screen View. Name
the View's stored property `viewModel` and place the two files together.

Move existing ViewModel code into the correct screen ViewModel. Move imperative
state handling out of SwiftUI Views without attempting to perfect the final
Model architecture yet. Suspected business rules may be staged temporarily in
the new ViewModel, but record every one in the migration ledger for extraction
into a Feature Manager during Pass Three. Never present this temporary placement
as the completed UI and Model boundary.

**Completion gate:** every screen has one clear backing object, no ViewModel is
shared between unique screens, no code was duplicated to create the new
boundaries, affected ViewModels can be tested independently, and every business
rule temporarily staged in a ViewModel appears in the migration ledger.

## Pass Two: Introduce AppBrain as a Transitional Shared Store

Add `AppBrain.shared` as the single production composition root. Initially it
may act as a deliberately untidy staging area for shared Model objects and
behaviour discovered during migration. This is temporary and must be stated in
the migration plan; it is not the completed architecture.

Record every object and behaviour staged in AppBrain in the migration ledger,
including its intended Feature Manager and the pass in which it will move.

Connect each ViewModel to the required capability through a default initializer
value supplied by `AppBrain.shared`. Do not pass AppBrain, services, ViewModels,
or behavioural closures through View initializers. Do not move navigation or
screen presentation state into AppBrain.

**Completion gate:** every screen that requires Model capabilities reaches them
through the single AppBrain graph, AppBrain contains no UI or navigation state,
and every transitional AppBrain responsibility has a named final owner in the
ledger.

## Pass Three: Extract Feature Managers

Identify each cohesive application capability that owns state, business rules,
or a meaningful workflow and create one Feature Manager for it. Do not create a
manager merely for every noun or control visible in the UI. Connect each
ViewModel to the narrow feature capability it uses.

Move business rules from Views, ViewModels, legacy managers, and the temporary
AppBrain staging area into the Feature Manager that owns the feature. Move
storage and device interactions behind repository contracts. Preserve one
authoritative state owner and add focused tests for every extracted rule.

Do not split one feature through several managers unless each additional type
has a concrete responsibility whose maintenance benefit outweighs its cost.

**Completion gate:** no known business rule remains in a View, ViewModel, or
temporary AppBrain staging area; every feature has one understandable public
capability; shared state has one authoritative owner; repositories contain no
application decisions; and extracted rules have focused tests.

## Pass Four: Tidy the Architecture

Repeat focused evaluation passes over AppBrain, Feature Managers, ViewModels,
repositories, and folders. Remove transitional code, duplicate state, deep
access chains, vague types, and misplaced responsibilities. AppBrain should end
as an elegant composition root and feature facade rather than a dumping ground.

Compare the result against every item in the canonical AppBrain Review
Checklist. Build the application and run the complete relevant test suite after
each material extraction.

**Completion gate:** the canonical AppBrain Review Checklist passes, the
migration ledger contains no unresolved architectural staging item, the folder
structure reflects actual ownership, and the complete relevant test suite
passes. When this gate is satisfied, recommend a Git milestone commit. Create
that commit only when the developer has authorised it.

## Pass Five: Migrate the Model from GCD to Swift Concurrency

Begin concurrency migration below the View layer. Ignore SwiftUI integration
until the Model exposes useful, directly testable asynchronous functions.

Inventory every queue, group, barrier, semaphore, callback, delegate, and
operation. For each one, determine:

- which work must begin concurrently;
- which work must remain ordered;
- which mutable state the original queue protects;
- whether work is durable, replaceable, cancellable, or long-lived;
- which caller needs the result and on which actor state is published; and
- how errors and cancellation currently behave.

Maintain a concurrency inventory alongside the migration ledger. For every
legacy primitive, record the guarantee it currently provides, its intended
Swift Concurrency replacement, and the test or observation that proves the
guarantee was preserved.

Replace behaviour, not syntax. Do not mechanically translate `DispatchQueue`
calls into `Task`, actors, continuations, `async let`, or task groups. Preserve
the ordering, lifetime, isolation, and concurrency guarantees required by the
product. Keep feature commands as `async` functions that tests can call and
await directly.

When adapting callback APIs, use a checked continuation only when an async API
is not already available. Prove that every execution path resumes the
continuation exactly once, including success, failure, cancellation, and early
exit paths. A continuation is a bridge to an existing callback lifetime; it
must not invent different cancellation or ordering behaviour.

**Completion gate:** Model and Feature Manager tests prove the migrated
implementation independently of SwiftUI; every legacy primitive is resolved in
the concurrency inventory; required ordering and parallelism are preserved;
mutable state has explicit isolation; errors remain visible; and cancellation
cannot publish stale results.

## Pass Six: Connect Swift Concurrency to ViewModels and Views

Adopt the migrated async feature APIs in each ViewModel. Let a View create an
unretained `Task` only to bridge a synchronous UI event into an async ViewModel
method. If a Task must be tracked, cancelled, replaced, deduplicated, or
inspected, store it in that screen's ViewModel—never in the SwiftUI View.

Expose loading, success, empty, partial, and failed feature states honestly.
Ensure retry is a real user flow. Verify that durable work continues when its
screen disappears and replaceable work cannot publish stale results.

**Completion gate:** every async user journey exposes honest observable state;
no SwiftUI View stores a Task handle; managed Tasks have an explicit owner and
lifetime; durable and replaceable operations behave as documented; UI and
ViewModel tests pass; and the complete application test suite remains green.

## Pass Seven: Every Model-layer File Should Have an Identifiable Feature Owner

Review every Model-layer file against the features that actually use it. Place
feature-specific domain types, repository contracts, storage implementations,
audio adapters, and timing collaborators beneath their owning feature folder.
Technical categories may remain as subfolders within that feature.

Folder ownership does not merge responsibilities: a repository still owns
storage, and AppBrain.live() still constructs the production dependencies.
AppBrain itself remains the application-wide composition root. A genuinely
shared collaborator may remain outside one feature, but document its actual
consumers and responsibility. Potential future reuse is not a reason to remove
a file from its current feature owner. UI types and resources retain their
own layer ownership.

Move files without changing behaviour. Update Xcode references and folder maps,
verify target membership, and keep a reviewable Git checkpoint.

**Completion gate:** every Model-layer file has a feature owner or an explained
application-wide/shared responsibility; feature-specific files live beneath
that feature; no responsibilities or implementations were duplicated; and
the application builds and its relevant tests pass after the moves.

## Pass Eight: Refine Test-grouping Folders and Plan Further Refinement Iterations

Group tests by the responsibility they verify, reflecting the new architecture.
Keep AppBrain construction and application-wide coordination tests separate
from feature-manager tests, repository tests, and screen ViewModel tests.
Split mixed suites so each ViewModel has its own focused suite. Place test
doubles beside their consuming tests when local, or in clearly named shared
test support when genuinely reused. Do not duplicate test doubles to satisfy
a folder pattern.

Preserve assertions, coverage, and test-target membership during regrouping.
Update test references in the behaviour contract and migration ledger.

Use the newly visible boundaries to plan further small refinement iterations.
For each concrete finding, record its owner, maintenance benefit, behaviour
risk, and verification needed. Separate organisational edits from behaviour
changes; agree on intentional product changes before implementing them.
Do not invent additional iterations merely to prolong the migration.

**Completion gate:** test names and folders reveal the tested responsibility,
no tests or assertions were lost, the suite passes, and remaining refinements
are explicitly scoped in the ledger—or the review records that none are needed.

## Pass Nine: Evaluate Cooperative Execution and Responsiveness

Evaluate whether the application genuinely uses Swift Concurrency to remain
responsive—not merely whether GCD syntax has disappeared. Trace important
execution paths from user intent through the feature and its dependencies.
Record actor isolation, synchronous work, suspension points, task ownership,
and the executor on which work resumes. A Task is not automatically background
execution, and an async function does not guarantee that expensive work leaves
the Main Actor.

Review startup, persistence, parsing, device setup, animation, and repeated
calculations for blocking calls or excessive Main Actor work. Profile realistic
workloads on representative devices; distinguish potential risks found in code
from measured delays. Use the findings to choose explicit execution ownership,
appropriate asynchronous APIs, or caching. Moving a blocking call into an actor
or detached Task alone does not make it cooperative; respect external API
execution requirements and avoid blocking cooperative-pool threads.

Review Task cancellation, replacement, retention, priority, and stale-result
prevention. Keep short synchronous operations synchronous. Use structured
concurrency when independent child operations belong to one workflow; do not
manufacture parallelism. Use suspending waits instead of blocking sleeps.
Task.yield() is an optional opportunity for other work to run, not a guarantee
of fairness or a substitute for moving expensive work off the UI executor.
Do not add Task, async, await, or yield solely for demonstration.

Verify complete concurrency checking for the selected language mode and targets.
Resolve findings without weakening required behaviour or silencing diagnostics
through unjustified unchecked annotations. Complement deterministic test doubles
with tests of real task lifetimes and focused runtime measurements. For
timing-sensitive features, compare cadence, cancellation, and missed-deadline
behaviour under load; cooperative scheduling is not a real-time guarantee.

Record compiler settings, tested build and device, workloads, measurements,
remaining risks, and proposed improvements in the migration ledger. Implement
agreed refinements in bounded iterations and repeat affected regression tests.

**Completion gate:** execution ownership and meaningful suspension points are
understood; concurrency diagnostics are resolved; task lifetimes are verified;
and representative runtime evidence supports the application's responsiveness
and timing requirements. Missing profiling or device access remains an explicit
verification gap—not a claim that the app never blocks the main thread.

## Pass Ten: Give Expensive Feature Work Off-Main Execution Ownership

Use the findings from Pass Nine to improve execution, in small, verified
checkpoints. The objective is responsive UI and dependable feature behaviour,
not using every CPU core or making every function asynchronous. Preserve the
feature boundaries: the ViewModel asks its feature for work; the feature owns
the rules and coordinates its execution dependencies.

1. Enable complete concurrency checking in Debug and Release for the app and
   test targets. Resolve diagnostics before introducing new isolation boundaries;
   do not silence them with unjustified unchecked Sendable conformances.
2. Profile cold startup, animation, and playback together. Record the device,
   build, workload, Main Actor activity, and timing results before and after
   changes. Include first use, missing resources, and persistence failures.
3. Give audio preparation and persistence explicit execution owners outside the
   Main Actor, respecting the underlying APIs. Expose async operations when
   callers must await completion or failure. Keep small UI-observed state updates
   on the Main Actor; move expensive computation and device or storage work out
   of that execution path. An actor provides isolation, not a dedicated thread.
   Use native asynchronous I/O where available; isolate unavoidable blocking
   APIs on a suitable executor rather than blocking the cooperative pool.
4. Cache reusable generated resources, such as fallback audio, in their owning
   implementation. Prepare them once and reuse them instead of regenerating
   them in frequently executed paths. Verify both normal and fallback behaviour.
5. Test the real ticker's cancellation, replacement, and missed deadlines,
   alongside deterministic feature tests. Establish the intended late-tick
   policy explicitly; do not silently change rhythm or introduce catch-up bursts.

At each new await boundary, protect operation ordering and state: a cancelled
start must not later restart playback, an older result must not replace newer
state, and overlapping saves must not lose the latest edits. Transfer safe value
snapshots across isolation boundaries; keep mutable device objects with their
execution owner. Preserve visible loading, failure, and retry states. Independent
startup loads should remain independent rather than becoming accidentally serial.

Choose parallel computation only where independent work warrants it. Let the
runtime schedule CPU cores; do not create one actor per core or move trivial
state changes off-main merely to demonstrate concurrency. Check the project's
language mode and isolation settings instead of assuming that async or Task
means off-main execution.

**Completion gate:** strict checks and regression tests pass; expensive feature
paths have verified execution ownership; caching and real task-lifetime tests
cover the changed paths; and before/after profiling supports responsiveness under
combined load. Record any unavailable measurements as pending. This pass is not
complete merely because methods now contain async and await.

## Repeat the Completion Audit

After every pass, ask:

> Evaluate the current architecture of the project against the AppBrain iOS
> Application Template. Do you consider this migration complete? Identify every
> accepted temporary violation, newly introduced violation, resolved violation,
> remaining blocker, duplicated responsibility, behavioural risk, and untested
> concurrency guarantee. State the evidence for every conclusion.

The migration is complete only when the answer is supported by the folder
structure, source ownership, observable behaviour, and passing tests—not merely
because all files compile or all GCD syntax has disappeared. It also requires no
unknown behavioural differences, a passing regression suite, and recorded
manual regression approval.

## After Migration Completion: Write the Feature Behaviour Report

Once the completion audit confirms that the migration has officially finished,
create a project-local `MIGRATION_FEATURE_REPORT.md`. This is the final handover
step, not another implementation pass. Explain the resulting application in
plain English so developers, reviewers, and students can understand what each
feature does and how its work executes without reconstructing the migration
history.

Give each feature its own heading and name its owning Feature Manager. Describe:

- **Behaviour:** the actions it supports and their observable results, including
  behaviour preserved from the original app and any explicitly approved changes.
- **Execution ownership:** which operations run on the Main Actor, which run on
  another executor, and where callers await results. Name the actual operation
  and owner rather than describing an entire feature as “background” when only
  part of its work runs off-main.
- **Ordering and lifetime:** which operations run independently, which preserve
  submission order, what cancellation or replacement does, and whether work
  continues after a screen disappears.
- **Visible state and recovery:** loading, saving, success, empty, and failure
  states where applicable, together with the user's retry or recovery options.
- **Evidence and limits:** links to relevant implementation files, named tests,
  manual checks, and profiling results. Distinguish implemented behaviour from
  measured performance; record known limitations and agreed follow-up work.

For example, a preset-storage section might say:

- UserDefaults access and JSON encoding/decoding run on the repository's
  off-main serial executor, leaving the Main Actor available for UI work.
- Saves preserve submission order and continue after the preset screen closes;
  they are not guaranteed to finish if the application process is terminated.
- The UI continues to show loading, saving, failure, and retry states.
- The feature manager publishes observable state on the Main Actor while
  awaiting storage operations.

Use examples only when the application actually provides those behaviours.
Off-main execution alone does not prove that an app is faster or never blocks.
Support performance claims with recorded measurements, not the presence of
`Task`, `async`, or an actor declaration.

Identify the reviewed commit, report date, tested configuration, and completion
approval. Summarise application-wide coordination, such as independent startup
loads, separately from individual features. Link to the behaviour contract and
migration ledger rather than copying their full history. If producing the
report exposes an unmet completion requirement, reopen the audit; do not hide
it behind a completed status.

## Pass Twelve: Replace Combine-based UI Observation with Swift Observation

This is an explicitly requested post-migration modernisation pass. Preserve the
completed migration commit and its report as a milestone; record this new scope
separately. The pass number is retained for the extended workflow; the preceding
completion audit and handover remain unnumbered. Do not automatically convert
every legacy app: first confirm that its supported OS versions and toolchain
support Observation, and obtain approval for any deployment-target change.

Replace ObservableObject, @Published, and manual objectWillChange forwarding
with @Observable on the classes that own observable state. Keep one shared
Feature Manager per feature and one bespoke ViewModel per screen. Feature APIs
must no longer require Combine publishers. A computed ViewModel property should
read its feature's authoritative state, not maintain a synchronised local copy.
Verify that reads through the actual feature protocol participate in tracking.

Use @State for the screen-owned observable viewModel and @Bindable only where
bindings to observable properties are required. Adapt theme observation too.
Preserve screen identity, navigation, sheet state, and task lifetimes. @State
retains the installed value for a View identity, but its initial-value expression
can execute when View structs are constructed again; unlike StateObject's
autoclosure it is not a guarantee that the initializer runs only once. Keep
initializers cheap and side-effect-free, and do not start tasks or register
subscriptions during construction. Explicit lifecycle actions own that work.

Observation is change tracking, not thread safety or background execution.
Retain Main Actor isolation for observable state, existing off-main audio and
storage ownership, and all ordering/cancellation guarantees. Exclude task handles
and internal bookkeeping from tracking with @ObservationIgnored where appropriate.
Do not make storage actors observable merely to remove an import.

Remove obsolete subscriptions and cancellables rather than replacing them with
a custom notification framework. Inventory any Combine pipelines that do more
than UI observation: Observation is not a general replacement for event streams,
debouncing, or backpressure. Preserve those semantics explicitly if encountered.

Replace publisher-specific test assertions with Observation tracking tests of
screen-facing properties. Cover two different ViewModels reading the same
feature, computed and collection-derived values, relevant versus unrelated
changes, theme updates, and loading/failure/retry state. Account for
withObservationTracking's one-shot, pre-mutation notification semantics; read
resulting values after mutation and establish fresh tracking for later changes.
Retain existing business and concurrency tests, including cancellation on owner
destruction, and manually check screen recreation, bindings, and dismissal.

Follow Apple's [Observation migration guide](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
for framework mechanics without changing the AppBrain ownership rules.

**Completion gate:** no obsolete Combine observation remains in production or
tests; shared feature changes reach every consuming screen through its own
ViewModel; binding, identity, and task-lifetime checks pass; complete concurrency
checking and the regression suite pass. Record manual verification and any gaps.
Update the architecture and feature report to describe Observation, then commit
this modernisation separately from the completed migration. Do not claim a
performance improvement without measurements.

## Pass Thirteen: Keep the Main Actor Available for UI Work

> Keep UI-observed state and short presentation-facing coordination on the Main
> Actor. Give expensive computation, blocking operations, and timing-sensitive
> execution an appropriate owner outside it.

This is an evaluation followed by implementation and verification, not a
review-only pass. Revisit execution ownership after the preceding changes,
including presentation calculations as well as Model work. Do not interpret
the rule as moving every async function off-main: suspension releases the
executor, while synchronous work between suspension points still needs an
appropriate execution owner.

### Evaluate and Plan

Trace startup and important interactions through Views, ViewModels, Feature
Managers, and their collaborators. Identify expensive synchronous sections,
blocking APIs, repeated allocations, excessive observable mutations, and
timing-sensitive work that depends on UI delivery. Check actual actor isolation
and the project's compiler settings rather than inferring execution from
`Task` or `async` syntax.

For each finding, record the operation, current owner and executor, evidence,
proposed owner, behaviour risk, and verification plan in the migration ledger.
Separate measured delays from suspected bottlenecks. Prioritise concrete
findings; reuse earlier profiling and avoid speculative layers or parallelism.

### Execute the Plan

Implement the scoped refinements in small checkpoints. Keep observable state
and short coordination on the Main Actor. Keep business decisions with their
Feature Manager, delegating expensive execution to its owned collaborators.
Presentation-only calculations may use a renderer owned by the ViewModel;
moving computation off-main does not make it business logic.

Use native asynchronous APIs where available, an actor or suitable computation
executor for isolated computation, and an appropriate execution boundary for
unavoidable blocking APIs. An actor is not a dedicated thread, and a detached
Task does not make blocking work cooperative. For real-time audio, prefer the
audio framework's scheduling facilities; neither UI ticks nor cooperative Task
wake-ups guarantee audio deadlines.

Transfer safe value snapshots, preserve operation order and durable work, and
reject cancelled or stale results before publishing them. Bound work in flight
so UI polling cannot build a backlog. Do not add `Task.yield()` as a substitute
for execution ownership. Preserve visible failure and retry states, and agree
on any product-behaviour changes before implementing them.

### Verify and Report

Run complete concurrency checking and affected regression tests at each
checkpoint. Verify execution boundaries, cancellation, replacement, ordering,
and stale-result protection. Exercise startup, animation, and feature activity
together; for timing-sensitive features, verify live transitions and sustained
behaviour, not just isolated state changes. Passing an offline audio test does
not establish real-time audible smoothness.

**Completion gate:** findings have been implemented and verified, or explicitly
agreed as deferred with reasons; execution ownership is documented; builds and
regression tests pass; and affected user flows have manual approval. Record
before/after measurements where available and leave unavailable runtime checks
explicitly pending. Update the feature behaviour report and recommend a separate
Git checkpoint. Do not claim that all Model work is off-main, that the main
thread never blocks, or that performance improved without supporting evidence.

## Pass Fourteen: Main Actor Code Review

Review the finished implementation with this question:

> Does each feature leave the Main Actor and its executor primarily available
> for UI-related work, rather than using them as the default place to execute
> the feature's workload?

Pass Thirteen implements execution refinements. This pass audits the resulting
code feature by feature, including paths that were not changed. Aim for each
Feature Manager's substantive work to execute outside the Main Actor while
keeping UI-observed state and short presentation-facing coordination on it.
Review operations, not just the actor annotation on the manager: a Main Actor
Feature Manager may correctly await work performed by its off-main repository,
audio adapter, or computation collaborator. Do not create a second Feature
Manager or duplicate authoritative state merely to change execution ownership.

For every Feature Manager, trace its public commands and the synchronous work
they invoke, including launch, first use, repeated interactions, failure, and
retry paths. Inspect work before and after each await, task isolation, and
computed properties read by the UI. Record:

- which operations execute outside the Main Actor and their actual owners;
- which operations remain on it and why they belong there;
- any computation, I/O, resource preparation, or timing dependency still
  unnecessarily consuming or depending on the UI executor; and
- a concrete refinement and verification plan for each unresolved finding.

Prefer moving substantive workloads to an appropriate non-main execution owner.
Retain small state transitions where moving them would add coordination without
a meaningful benefit, and respect APIs that require the main thread. Explain
these decisions rather than weakening isolation or mechanically adding actors,
detached Tasks, or async declarations. Apply Pass Thirteen's execution and
verification safeguards to any resulting corrections, preserving feature
ownership, observable behaviour, ordering, cancellation, and error recovery.

**Completion gate:** every Feature Manager has an evidence-backed execution
review; remaining Main Actor work has a clear UI, short-coordination, or
documented API requirement; and substantive off-main work has an identifiable
owner. Resolve findings within the agreed scope or record explicitly approved
deferrals. Build and test any corrections, obtain manual approval for affected
flows, and update the feature behaviour report with remaining verification
gaps. A clean review may require no code changes. This is an ownership audit,
not proof of faster performance or a guarantee that the main thread never
blocks.
