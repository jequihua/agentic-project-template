# geecomposer Milestone 003 Closure Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a narrow corrective pass to close milestone 003 cleanly after the
independent review.

Do not start milestone 004 work. Do not implement export helpers, grouping,
auth flows, notebooks, or broad refactors.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

The milestone-003 review is recorded here:

- `05_governance/reviews/review_milestone_003.md`

Use that review as the authoritative scope for this corrective pass.

## Current state

- milestone 001 is closed
- milestone 002 is closed
- milestone 003 is implemented and tested
- the full local test suite currently passes in the project `.venv`
- milestone 003 is **not yet closeable** because malformed Sentinel-1 filter
  values are not validated clearly and one small compose docstring mismatch
  remains

## What the review found

### P1 to fix before closure

`datasets/sentinel1.py` currently validates unsupported filter keys but does
not validate malformed filter values.

The review confirmed that these currently pass instead of failing clearly:

- `{"instrumentMode": 123}`
- `{"orbitPass": 123}`
- `{"polarizations": []}`
- `{"polarizations": "VV"}`

That creates confusing downstream behavior. In particular:

- `polarizations="VV"` is treated as an iterable of characters, leading to two
  `listContains(..., "V")` filters instead of one `VV` filter

This violates the milestone requirement that invalid or malformed Sentinel-1
filter inputs fail clearly.

### P2 to fix in the same pass

`compose.py` still documents the dataset preset path as only `"sentinel2"`
even though `"sentinel1"` is now implemented.

This is small, but it should be corrected for honesty.

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
- `docs/GEECOMPOSER_MILESTONE_003_SENTINEL1.md`
- `05_governance/reviews/review_milestone_003.md`
- `01_data/case_studies/rbmn.geojson`

## Also inspect before editing

- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/tests/test_sentinel1.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/src/geecomposer/validation.py`
- `08_pkg/src/geecomposer/exceptions.py`

## Task

Do this pass in a safe, narrow sequence.

### 1. Add real Sentinel-1 filter value validation

Required outcome:

- malformed Sentinel-1 filter values fail clearly with package-level errors
- validation remains inside the Sentinel-1 dataset module
- the implementation stays explicit and lightweight

At minimum validate:

- `instrumentMode` must be a non-empty string
- `orbitPass` must be a non-empty string
- `polarizations` must be a non-empty list or tuple of non-empty strings

You may choose whether to also constrain `orbitPass` to known values like
`ASCENDING` / `DESCENDING`, but if you do, keep the behavior simple and fully
tested.

Do not build a generic validation framework for this.

### 2. Add tests that prove the malformed-value cases fail

Required outcome:

- the four cases from the review are covered:
  - `{"instrumentMode": 123}`
  - `{"orbitPass": 123}`
  - `{"polarizations": []}`
  - `{"polarizations": "VV"}`
- tests verify package-level error behavior, not accidental downstream mock
  behavior
- at least one test should prove the old string-iteration bug cannot recur

Keep the tests deterministic and mock-based.

### 3. Clean up the small compose docstring mismatch

Required outcome:

- `compose()` docs mention both implemented dataset presets where appropriate

Do not broaden this into a full doc rewrite.

### 4. Update docs and governance honestly

At minimum consider:

- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `02_analysis/findings.md`
- `05_governance/review_log.md`

Only update what changed.

## Scope

You should:

- fix only the milestone-003 closure items
- add only the tests needed to prove those fixes
- keep docs/governance aligned with actual results

You should not:

- implement export helpers
- implement `compose_yearly()`
- add auth flows
- add notebooks
- add advanced Sentinel-1 preprocessing
- redesign dataset dispatch
- perform broad unrelated refactors

## Verification

Use the project `.venv` and verify with:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If you use additional targeted commands, record them honestly.

## Definition of Done

- malformed Sentinel-1 filter values fail clearly
- tests prove the malformed-value cases are fixed
- the compose docstring matches the implemented dataset support
- the suite passes in the documented `.venv` environment
- milestone 003 is left ready for a short closure review

## Important principle

This is a closure pass, not a feature pass.

Prefer:

- one precise validation fix
- a few meaningful regression tests
- honest documentation cleanup

over:

- wider cleanup
- early milestone-004 work
- abstractions that do more than the review requires
