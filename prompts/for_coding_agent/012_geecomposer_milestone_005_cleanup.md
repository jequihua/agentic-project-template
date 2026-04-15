# geecomposer Milestone 005 Cleanup Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a narrow post-review cleanup pass after milestone 005. It is **not** a
new feature milestone.

The authoritative review for this cleanup is:

- `05_governance/reviews/review_milestone_005.md`

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

## Current state

- milestones 001–005 are implemented
- `sentinel1_float` has been independently reviewed and is closeable
- the review found no correctness blocker
- one small documentation issue remains
- one small design-smell may be worth smoothing out if it can be done cleanly

This pass should stay very small and should not reopen milestone 005 scope.

## What the review found

### Confirmed issue to fix

`compose()` now supports `sentinel1_float`, but the `dataset` parameter
docstring still only mentions:

- `"sentinel2"`
- `"sentinel1"`

The docstring should clearly list all supported friendly preset names.

### Optional small improvement

`sentinel1_float.py` imports the private `_validate_filters` symbol from
`sentinel1.py`.

This is not a blocker, but it is a mild boundary smell. If it can be improved
cleanly and with very low risk, do so. If not, leave the code behavior alone
and instead improve clarity/documentation.

The key constraint is:

- do not broaden scope
- do not redesign the Sentinel-1 modules
- do not add new SAR features or preprocessing

## Use these control artifacts first

- `geecomposer_v0.1_spec.md`
- `CLAUDE.md`
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
- `05_governance/reviews/review_milestone_005.md`

## Also inspect before editing

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/datasets/sentinel1_float.py`
- `08_pkg/README.md`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_sentinel1_float.py`

## Task

Do this pass in a safe, narrow sequence.

### 1. Fix the `compose()` dataset docstring

Required outcome:

- the `dataset` parameter docstring in `compose()` explicitly reflects the
  currently supported preset names
- the wording remains concise and user-facing

At minimum it should now mention:

- `sentinel2`
- `sentinel1`
- `sentinel1_float`

### 2. Improve user-facing clarity between dB and float Sentinel-1 paths

Required outcome:

- a future reader should be able to tell when to use `sentinel1` versus
  `sentinel1_float`

Good places for this, if not already sufficient:

- `08_pkg/README.md`
- module docstrings in:
  - `datasets/sentinel1.py`
  - `datasets/sentinel1_float.py`

Keep this explanation short and practical:

- `sentinel1` = dB-scaled GRD path
- `sentinel1_float` = linear-unit path for ratio/algebraic SAR features

### 3. Optional design-smell cleanup only if it stays tiny

If and only if it can be done cleanly in a few lines without refactoring the
milestone design, you may reduce the private cross-module dependency around
shared Sentinel-1 filter validation.

Acceptable example:

- move shared Sentinel-1 filter constants/validation into a tiny neutral helper
  module used by both dataset modules

Not acceptable:

- broad SAR refactor
- changing filter behavior
- changing public API
- changing milestone semantics

If this cannot be done very cleanly, do not force it. Prefer small
documentation clarity over structural churn.

### 4. Update tests/docs only where needed

If you change documentation only, tests may not need changes.

If you change any internal helper location or implementation detail:

- keep behavior unchanged
- update tests only as needed
- keep the suite deterministic

At minimum consider:

- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/review_log.md`

Only update artifacts that actually changed in this pass.

## Scope

You should:

- fix the stale compose docstring
- improve clarity around `sentinel1` vs `sentinel1_float`
- optionally smooth the private-import smell only if it is tiny and low-risk

You should not:

- add new datasets
- add new transforms
- add speckle filtering
- add terrain-correction frameworks
- redesign `compose()`
- redesign dataset-module boundaries broadly
- create notebooks
- perform broad unrelated cleanup

## Verification

Use the project `.venv` and verify with:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If no code behavior changes, still run the suite unless there is a strong
reason not to.

## Definition of Done

- `compose()` docstring is accurate
- users can more easily distinguish dB vs float Sentinel-1 paths
- any cleanup beyond docs remains very small and behavior-preserving
- docs/governance stay honest
- the suite still passes

## Important principle

This is a polish pass.

Prefer:

- one accurate docstring
- one or two clarifying notes
- tiny low-risk cleanup

over:

- structural refactors
- speculative abstraction cleanup
- any new feature work
