# geecomposer Core Foundations Final Closure Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is to finish closing milestone 001 for
`geecomposer`, not to begin milestone 002 dataset work, not to implement
`compose()`, and not to broaden the package surface.

Until further notice, use this case-study AOI as the canonical project polygon
for any AOI-dependent examples, checks, or local manual validation work:

- `01_data/case_studies/rbmn.geojson`

Do not invent alternate case-study AOIs unless the task explicitly requires a
small synthetic test fixture.

The key architectural conclusions already established are:

- `geecomposer` must stay a narrow function-based library
- per-image transforms and temporal reducers must stay separate
- AOI normalization is a first-class boundary and must fail with explicit
  package-level errors on invalid input
- milestone 001 is still not closeable because the corrective-pass review found
  a remaining AOI error-path bug
- dataset loaders, `compose()`, export helpers, grouping, and auth remain out
  of scope for this pass

The current closure pass is:

- fix malformed GeoJSON `FeatureCollection` geometry handling so invalid feature
  geometries raise `InvalidAOIError` rather than leaking raw low-level
  exceptions
- add tests proving that behavior
- address the small review recommendations that are safe and useful within this
  same pass
- update docs and governance honestly to reflect the final closure state

Current repo state:

- milestone 001 foundations were implemented
- milestone 001 got an independent review
- a corrective pass fixed the original two `P1` issues
- the corrective-pass review found one remaining closure blocker in
  `_dissolve_feature_collection()`
- the corrective-pass review is recorded in
  `05_governance/reviews/review_milestone_001_corrective.md`

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
- `05_governance/reviews/review_milestone_001_corrective.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`
- `01_data/case_studies/rbmn.geojson`

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
- `05_governance/reviews/review_milestone_001_corrective.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`
- `01_data/case_studies/rbmn.geojson`

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
- `05_governance/risks.md`
- `05_governance/review_log.md`

## Task

Do the final closure pass in a safe sequence.

### 1. Fix malformed FeatureCollection geometry handling

Required outcome:

- `_dissolve_feature_collection()` does not leak raw `KeyError`,
  `GeometryTypeError`, or other low-level shapely exceptions for malformed
  geometry dicts
- malformed geometries are reported as `InvalidAOIError`
- the error message is clear enough that a reviewer can tell the AOI input was
  invalid, not that the package crashed internally

Be especially careful about mixed collections:

- all valid geometries
- some valid and some malformed geometries
- missing `geometry`
- geometry dicts with missing coordinates
- geometry dicts with unknown geometry types

Decide and document the intended behavior clearly. Do not hide malformed input
behind silent skipping unless the behavior is deliberate and justified.

### 2. Add the missing closure tests

At minimum add or improve tests for:

- malformed FeatureCollection geometry dicts raising `InvalidAOIError`
- mixed valid/malformed FeatureCollection behavior
- any new helper path you introduce while fixing the AOI error handling

### 3. Address the small review recommendations that fit this pass

If safe and still within scope:

- remove or strengthen the redundant `read_vector_file` pathlib test so it adds
  real coverage
- keep the docs explicit about the two dissolve code paths and their intended
  equivalence by input form

Do not turn this into a broad cleanup pass.

### 4. Update docs and governance honestly

At minimum consider:

- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`

If this pass really closes milestone 001, the artifacts should say so
carefully and truthfully.

## Goal

After this pass, milestone 001 should be genuinely closeable:

- the original `P1` issues remain fixed
- the remaining AOI error-path blocker is fixed
- the milestone test suite passes in the documented environment
- docs and governance match the final milestone state

## Scope

Keep this pass narrow and closure-focused.

You should:

- touch only AOI logic, directly related tests, and the docs/governance needed
  to reflect the result
- use the project `.venv` for verification
- keep later-milestone modules untouched

You should not:

- start Sentinel-2 or Sentinel-1 dataset loading work
- implement `compose()`
- implement export helpers
- implement grouping
- add new public API surface unrelated to AOI closure
- perform broad refactors

## Requirements

### 1. Keep milestone discipline

This pass exists to close milestone 001, not to partially start milestone 002.

### 2. Keep AOI behavior explicit

A reviewer should be able to tell:

- how valid multi-feature GeoJSON dicts are normalized
- how malformed FeatureCollection geometries fail
- whether mixed valid/malformed inputs are accepted or rejected
- which AOI input forms are covered by tests

### 3. Verify in the documented environment

Use the project `.venv` and verify with the full package test command:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If any environment-specific caveat arises, document it honestly.

### 4. Use the case-study AOI consistently

For any AOI-dependent manual checks, examples, or notes in this pass, use:

- `01_data/case_studies/rbmn.geojson`

Synthetic fixtures are still acceptable inside `08_pkg/tests/fixtures/` when
they are specifically needed for deterministic unit tests.

## Non-goals

DO NOT implement:

- dataset collection loading
- compose orchestration
- export logic
- grouping logic
- auth logic
- CLI or application features

## Definition of Done

- malformed FeatureCollection geometries raise `InvalidAOIError`
- the new AOI tests pass and prove the closure behavior
- the full milestone suite passes in `.venv`
- docs and governance support closing milestone 001 honestly
- the package remains cleanly within milestone 001 scope

## Important principle

This pass is about making the AOI foundations fully trustworthy before the
package moves into dataset and orchestration work.

Prefer:

- explicit invalid-input handling
- meaningful tests
- narrow closure scope
- honest milestone documentation

over:

- partial milestone 002 work
- silent skipping of bad AOI data without justification
- broad cleanup unrelated to closure
