# geecomposer Milestone 003 Sentinel-1 Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is milestone 003 for `geecomposer`: the first real
Sentinel-1 dataset path.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

Milestone 002 is closed. The Sentinel-2 path and the shared compose pipeline
are now trustworthy enough to extend carefully.

The main architectural conclusions already established are:

- `geecomposer` must remain a narrow function-based library
- Earth Engine should stay visible
- dataset-specific logic belongs in dataset modules
- per-image transforms and temporal reducers must stay separate
- the existing `compose()` pipeline should be extended, not redesigned
- Sentinel-1 support must not introduce advanced SAR processing in v0.1

The current milestone is:

- implement Sentinel-1 dataset loading
- support minimal Sentinel-1 dataset-specific filtering
- make `compose(dataset="sentinel1", ...)` work through the existing pipeline
- add meaningful tests for the implemented radar path
- update docs and governance honestly

Current repo state:

- milestone 001 is complete
- milestone 002 is complete
- `datasets/sentinel1.py` is still a placeholder
- `compose()` already supports Sentinel-2 and raw collections
- export, grouping, and auth remain out of scope for this pass
- notebook workspace is prepared under `02_analysis/notebooks/`

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_003_SENTINEL1.md`
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
- `02_analysis/findings.md`
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
- `02_analysis/findings.md`
- `docs/GEECOMPOSER_MILESTONE_003_SENTINEL1.md`
- `01_data/case_studies/rbmn.geojson`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/datasets/sentinel2.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/reducers/temporal.py`
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`
- `08_pkg/src/geecomposer/utils/metadata.py`
- `08_pkg/tests/test_sentinel1.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_public_api.py`

## Task

Do the milestone in a safe, narrow sequence.

### 1. Implement Sentinel-1 dataset loading

Required outcome:

- `datasets/sentinel1.py` exposes the default Sentinel-1 collection id
- it can load an `ee.ImageCollection` filtered by AOI and date
- it supports a small explicit filter vocabulary through `filters`
- unsupported or malformed filter inputs fail clearly

At minimum support the filters the spec most clearly calls for:

- `polarizations`
- `instrumentMode`
- `orbitPass`

Keep the implementation explicit and reviewable. Do not add advanced SAR
processing.

### 2. Integrate Sentinel-1 into the existing compose path

Required outcome:

- `compose(dataset="sentinel1", ...)` works through the current pipeline
- dataset resolution stays simple
- Sentinel-1-specific behavior stays inside the dataset module
- shared orchestration stays generic

Be careful not to blur:

- dataset filtering
- per-image transforms
- temporal reduction
- metadata attachment

### 3. Add tests for the implemented Sentinel-1 path

At minimum cover:

- sentinel1 dataset preset resolution
- sentinel1 loader AOI + date filtering
- sentinel1 filter application for supported keys
- invalid Sentinel-1 filter inputs
- compose-path behavior for `dataset="sentinel1"`
- one realistic Sentinel-1 transform path using the existing generic transform
  mechanism or a custom callable

Use deterministic tests first. Do not require live Earth Engine credentials in
the main milestone suite.

### 4. Keep notebook readiness in mind

This pass does not need to create notebooks, but it should leave the package in
shape for notebook-based validation against:

- `01_data/case_studies/rbmn.geojson`

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

After this pass, `geecomposer` should support both of its required v0.1 dataset
presets at a basic but real level:

- Sentinel-2
- Sentinel-1

The dataset modules should differ where they need to, while the main compose
pipeline remains stable.

## Scope

Keep this pass narrow and milestone-focused.

You should:

- implement only the Sentinel-1 path required by the spec
- reuse the existing compose pipeline
- add tests for the real implemented behavior
- preserve the clean architecture established in milestones 001 and 002

You should not:

- add speckle filtering
- add terrain correction
- add coherence logic
- implement `compose_yearly()`
- implement Drive export
- implement auth flows
- add notebooks
- introduce a CLI or app layer
- perform broad unrelated refactors

## Requirements

### 1. Keep Earth Engine visible

Do not hide Earth Engine behind a large abstraction layer.

### 2. Keep module ownership explicit

A reviewer should be able to tell:

- what `datasets/sentinel1.py` owns
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

- advanced Sentinel-1 preprocessing
- export helpers
- grouping helpers
- auth flows beyond the current scope
- notebook files themselves
- visualization or CLI features

## Definition of Done

- Sentinel-1 dataset support exists for the scoped feature set
- `compose()` has a real Sentinel-1 orchestration path
- supported Sentinel-1 filters work and invalid ones fail clearly
- the implemented path is tested in the documented environment
- docs and governance reflect the new package state honestly

## Important principle

This pass is about proving that the package can support both required dataset
families without breaking architectural simplicity.

Prefer:

- one trustworthy Sentinel-1 path
- explicit filter handling
- meaningful tests
- honest milestone documentation

over:

- advanced SAR features
- abstractions that hide dataset differences
- broad refactors
- premature export or notebook-driven implementation
