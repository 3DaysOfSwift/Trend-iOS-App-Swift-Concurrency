# Dashboard Review and Ratings

## Deliverable and workflow

Produce a self-contained interactive HTML dashboard for a modern iOS target
using Swift Concurrency. The analysis is read-only. Do not edit app code, delete
tests, publish reports or commit changes. Use a caller-supplied repository and
output directory, never a hard-coded app name, path, source fingerprint or line
number. Example reports are evidence for their own app only.

1. Read repository instructions, select the target and establish live wiring.
   Inspect Swift settings, conditional compilation and source membership; a
   filesystem scan alone cannot resolve these.
2. Generate the source inventory. Review matches and callers, rejecting type
   declarations mistaken for constructors. Never fix counts by special-casing
   the input repository. `Task<T, E>` as a return/property type creates no Task.
3. Trace feature commands and public behaviour through the actual layers.
   Apply [Concurrency warnings](concurrency-warnings.md), including navigation,
   repeated requests and persistence effects. Record source-backed findings
   and distinguish confirmed defects from risks.
4. Inventory business-rule groups and test scenarios; read actual assertions.
   Complete the full-analysis ledger and reconciliation before producing both
   ratings below. A sampled first pass is working evidence, not the deliverable.
5. Import any available Xcode test summary and measured coverage. Preserve the
   target/run identity and state whether source alignment was verified.
6. Generate the report, check counts/formulas, code highlighting and navigation,
   and inspect responsive rendering when permitted. Link the newest report and
   report any verification that could not be performed.

## Rating rules

Ratings are expected. Do not prohibit them or leave a dashboard full of promises
to calculate them later. Each displayed rating must name its denominator, method
and scope. Inspect enough code to make an assessment; expose gaps rather than
quietly inflating the result. Unknown is not zero.

### UI / Model separation

Count distinct reviewed product-rule groups, not every `if`, accessor or call.
Exclude presentation-only formatting, navigation and animation decisions.
Classify each rule as SwiftUI View, ViewModel, Model or Other, with source lines.
A model rule is testable if it can be exercised without constructing the UI.

Score = round(100 × testable Model rules / all reviewed rules).
SwiftUI and ViewModel business rules deduct points. No meaningful testable model
boundary means 0, not a passing score for one or two isolated functions. Explain
that boundary judgment. Set `complete: true` only after the full-analysis gate
passes. An incomplete inventory must not produce a project rating; report
“Analysis incomplete — project ratings withheld”, with specific missing work.
Do not use `ratingScope: reviewed-rules` to bypass completion. A legitimately
empty rule inventory has no percentage; explain the completed inspection.

### Test quality

Enumerate meaningful behaviour groups for exposed feature commands: success,
invalid input, persistence/integration failure, cancellation, overlapping calls,
stale completion, retry and cross-feature scope where applicable. Do not create
irrelevant scenarios simply to increase the denominator. Match scenarios to
assertions, not function names alone. Include test file and source line evidence.

Score = round(100 × reviewed scenarios with matching assertions / reviewed scenarios).
Stars = displayed score / 20. Thus 80 / 100 = 4 / 5 stars; use fractional fill.
Use green for 80–100 and red below 80, with numeric text so colour is not the only
signal. The denominator must cover the reconciled scenario inventory across all
in-scope features, not a selected sample. A perfect 100 means every scenario in
that inventory has matching assertions, not that every possible input is tested.
This rating measures
reviewed behavioural protection, not all dimensions of test quality, execution
coverage or mutation resistance. Display this scope beside the rating.

List tests worth strengthening separately. A stored-property assignment/readback
may be low value, but reconstructing a manager to verify persistence is meaningful.
Default-value, conversion and forwarding assertions can protect real contracts.
Explain what broken implementation a weak assertion could miss. Do not label a
test redundant without evidence, or delete any tests during analysis. “No focused
test identified” is not proof that no test exists. Findings and test suggestions
do not automatically become agreed product requirements.

### Test pass gauge and measured coverage

Show passed / total with an arc proportional to passed / total; include failed
and skipped counts. Zero total means no pass rate. A green 114 / 114 does not
mean the app is fully tested. Import a real Xcode summary; never infer passing
from source code or reuse another app's result.

Code coverage requires xccov covered/executable line counts for one exact target.
Do not substitute pass rate or reviewed scenarios. Omit an unavailable coverage
card rather than showing a “Not yet measured” placeholder. If requested coverage
cannot be obtained, explain the missing artifact in the handoff, not as a score.

Other requested architecture ratings need an explicit agreed rubric and inspected
evidence. Do not infer readability, spaghetti or cooperation scores from Task
counts, folder names, MainActor annotations or the percentage of unstructured
Tasks. Keep unsupported metrics out of the dashboard.

## Presentation contract

- Put useful counts and ratings first. Use “Analysis · Xcode Project dashboard”,
  the actual project name, and “ARCHITECTURE REPORT”. No Git status display.
- Labels: “Tasks”, “Unstructured Tasks”, “Detached Tasks”, “Child Tasks”, “Await”,
  “SwiftUI Tasks”, “ViewModel Tasks”, “Model Tasks”, “UI · MainActor annotations”,
  “Model · MainActor annotations”. Explain that counts are source instructions,
  not runtime instances; detached Tasks are included in unstructured Tasks.
- Use “Source files”, “Business decisions” and “View results for”. Reuse count
  cards as task filters. Put search, matching list and selected detail inside
  one bordered results panel. Empty filters say “No detached tasks”, etc.
- Show filename · Line N, then highlighted source, then explanation. Preserve
  full paths as secondary detail. Use “SOURCECODE”, “Possible suspension point”,
  and “💡 What is …?” definitions. Avoid “candidate” and cryptic “sites” labels.
- Display business cards as number → “Reviewed business decisions” → layer name.
- Group source-backed lifecycle findings under “⚠️ Concurrency Warnings”.
  Distinguish warnings, managed operations and unresolved checks. Correctly
  managed root Tasks must not receive a warning just for being unstructured.
  Explain actual creator waiting/cancellation and View-lifetime behaviour.
- Structured children (`async let`, task groups) have scoped completion and
  parent cancellation propagation. Ordinary await is not a child Task.
- Do not use a task-composition progress bar: 100% unstructured looks like a
  quality score. Use counts and a brief lifecycle explanation instead.
- Show collapsible orange investigation titles as readable questions, source
  evidence and focused suggested checks. Separate raw scanner warnings from
  semantically reviewed findings. Keep unknown runtime boundaries in relevant
  details; remove unfinished-metric sections and unsupported score placeholders.

## Reusable tool inputs

The dashboard tool is a separate tool; obtain its path from the user/environment. Read
its `Documentation/OBSERVATIONS.md` and `Documentation/REVIEWS.md` for current
schemas. Do not use `examples/build-trend-review.mjs` for another project.

The current tool folder is named `swift-architecture-explorer`; this is a disk
folder name, not another product the reader needs to understand. Keep its `src`,
`Documentation` and `package.json` together. It requires Node.js 20 or newer and
has no package-install step. Run `node src/cli.mjs --help` from that folder before
using it. Neither Trend nor the migration skill is a runtime dependency.
Xcode on macOS is needed only to run iOS tests or export Xcode result bundles;
source review and rendering can use an already supplied JSON result elsewhere.

If the generator is unavailable, explain that before proceeding. A custom HTML
fallback can follow the same rating and presentation rules, but must be labelled
as custom output, not the tested standard generator. Do not silently download
or install tooling. Ask for the tool location when the standard output is required.

Apply [the full-analysis gate](full-analysis.md) for every project dashboard.
Incomplete working notes must never stand in for the requested full analysis.
Keep rule groups consistent in size, avoid duplicate scenarios,
and record the reasoning behind each classification so another reviewer can
reproduce or challenge the rating. Do not claim rankings across projects whose
review scope and grouping differ.

```sh
node /path/to/dashboard-tool/src/cli.mjs /path/to/app --out /path/to/new-inventory
# Inspect source and author observations/review bound to that inventory.
node /path/to/dashboard-tool/src/cli.mjs /path/to/app \
  --observations /path/to/observations.json --review /path/to/review.json \
  --test-results /path/to/xcode-summary.json --project-name 'Your iOS App' \
  --out /path/to/new-dashboard
```

Omit `--test-results` if unavailable; retain ratings from the source review.
Use `--coverage` and `--coverage-target` only with measured xccov JSON.
The review importer verifies hashes and line ranges, including test sources
outside the production scan. It does not prove the review judgments themselves.
If the tool is absent, build equivalent HTML using these rules and keep evidence
alongside it; do not claim tool validation that was not performed.
