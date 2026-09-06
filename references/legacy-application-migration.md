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
