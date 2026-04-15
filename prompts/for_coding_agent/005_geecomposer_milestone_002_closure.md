# geecomposer Milestone 002 Closure Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a narrow corrective pass to close milestone 002 cleanly after the
independent review.

Do not start milestone 003 work. Do not implement Sentinel-1 logic, grouping,
export, auth, notebooks, or broad refactors.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

The milestone-002 review is recorded here:

- `05_governance/reviews/review_milestone_002.md`

Use that review as the authoritative scope for this corrective pass.

## Current state

- milestone 001 is closed
- milestone 002 is implemented and tested
- the full local test suite currently passes in the project `.venv`
- milestone 002 is **not yet closeable** because one implemented metadata path
  is misleading and two governance artifacts contain inaccurate test counts

## What the review found

### P1 to fix before closure

`compose()` currently derives `geecomposer:transform` from
`getattr(transform, "__name__", None)`.

That works for manually named mock functions in tests, but it does **not**
produce useful metadata for the built-in transform factories:

- `ndvi()`
- `select_band(...)`
- `normalized_difference(...)`
- `expression_transform(...)`

Those factories currently return inner callables named `_fn`, so ordinary user
calls like:

```python
compose(
    dataset="sentinel2",
    aoi="01_data/case_studies/rbmn.geojson",
    start="2024-01-01",
    end="2024-12-31",
    transform=ndvi(),
    reducer="max",
)
```

would attach:

```python
"geecomposer:transform": "_fn"
```

That is not useful metadata and does not satisfy the spec's "minimal but useful
metadata payload" intent.

### P2 to fix in the same pass

Two governance docs have inaccurate per-file test counts:

- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`

The overall suite result is correct, but the inventory counts for at least
`test_validation.py` and `test_compose.py` no longer match reality.

### P2 recommended test improvement

`test_sentinel2.py` currently verifies `linkCollection(...)` and `.map(...)`,
but it does not inspect the mapped masking function deeply enough to prove the
threshold/updateMask path.

Add one focused deterministic test for that behavior if it can be done cleanly
without overbuilding.

### P3 cleanup if small and safe

- remove the dead `ds_module is not None` check in `compose.py`
- remove one of the two reducer validation calls, or keep both only if you can
  justify that explicitly in code comments or docs

These are not the primary goal. Do not broaden the pass to chase polish.

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
- `docs/GEECOMPOSER_MILESTONE_002_SENTINEL2_COMPOSE.md`
- `05_governance/reviews/review_milestone_002.md`
- `01_data/case_studies/rbmn.geojson`

## Also inspect before editing

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/utils/metadata.py`
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`
- `08_pkg/src/geecomposer/datasets/sentinel2.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_sentinel2.py`
- `08_pkg/tests/test_metadata.py`

## Task

Do this pass in a safe, narrow sequence.

### 1. Fix transform metadata naming

Required outcome:

- built-in transform factories produce a useful stable transform identifier for
  metadata
- `compose(..., transform=ndvi())` should not attach `_fn`
- the solution should stay lightweight and function-based
- do not introduce a heavy transform class system

Acceptable directions include:

- setting stable attributes on returned transform callables
- assigning meaningful `__name__` values on returned callables
- using a tiny helper pattern inside transform factories

Pick the smallest clean solution that works across the built-in factories.

### 2. Add a real test that proves the metadata fix

Required outcome:

- at least one compose-path test uses a real built-in transform factory
- the test verifies the actual metadata attached to the output image
- the test would have failed before the fix

Do not rely only on a mocked callable with a manually assigned `__name__`.

### 3. Tighten Sentinel-2 masking test coverage if clean

Preferred outcome:

- verify the mapped mask function performs:
  - `img.select("cs_cdf")`
  - `.gte(0.6)`
  - `img.updateMask(...)`

Keep this deterministic and mock-based. Do not require live Earth Engine.

If this becomes awkward or brittle, keep the test modest rather than writing a
complex mock harness.

### 4. Correct governance artifact counts

Update at minimum:

- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`

Make the per-file test counts match the actual suite.

Update any related milestone wording only if needed for honesty.

### 5. Optional tiny cleanup only if clearly safe

You may also fix one or both of these if doing so is small and low-risk:

- remove dead `ds_module is not None` in `compose.py`
- remove duplicate reducer validation or explicitly justify it

Do not turn this into a refactor pass.

## Scope

You should:

- fix only the milestone-002 closure items
- add only the tests needed to prove those fixes
- keep docs/governance aligned with actual results

You should not:

- implement Sentinel-1
- change milestone 003 scope
- add `compose_yearly()`
- implement export helpers
- implement auth
- add notebooks
- redesign the package

## Verification

Use the project `.venv` and verify with:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If you use a different command in addition, record it honestly.

## Definition of Done

- built-in transform metadata is useful and stable
- at least one new test proves the real metadata behavior
- Sentinel-2 masking coverage is improved if done cleanly
- governance artifact counts are corrected
- the suite passes in the documented `.venv` environment
- milestone 002 is left ready for a short closure review

## Important principle

This is a closure pass, not a feature pass.

Prefer:

- one precise metadata fix
- one meaningful test that would have caught the issue
- honest documentation cleanup

over:

- wider cleanup
- early Sentinel-1 work
- abstractions that do more than the review requires
