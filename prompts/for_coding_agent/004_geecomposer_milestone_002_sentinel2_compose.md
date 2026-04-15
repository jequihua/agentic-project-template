# geecomposer Milestone 002 Sentinel-2 Compose Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is milestone 002 for `geecomposer`: the first real
Sentinel-2 composition workflow. Do not start Sentinel-1 work, export
implementation, grouping, or broad refactors.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented testing:

- `01_data/case_studies/rbmn.geojson`

The key architectural conclusions already established are:

- milestone 001 is closed and provides trustworthy AOI, validation, reducer,
  and transform foundations
- `geecomposer` must remain a narrow function-based library
- per-image transforms and temporal reducers must stay separate inside the
  composition pipeline
- Earth Engine should remain visible rather than hidden behind heavy
  abstractions
- dataset-specific logic belongs in dataset modules, not scattered through the
  package
- milestone 002 should deliver one real, narrow, usable Sentinel-2 path before
  any broader feature expansion

The current milestone is:

- implement Sentinel-2 dataset loading
- implement the first real `compose()` orchestration path
- connect AOI normalization, masking, selection, transforms, reducers, and
  metadata in a clean linear flow
- add meaningful tests for the implemented Sentinel-2 path
- update docs and governance honestly to reflect the real package state

Current repo state:

- milestone 001 is complete and reviewed
- `compose()` is still a placeholder
- `datasets/sentinel2.py` is still a placeholder
- export, grouping, Sentinel-1, and auth remain out of scope for this pass
- a notebook workspace is prepared under `02_analysis/notebooks/` for upcoming
  interactive testing

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_002_SENTINEL2_COMPOSE.md`
- `docs/GEECOMPOSER_ROADMAP.md`
- `docs/GEECOMPOSER_PACKAGE_ANALYSIS.md`
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
- `01_data/data_sources.md`
- `01_data/schema.md`
- `01_data/data_quality.md`
- `01_data/case_studies/rbmn.geojson`
- `02_analysis/notebooks/README.md`

as the primary control artifacts.

## Active Workspaces

- `01_data`
- `02_analysis`
- `03_experiments`
- `05_governance`
- `06_infra`
- `08_pkg`

## Before starting

Read:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `01_data/CONTEXT.md`
- `02_analysis/CONTEXT.md`
- `03_experiments/CONTEXT.md`
- `05_governance/CONTEXT.md`
- `06_infra/CONTEXT.md`
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
- `docs/GEECOMPOSER_MILESTONE_002_SENTINEL2_COMPOSE.md`
- `01_data/case_studies/rbmn.geojson`
- `02_analysis/notebooks/README.md`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/datasets/sentinel2.py`
- `08_pkg/src/geecomposer/aoi.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/reducers/temporal.py`
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`
- `08_pkg/src/geecomposer/utils/metadata.py`
- `08_pkg/tests/test_sentinel2.py`
- `08_pkg/tests/test_public_api.py`

## Task

Do the milestone in a safe sequence.

### 1. Implement Sentinel-2 dataset loading

Required outcome:

- `datasets/sentinel2.py` exposes the default Sentinel-2 collection id
- it can load an `ee.ImageCollection` filtered by AOI and date
- it supports the intended masking hook for `s2_cloud_score_plus`
- unsupported masking choices fail clearly rather than being silently ignored

Keep the Sentinel-2 logic narrow and explicit.

### 2. Implement the first real `compose()` path

Required outcome:

- `compose()` works for `dataset="sentinel2"`
- the pipeline order stays explicit and linear
- AOI normalization is actually used
- reducer validation and application are actually used
- optional `select`, `mask`, `preprocess`, `transform`, and `metadata`
  participate in the implemented path in a reviewable way

Be especially careful not to blur:

- dataset loading
- per-image transform logic
- temporal reduction logic
- metadata attachment

### 3. Add tests for the implemented Sentinel-2 path

At minimum cover:

- dataset preset resolution
- invalid dataset or reducer inputs through `compose()`
- AOI normalization being invoked by `compose()`
- Sentinel-2 loader behavior at the boundary level
- `compose()` orchestration order for the implemented path using mocks where
  appropriate
- masking behavior for the supported mask option

Use deterministic tests first. Do not require live Earth Engine credentials in
the main milestone suite.

### 4. Keep notebook readiness in mind

This pass does not need to create notebooks, but it should leave the package in
shape for the next notebook-based checks using:

- `01_data/case_studies/rbmn.geojson`
- `02_analysis/notebooks/milestones/`
- `02_analysis/notebooks/case_studies/`

Any manual or example-oriented notes in this pass should assume that AOI.

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

## Goal

After this pass, `geecomposer` should have its first real end-to-end package
workflow:

- Sentinel-2 collection loading
- AOI normalization
- optional masking and transform handling
- temporal reduction to an `ee.Image`

This should be enough to justify notebook-based interactive testing next.

## Scope

Keep this pass narrow and milestone-focused.

You should:

- implement only the Sentinel-2 path
- keep later milestones honestly deferred
- add tests for the actual implemented behavior
- preserve the clean architecture established in milestone 001

You should not:

- implement Sentinel-1
- implement `compose_yearly()`
- implement Drive export
- implement full auth workflows
- add monthly or seasonal grouping
- introduce a CLI or app layer
- perform broad unrelated refactors

## Requirements

### 1. Keep Earth Engine visible

Do not hide Earth Engine behind a large abstraction layer.

### 2. Keep module ownership explicit

A reviewer should be able to tell:

- what `datasets/sentinel2.py` owns
- what `compose.py` owns
- what is still deferred to later milestones

### 3. Use the case-study AOI consistently

For AOI-dependent manual checks, examples, and notebook-oriented notes, use:

- `01_data/case_studies/rbmn.geojson`

Synthetic fixtures remain acceptable in tests when needed for deterministic
coverage.

### 4. Verify in the project environment

Use the project `.venv` for verification. If `--basetemp=.pytest_tmp` is still
needed on this Windows environment, use it and document that honestly.

## Non-goals

DO NOT implement:

- Sentinel-1
- export helpers
- grouping helpers
- auth flows beyond the current scope
- notebook files themselves
- visualization or CLI features

## Definition of Done

- Sentinel-2 dataset support exists
- `compose()` has a real Sentinel-2 orchestration path
- the implemented path is tested in the documented environment
- docs and governance reflect the new package state honestly
- the package is ready for notebook-based smoke testing against `rbmn.geojson`

## Important principle

This pass is about delivering one real usable workflow cleanly before broadening
the package.

Prefer:

- one trustworthy Sentinel-2 path
- explicit orchestration
- meaningful tests
- honest milestone documentation

over:

- partial multi-dataset work
- premature export features
- broad abstraction layers
- notebook-driven implementation without package discipline
