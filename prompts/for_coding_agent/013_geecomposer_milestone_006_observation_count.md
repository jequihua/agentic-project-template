# geecomposer Milestone 006 Observation Count Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is milestone 006 for `geecomposer`: add a clean
per-pixel observation-count capability through the existing temporal reducer
system.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

This is a focused reducer-extension milestone, not a broader temporal-analysis
or seasonal-grouping milestone.

The main architectural conclusions already established are:

- `geecomposer` must remain a narrow function-based library
- Earth Engine should stay visible
- dataset-specific logic belongs in dataset modules
- per-image transforms and temporal reducers must stay separate
- the existing `compose()` pipeline should be extended, not redesigned
- new capability should fit the current reducer dispatch rather than add a
  second parallel API if avoidable

The current milestone is:

- add `count` as a supported temporal reducer
- make `compose(..., reducer="count")` work through the existing pipeline
- document the difference between Sentinel-2 clear-observation counts and
  Sentinel-1 acquisition counts
- add meaningful tests without changing the current dataset paths

Current repo state:

- milestones 001-005 are closed
- hardening pass is complete
- the package is already ready for notebook-based live validation
- `compose()` supports `sentinel2`, `sentinel1`, `sentinel1_float`, and raw
  collection IDs
- yearly grouping already exists
- seasonal grouping is still deferred

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_006_OBSERVATION_COUNT.md`
- `docs/GEECOMPOSER_ROADMAP.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `docs/ML_FEATURES.md`
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
- `01_data/CONTEXT.md`
- `02_analysis/CONTEXT.md`
- `03_experiments/CONTEXT.md`
- `05_governance/CONTEXT.md`
- `08_pkg/CONTEXT.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `docs/GEECOMPOSER_MILESTONE_006_OBSERVATION_COUNT.md`
- `docs/ML_FEATURES.md`
- `01_data/case_studies/rbmn.geojson`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/reducers/temporal.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/datasets/sentinel2.py`
- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/datasets/sentinel1_float.py`
- `08_pkg/tests/test_reducers.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_validation.py`

## Task

Do the milestone in a safe, narrow sequence.

### 1. Add `count` to the reducer vocabulary

Required outcome:

- `validate_reducer("count")` succeeds
- `apply_reducer(..., "count")` dispatches to `ImageCollection.count()`
- existing reducer names remain unchanged

Strong constraint:

- do **not** add a second helper API such as `observation_count(...)` if the
  current reducer system is sufficient

Preferred design:

- extend the existing reducer constants and reducer map cleanly

### 2. Make `compose(..., reducer="count")` work through the current pipeline

Required outcome:

- `compose()` continues to follow the existing pipeline order
- count is applied after dataset loading, optional masking, optional select,
  optional preprocess, and optional transform
- no dataset-specific count logic leaks into `compose.py`

Important semantic requirement:

- the count should reflect the number of non-masked images present in the
  collection at the reduction step

### 3. Cover realistic count semantics in tests

At minimum cover:

- reducer validation and mapping for `count`
- compose-path behavior for `dataset="sentinel2"` with masking
- compose-path behavior for `dataset="sentinel1"` or `dataset="sentinel1_float"`
- at least one transformed count workflow, preferably Sentinel-2 NDVI with
  masking

Use deterministic tests first. Do not require live Earth Engine credentials in
the main milestone suite.

### 4. Keep the milestone narrow

This milestone is **not** about:

- seasonal grouping
- monthly grouping
- observation-density helper functions
- uncertainty metrics
- export automation
- notebook creation

If a design choice would broaden the package beyond “add `count` cleanly as a
reducer,” do not take it in this pass.

### 5. Update docs and governance honestly

At minimum consider:

- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `08_pkg/README.md` if a short usage example materially helps

## Goal

After this pass, `geecomposer` should support a sixth explicit reducer,
`count`, so users can produce:

- Sentinel-2 clear-observation count composites after masking
- Sentinel-1 / Sentinel-1 float acquisition count composites

through the same `compose()` interface already used for median/mean/min/max/
mosaic.

## Scope

Keep this pass narrow and milestone-focused.

You should:

- add only the reducer support required for observation counting
- reuse the existing compose pipeline
- add tests for the real implemented behavior
- document the semantics clearly

You should not:

- add seasonal grouping
- add monthly grouping
- add new export helpers
- redesign the reducer API
- redesign the transform system
- add dataset-specific count special cases
- add notebooks in this pass
- perform broad unrelated refactors

## Requirements

### 1. Keep Earth Engine visible

Do not hide Earth Engine behind a large abstraction layer.

### 2. Keep semantics explicit

A reviewer should be able to tell clearly:

- Sentinel-2 count with masking means valid clear observations
- Sentinel-1 / Sentinel-1 float count means contributing acquisitions

### 3. Keep module ownership explicit

A reviewer should be able to tell:

- reducer logic lives in the reducer/validation layer
- `compose.py` remains orchestration only
- dataset modules remain unchanged except for docs if needed

### 4. Verify in the project environment

Use the project `.venv` for verification. If `--basetemp=.pytest_tmp` is still
needed on this Windows environment, use it and document that honestly.

## Non-goals

DO NOT implement:

- seasonal grouping
- monthly grouping
- count-specific helper functions
- cloud-quality metrics beyond count
- task monitoring
- notebook files
- visualization or CLI features

## Definition of Done

- `count` is a supported reducer
- `compose()` supports it through the existing pipeline
- tests cover realistic Sentinel-2 and Sentinel-1/Sentinel-1 float count paths
- docs and governance reflect the new capability honestly

## Important principle

This pass is about adding one scientifically useful QA/feature primitive
without broadening the package unnecessarily.

Prefer:

- one clean reducer extension
- explicit semantics
- meaningful tests
- honest documentation

over:

- helper proliferation
- temporal-analysis expansion
- broad refactors
- premature seasonal abstractions
