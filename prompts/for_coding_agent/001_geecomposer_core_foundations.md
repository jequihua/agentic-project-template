# geecomposer Core Foundations Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

The current project priority is the shared package foundations for
`geecomposer`, not dataset integration, not live export workflows, and not broad
refactoring.

The key architectural conclusions already established are:

- `geecomposer` must stay a narrow function-based library
- per-image transforms and temporal reducers must stay separate
- Sentinel-1 and Sentinel-2 support are required, but dataset-specific logic
  belongs in dataset modules and should not be improvised inside the shared
  foundations
- AOI normalization is a first-class boundary and must support local vector
  inputs safely
- exports matter to the workflow, but export helpers must remain separate from
  the composition core
- CLI, visualization, local raster downloads, and advanced SAR preprocessing
  are out of scope for v0.1

The current milestone is:

- implement focused exceptions and validation helpers
- implement AOI normalization foundations
- implement reducer mapping
- implement built-in transform factories
- strengthen tests for the active modules
- update docs and governance honestly to match what you actually implement

Current repo state:

- the template has been adapted into a `geecomposer`-specific development
  workspace
- the active package workspace is `08_pkg`
- the active package root is `08_pkg`
- the package scaffold exists under `08_pkg/src/geecomposer`
- many package modules are still placeholders
- the first coding pass should establish trustworthy shared foundations before
  dataset loaders or full `compose()` logic are implemented

Use:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`
- `docs/GEECOMPOSER_ROADMAP.md`
- `docs/GEECOMPOSER_PACKAGE_ANALYSIS.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/experiment_plan.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `05_governance/review_rubric.md`
- `06_infra/local_setup.md`
- `01_data/data_sources.md`
- `01_data/schema.md`
- `01_data/data_quality.md`

as the primary control artifacts.

## Active Workspaces

- `00_brief`
- `01_data`
- `02_analysis`
- `03_experiments`
- `05_governance`
- `06_infra`
- `08_pkg`
- `90_legacy_review`

## Before starting

Read:

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
- `00_brief/CONTEXT.md`
- `01_data/CONTEXT.md`
- `03_experiments/CONTEXT.md`
- `05_governance/CONTEXT.md`
- `06_infra/CONTEXT.md`
- `08_pkg/CONTEXT.md`
- `90_legacy_review/CONTEXT.md`
- `00_brief/problem_statement.md`
- `00_brief/constraints.md`
- `00_brief/non_goals.md`
- `00_brief/success_metrics.md`
- `01_data/data_sources.md`
- `01_data/schema.md`
- `01_data/data_quality.md`
- `02_analysis/analysis_summary.md`
- `03_experiments/experiment_plan.md`
- `05_governance/decision_log.md`
- `05_governance/assumptions_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `05_governance/review_rubric.md`
- `06_infra/local_setup.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`
- `docs/GEECOMPOSER_ROADMAP.md`
- `docs/GEECOMPOSER_PACKAGE_ANALYSIS.md`

Also inspect current implementation before editing:

- `08_pkg/src/geecomposer/__init__.py`
- `08_pkg/src/geecomposer/aoi.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/exceptions.py`
- `08_pkg/src/geecomposer/reducers/temporal.py`
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/tests/test_public_api.py`
- `08_pkg/tests/test_aoi.py`
- `08_pkg/tests/test_reducers.py`
- `08_pkg/tests/test_transforms.py`

## Task

Do the milestone in a safe sequence.

### 1. Implement exception and validation foundations

Required outcome:

- focused custom exceptions remain small and useful
- validation helpers provide clear reducer and dataset checks
- invalid inputs fail with explicit package-level errors where practical

### 2. Implement AOI normalization

Required outcome:

- `to_ee_geometry()` accepts the supported AOI forms that are reasonable for
  this milestone
- GeoJSON-like dictionaries and local vector paths are handled explicitly
- invalid or unsupported AOI inputs raise clear errors

If local vector support requires lightweight fixtures or helper utilities, keep
them minimal and reviewable.

### 3. Implement reducers and transforms

Required outcome:

- reducer mapping supports `median`, `mean`, `min`, `max`, and `mosaic`
- built-in transform factories support band selection, normalized difference,
  NDVI, and expression-based transforms
- custom transform callable expectations remain clear

### 4. Add tests and update docs honestly

At minimum consider:

- `08_pkg/tests/test_aoi.py`
- `08_pkg/tests/test_reducers.py`
- `08_pkg/tests/test_transforms.py`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`

## Goal

After this pass, the repository should have:

- real implementations for the shared core-foundation modules
- deterministic tests for those modules
- honest docs and governance artifacts aligned with what was implemented
- a package still clearly waiting on later dataset, compose, export, and
  grouping milestones

## Scope

Keep this pass narrow and foundation-focused.

You should:

- preserve the package boundaries established by the scaffold
- implement only the active foundation modules plus necessary supporting edits
- add real tests for the active scope
- keep docs and governance synchronized with the result

You should not:

- implement full `compose()` orchestration
- add Sentinel-1 or Sentinel-2 collection loading
- add export helper implementations
- add yearly grouping implementation
- add CLI or application features
- perform broad refactors unrelated to the active foundation modules

## Requirements

### 1. Keep module ownership explicit

The implementation must not blur ownership across modules.

Be explicit about:

- what `aoi.py` owns
- what `validation.py` owns
- what transform modules own
- what reducer modules own
- what remains deferred to later milestones

### 2. Keep Earth Engine visible

Do not wrap Earth Engine concepts in unnecessary abstraction. Favor clear,
direct behavior over clever indirection.

### 3. Keep errors reviewable

A reviewer should be able to tell:

- which inputs are supported
- how invalid AOIs fail
- which reducers are allowed
- what transform factories produce

### 4. Tests

Strengthen tests in `08_pkg/tests/` as needed.

At minimum cover:

- valid and invalid AOI paths for the implemented scope
- reducer selection and invalid reducer behavior
- transform factory behavior and invalid usage where relevant
- public package imports still working

### 5. Governance and docs

Update only as needed to reflect the real implementation and any refined
decisions.

Document honestly:

- what foundation modules now work
- what still remains placeholder behavior
- any implementation constraints uncovered during the pass

## Non-goals

DO NOT implement:

- full compose pipeline orchestration
- dataset loaders
- export task helpers
- grouping helpers
- CLI wrappers
- visualization utilities
- local raster downloads
- advanced SAR processing

## Definition of Done

- active foundation modules are implemented and tested
- invalid cases raise clear package-level errors where appropriate
- public imports still work
- docs and governance are synchronized to the actual result
- package boundaries remain clean and reviewable

## Important principle

This pass is about making the shared package foundations trustworthy before the
dataset-specific and orchestration layers are built on top of them.

Prefer:

- explicit module boundaries
- real tests
- narrow scope
- honest documentation

over:

- premature compose logic
- hidden magic
- broad package expansion
- placeholder-heavy changes that look complete but are not
