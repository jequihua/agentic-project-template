# geecomposer Milestone 005 Sentinel-1 Linear Float Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is milestone 005 for `geecomposer`: add a clean
Sentinel-1 linear-unit dataset path based on `COPERNICUS/S1_GRD_FLOAT`.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

This is a focused enhancement milestone, not a broad SAR-processing expansion.

The main architectural conclusions already established are:

- `geecomposer` must remain a narrow function-based library
- Earth Engine should stay visible
- dataset-specific logic belongs in dataset modules
- per-image transforms and temporal reducers must stay separate
- the existing `compose()` pipeline should be extended, not redesigned
- advanced SAR preprocessing must not sneak in implicitly

The current milestone is:

- add a clean linear-unit Sentinel-1 dataset path
- support `COPERNICUS/S1_GRD_FLOAT`
- make `compose(dataset="sentinel1_float", ...)` work through the existing pipeline
- leave `compose(dataset="sentinel1", ...)` unchanged
- add meaningful tests for the new preset and at least one linear-unit derived
  feature workflow

Current repo state:

- milestones 001–004 are closed
- hardening pass is complete
- the package is already ready for notebook-based live validation
- `datasets/sentinel1.py` currently supports the dB product `COPERNICUS/S1_GRD`
- `compose()` already supports `sentinel1`, `sentinel2`, and raw collections
- GCS export, monthly/seasonal grouping, and advanced SAR processing remain out
  of scope

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_005_S1_LINEAR_FLOAT.md`
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
- `docs/GEECOMPOSER_MILESTONE_005_S1_LINEAR_FLOAT.md`
- `docs/ML_FEATURES.md`
- `01_data/case_studies/rbmn.geojson`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`
- `08_pkg/tests/test_sentinel1.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_public_api.py`

## Task

Do the milestone in a safe, narrow sequence.

### 1. Add the linear-unit Sentinel-1 dataset preset

Required outcome:

- a new explicit preset such as `sentinel1_float` exists
- it uses `COPERNICUS/S1_GRD_FLOAT`
- it supports the same filter vocabulary as the current Sentinel-1 path where
  appropriate:
  - `instrumentMode`
  - `orbitPass`
  - `polarizations`
- it is clear to users that this preset is the linear-unit path

Strong constraint:

- do **not** change the meaning of the existing `sentinel1` preset

Preferred design:

- a small dedicated dataset module for the float collection, or another equally
  explicit dataset-module-level solution

Do not add hidden flags that change unit semantics behind the existing
`sentinel1` name.

### 2. Integrate the new preset into the existing compose path

Required outcome:

- `compose(dataset="sentinel1_float", ...)` works through the current pipeline
- current `sentinel1` and `sentinel2` behavior remains intact
- no radar-specific logic leaks into `compose.py` beyond clean dataset
  registration / resolution

### 3. Prove a linear-unit feature workflow

Required outcome:

- tests prove that a user can create at least one derived SAR feature using the
  current transform system on top of `sentinel1_float`

Good examples:

- `VH / VV`
- `VH + VV`
- `VH - VV`
- `RVI`-like expression

You do **not** need to add a new built-in transform helper in this milestone if
the current expression/custom-transform system is sufficient.

### 4. Add tests for the new preset

At minimum cover:

- dataset preset resolution
- collection ID
- AOI + date filtering
- supported filter behavior
- invalid filter inputs
- compose-path behavior for `dataset="sentinel1_float"`
- one derived-feature expression path
- preservation of current `sentinel1` behavior

Use deterministic tests first. Do not require live Earth Engine credentials in
the main milestone suite.

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

After this pass, `geecomposer` should support two distinct Sentinel-1 modes in
a clean, explicit way:

- `sentinel1` for the existing dB product path
- `sentinel1_float` for linear-unit SAR feature generation

This should make biomass-oriented SAR feature engineering cleaner without
turning the package into a full SAR-processing framework.

## Scope

Keep this pass narrow and milestone-focused.

You should:

- add only the explicit float dataset path required for the milestone
- reuse the existing compose pipeline
- use the current transform system for derived SAR features
- add tests for the real implemented behavior
- preserve the clean architecture established in earlier milestones

You should not:

- add speckle filtering
- add terrain-correction frameworks
- add tide-aware filtering
- add GLCM or other texture features
- redesign reducers
- redesign the transform system
- implement GCS export
- implement grouped export helpers
- add notebooks in this pass
- perform broad unrelated refactors

## Requirements

### 1. Keep Earth Engine visible

Do not hide Earth Engine behind a large abstraction layer.

### 2. Keep unit semantics explicit

A reviewer should be able to tell clearly:

- `sentinel1` means current dB path
- `sentinel1_float` means linear-unit path

### 3. Keep module ownership explicit

A reviewer should be able to tell:

- what the Sentinel-1 float dataset module owns
- what `compose.py` owns
- what remains deferred to later SAR-related milestones

### 4. Verify in the project environment

Use the project `.venv` for verification. If `--basetemp=.pytest_tmp` is still
needed on this Windows environment, use it and document that honestly.

## Non-goals

DO NOT implement:

- speckle filtering
- SAR denoising frameworks
- terrain correction frameworks
- tide-aware filtering
- texture features
- new reducers
- notebook files
- visualization or CLI features

## Definition of Done

- `sentinel1_float` exists as a clean, explicit preset
- `compose()` supports it through the existing pipeline
- at least one linear-unit SAR derived feature workflow is tested
- current `sentinel1` behavior remains intact
- docs and governance reflect the new state honestly

## Important principle

This pass is about enabling cleaner SAR feature engineering without losing the
project's simplicity.

Prefer:

- one explicit new dataset preset
- physically clearer linear-unit feature generation
- meaningful tests
- honest documentation

over:

- advanced SAR frameworks
- hidden unit conversions
- broad refactors
- premature expansion into denoising or texture systems
