# geecomposer Core Foundations Closure Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is to close the remaining milestone 001 issues for
`geecomposer`, not to begin milestone 002 dataset work, not to implement
`compose()`, and not to broaden the package surface.

The key architectural conclusions already established are:

- `geecomposer` must stay a narrow function-based library
- per-image transforms and temporal reducers must stay separate
- AOI normalization is a first-class boundary and must behave consistently
  across supported input forms
- foundation-level validation should fail with explicit package-level errors
- milestone 001 is close, but not yet closeable because the independent review
  found two `P1` issues

The current corrective pass is:

- fix GeoJSON `FeatureCollection` AOI semantics so multi-feature dict inputs do
  not silently drop all but the first feature
- harden `validate_reducer()` and `validate_dataset()` so non-string inputs do
  not raise raw `AttributeError`
- add the missing tests needed to support those fixes and reduce the known AOI
  edge-case gap
- update docs and governance honestly to reflect the corrective pass

Current repo state:

- milestone 001 foundations were implemented and independently reviewed
- the review is recorded in `05_governance/reviews/review_milestone_001.md`
- the review result is: milestone 001 is close, but not ready to close
- dataset loaders, `compose()`, export helpers, grouping, and auth remain out
  of scope for this pass

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_001.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`

as the primary control artifacts.

## Active Workspaces

- `01_data`
- `02_analysis`
- `03_experiments`
- `05_governance`
- `08_pkg`

## Before starting

Read:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `08_pkg/CONTEXT.md`
- `05_governance/CONTEXT.md`
- `03_experiments/CONTEXT.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_001.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `03_experiments/run_summary.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/aoi.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/tests/test_aoi.py`
- `08_pkg/tests/test_validation.py`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/review_log.md`

## Task

Do the corrective pass in a safe sequence.

### 1. Fix the `FeatureCollection` AOI issue

Required outcome:

- GeoJSON `FeatureCollection` dict inputs no longer silently discard every
  feature except the first
- dict-based AOI behavior is brought into line with the intended multi-feature
  normalization policy from the spec
- the behavior is documented clearly enough that a reviewer can understand the
  chosen normalization rule

### 2. Fix validation failure modes

Required outcome:

- `validate_reducer()` handles non-string input safely and raises
  `InvalidReducerError`
- `validate_dataset()` handles non-string input safely and raises
  `DatasetNotSupportedError`
- the failure mode is explicit and test-covered

### 3. Strengthen the missing tests

At minimum add or improve tests for:

- multi-feature GeoJSON AOI behavior
- `pathlib.Path` AOI input
- non-string inputs to `validate_reducer()`
- non-string inputs to `validate_dataset()`

If you can add a clean reprojection test without bloating the suite, do so. If
not, leave an honest note in the docs rather than forcing a brittle test.

### 4. Update docs and governance honestly

At minimum consider:

- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`

## Goal

After this pass, milestone 001 should be materially closer to closure with the
two reviewed `P1` issues resolved and the known test gaps reduced.

## Scope

Keep this pass narrow and corrective.

You should:

- touch only the foundation modules and their directly related tests/docs
- resolve the review findings with clear behavior and test coverage
- keep placeholder later-milestone modules untouched

You should not:

- start Sentinel-2 or Sentinel-1 dataset loading work
- implement `compose()`
- implement export helpers
- implement grouping
- add new public API surface unrelated to the review findings
- perform broad refactors

## Requirements

### 1. Keep milestone discipline

This pass exists to close milestone 001, not to partially start milestone 002.

### 2. Keep AOI behavior explicit

A reviewer should be able to tell:

- how multi-feature GeoJSON dicts are normalized
- whether the behavior matches local vector-file AOI normalization
- which AOI input forms are covered by tests

### 3. Keep validation behavior explicit

A reviewer should be able to tell:

- what happens on invalid reducer input
- what happens on invalid dataset input
- that non-string inputs do not leak raw Python attribute errors

### 4. Verify in the documented environment

Use the project `.venv` and verify with the full package test command. If the
test command needs a writable local base temp in this environment, use it and
document that honestly.

## Non-goals

DO NOT implement:

- dataset collection loading
- compose orchestration
- export logic
- grouping logic
- auth logic
- CLI or application features

## Definition of Done

- the two `P1` review issues are fixed
- the relevant tests pass in the documented environment
- docs and governance no longer overstate milestone 001 closure status
- the package remains cleanly within milestone 001 scope

## Important principle

This pass is about finishing the shared foundations properly before moving on.

Prefer:

- consistent AOI semantics
- explicit validation errors
- focused tests
- honest milestone documentation

over:

- partial milestone 002 work
- broad cleanup unrelated to the review findings
- cosmetic refactors without closure value
