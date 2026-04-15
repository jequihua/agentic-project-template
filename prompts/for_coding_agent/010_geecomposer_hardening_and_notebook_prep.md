# geecomposer Hardening and Notebook-Prep Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a narrow hardening pass after milestone 004 closure. It is **not**
another feature-expansion milestone.

The goal is to smooth and strengthen the existing v0.1 surface so the project
is ready for official notebook-based live validation and example authoring.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

## Current state

- milestones 001, 002, 003, and 004 are closed
- both required dataset presets work:
  - `sentinel2`
  - `sentinel1`
- `compose()`, `compose_yearly()`, and `export_to_drive()` are implemented and
  tested
- the package can already be used in a live notebook when Earth Engine is
  initialized manually with `ee.Initialize(...)`
- `initialize()` is still a placeholder
- some control docs are slightly stale after the milestone 004 corrective pass

This hardening pass should make the package and repo easier to use correctly in
live notebook validation without adding new product scope.

## Use these control artifacts first

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
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
- `05_governance/reviews/review_milestone_004_corrective.md`
- `02_analysis/notebooks/README.md`
- `01_data/case_studies/rbmn.geojson`

## Also inspect before editing

- `08_pkg/src/geecomposer/auth.py`
- `08_pkg/src/geecomposer/__init__.py`
- `08_pkg/src/geecomposer/export/drive.py`
- `08_pkg/src/geecomposer/grouping.py`
- `08_pkg/tests/test_export_drive.py`
- `08_pkg/tests/test_grouping.py`
- `08_pkg/tests/test_public_api.py`

## Task

Do this pass in a safe, narrow sequence.

### 1. Implement `initialize()` for real package use

Required outcome:

- `geecomposer.initialize()` becomes usable
- it should initialize Earth Engine in a small, explicit way
- it must not hide Earth Engine behind a complex abstraction layer
- it should be suitable for notebook usage

Keep the interface lightweight. A good v0.1 outcome is:

- accept `project: str | None = None`
- accept `authenticate: bool = False`
- if `authenticate=True`, call `ee.Authenticate()` before initialization
- call `ee.Initialize(project=project)` when a project is provided
- otherwise call `ee.Initialize()`
- return nothing or a minimal success value if that is the existing repo style

Important constraints:

- do not hardcode any local project ID
- do not build credential storage logic
- do not add service-account flows
- do not add environment-variable orchestration beyond what is clearly needed

If you add package-level error wrapping, keep it very small and consistent.

### 2. Add focused tests for `initialize()`

Required outcome:

- tests are deterministic and do not require live Earth Engine credentials
- patch the local `ee` import in `auth.py`
- verify:
  - `initialize()` calls `ee.Initialize()` with no project by default
  - `initialize(project="...")` passes the project through
  - `initialize(authenticate=True)` calls `ee.Authenticate()` before
    `ee.Initialize()`

Do not add live auth tests to the main suite.

### 3. Polish small existing gaps from closed milestone work

This pass may also clean up a few small, already-identified issues that make
the package or repo less crisp for notebook validation.

At minimum:

- refresh stale counts and next-step wording in `08_pkg/current_status.md`
- ensure post-milestone-004 governance/docs are internally consistent

Optionally, if clean and small:

- add an explicit `file_name_prefix=None` test for `export_to_drive()`
- add one explicit `start=None` or `end=None` validation test for
  `compose_yearly()` so the strict rule is executable documentation
- tighten any obviously misleading docstrings discovered in the touched files

Only do these if they stay small and do not broaden scope.

### 4. Keep notebook readiness in mind

Do not create notebooks in this pass.

But leave the package and docs in shape for the next step:

- a live notebook under `02_analysis/notebooks/milestones/`
- manual EE initialization or package `initialize()`
- `compose(...)`
- `export_to_drive(...)`
- Drive task start and status checks done in notebook code

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

Update only what changed in this pass.

## Scope

You should:

- implement `initialize()`
- add only the tests needed to prove it
- clean up small stale package/governance artifacts
- improve notebook readiness without creating notebooks yet

You should not:

- add new dataset logic
- add new transforms or reducers
- redesign export or grouping
- add GCS export
- add task monitoring helpers
- add service-account or complex auth frameworks
- create notebooks in this pass
- perform broad unrelated refactors

## Verification

Use the project `.venv` and verify with:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If you use targeted test commands first, record them honestly.

## Definition of Done

- `geecomposer.initialize()` is implemented and importable
- deterministic unit tests cover the implemented initialization behavior
- package/docs are cleaner and more internally consistent for notebook work
- the full suite passes in the documented environment
- the repo is ready for the next pass: official notebook generation and live
  validation

## Important principle

This is a hardening pass, not a new feature phase.

Prefer:

- one clean `initialize()` implementation
- a few trustworthy tests
- honest state cleanup
- better readiness for live notebooks

over:

- richer auth abstractions
- new product features
- broad cleanup unrelated to immediate notebook validation
