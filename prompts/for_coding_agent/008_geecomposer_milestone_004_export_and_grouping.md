# geecomposer Milestone 004 Export and Grouping Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is milestone 004 for `geecomposer`: Drive export
helper support and yearly grouping.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

Milestones 001, 002, and 003 are closed. The package now has trustworthy
foundations plus working Sentinel-2 and Sentinel-1 dataset paths.

The main architectural conclusions already established are:

- `geecomposer` must remain a narrow function-based library
- Earth Engine should stay visible
- dataset-specific logic belongs in dataset modules
- per-image transforms and temporal reducers must stay separate
- export helpers should remain logically separate from composition
- grouping should stay intentionally modest in v0.1

The current milestone is:

- implement `export_to_drive()` as a small Drive task helper
- implement `compose_yearly()` as a yearly grouping helper
- ensure both build on the existing architecture without broadening scope
- add meaningful tests for the implemented behavior
- update docs and governance honestly

Current repo state:

- milestone 001 is complete
- milestone 002 is complete
- milestone 003 is complete
- `compose()` supports Sentinel-2, Sentinel-1, and raw collections
- `export_to_drive()` is still a placeholder
- `compose_yearly()` is still a placeholder
- notebook workspace is prepared under `02_analysis/notebooks/`

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_004_EXPORT_AND_GROUPING.md`
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
- `docs/GEECOMPOSER_MILESTONE_004_EXPORT_AND_GROUPING.md`
- `01_data/case_studies/rbmn.geojson`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/grouping.py`
- `08_pkg/src/geecomposer/export/drive.py`
- `08_pkg/src/geecomposer/aoi.py`
- `08_pkg/src/geecomposer/utils/metadata.py`
- `08_pkg/tests/test_grouping.py`
- `08_pkg/tests/test_public_api.py`

## Task

Do the milestone in a safe, narrow sequence.

### 1. Implement `export_to_drive()`

Required outcome:

- create a Google Drive export task through Earth Engine
- keep the helper small and explicit
- accept an `ee.Image` plus explicit export parameters
- normalize `region` through existing AOI conversion when appropriate
- return the Earth Engine task object

Be careful not to add:

- task polling
- task monitoring abstractions
- GCS export
- local download workflows

### 2. Implement `compose_yearly()`

Required outcome:

- support yearly grouping only
- accept a list or iterable of years
- return `dict[int, ee.Image]`
- delegate each yearly image build to `compose()`
- keep the control flow explicit and easy to review

Do not add monthly, seasonal, or generic grouping frameworks.

### 3. Add tests for the implemented behavior

At minimum cover:

- `export_to_drive()` task creation shape using mocks
- region normalization / delegation behavior
- invalid export arguments if relevant
- `compose_yearly()` delegation to `compose()`
- returned dict keys and values
- one failure path for invalid yearly input if needed

Use deterministic tests first. Do not require live Earth Engine credentials in
the main milestone suite.

### 4. Keep notebook readiness in mind

This pass does not need to create notebooks, but it should leave the package in
shape for notebook-based validation against:

- `01_data/case_studies/rbmn.geojson`

Especially for:

- composing a real image
- creating a real Drive export task
- composing yearly outputs for a short year range

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

After this pass, `geecomposer` should support the next core v0.1 workflow
pieces beyond composition itself:

- compose an image
- group by year
- create a Drive export task

All while keeping export, grouping, and composition as separate concerns.

## Scope

Keep this pass narrow and milestone-focused.

You should:

- implement only Google Drive export
- implement only yearly grouping
- delegate yearly image building to the existing `compose()` path
- add tests for the real implemented behavior
- preserve the clean architecture established in milestones 001–003

You should not:

- add GCS export
- add task monitoring or polling
- add monthly or seasonal grouping
- redesign `compose()`
- implement auth
- add notebooks
- introduce a CLI or app layer
- perform broad unrelated refactors

## Requirements

### 1. Keep Earth Engine visible

Do not hide Earth Engine behind a large abstraction layer.

### 2. Keep ownership boundaries explicit

A reviewer should be able to tell:

- what `export/drive.py` owns
- what `grouping.py` owns
- what `compose.py` still owns
- what remains deferred to later milestones

### 3. Use the case-study AOI consistently

For AOI-dependent manual checks, examples, and notebook-oriented notes, use:

- `01_data/case_studies/rbmn.geojson`

### 4. Verify in the project environment

Use the project `.venv` for verification. If `--basetemp=.pytest_tmp` is still
needed on this Windows environment, use it and document that honestly.

## Non-goals

DO NOT implement:

- GCS export
- task monitoring
- grouped export helpers
- monthly or seasonal grouping
- auth flows beyond the current scope
- notebook files themselves
- visualization or CLI features

## Definition of Done

- `export_to_drive()` exists and creates Drive export tasks
- `compose_yearly()` exists and delegates to `compose()`
- the implemented path is tested in the documented environment
- docs and governance reflect the new package state honestly

## Important principle

This pass is about adding two core workflow helpers without breaking the clean
separation that now exists in the package.

Prefer:

- one trustworthy Drive export helper
- one trustworthy yearly grouping helper
- explicit delegation
- meaningful tests
- honest milestone documentation

over:

- generalized export systems
- generalized grouping engines
- orchestration refactors
- premature production tooling
