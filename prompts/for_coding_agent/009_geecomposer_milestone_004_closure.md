# geecomposer Milestone 004 Closure Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a narrow corrective pass to close milestone 004 cleanly after the
independent review.

Do not start post-milestone work such as `initialize()` implementation,
notebook authoring, examples hardening, release packaging, or broader refactors.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

The milestone-004 review is recorded here:

- `05_governance/reviews/review_milestone_004.md`

Use that review as the authoritative scope for this corrective pass.

## Current state

- milestones 001, 002, and 003 are closed
- milestone 004 is implemented and tested
- the full local test suite currently passes in the project `.venv`
- milestone 004 is **not yet closeable** because `compose_yearly()` silently
  fails for generator inputs after validation exhausts the iterable

## What the review found

### P0 to fix before closure

`compose_yearly()` currently validates `years` by converting it to
`list(years)` inside `_validate_yearly_args()`, but then the main function
iterates the original `years` object instead of the validated list.

That is harmless for lists and ranges, but it breaks for generators and other
one-shot iterables:

- a generator is exhausted during validation
- the later `for year in years` loop sees no items
- the function returns `{}` with no error
- `compose()` is never called

This is a real correctness bug, not just a test gap.

### P1 to consider in the same pass

`compose_yearly()` currently rejects `start=None` or `end=None` if those keys
appear in `compose_kwargs`, even though `None` is semantically similar to not
providing them.

The review did not require this to be fixed before closure, but asked for a
clear decision:

- either keep the current strict behavior and document it
- or relax the conflict check to reject only meaningful user-supplied values

Do not overbuild this. Make one clean decision and keep it explicit.

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
- `docs/GEECOMPOSER_MILESTONE_004_EXPORT_AND_GROUPING.md`
- `05_governance/reviews/review_milestone_004.md`
- `01_data/case_studies/rbmn.geojson`

## Also inspect before editing

- `08_pkg/src/geecomposer/grouping.py`
- `08_pkg/tests/test_grouping.py`
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/export/drive.py`
- `08_pkg/src/geecomposer/exceptions.py`

## Task

Do this pass in a safe, narrow sequence.

### 1. Fix the generator-exhaustion bug in `compose_yearly()`

Required outcome:

- `compose_yearly()` works correctly for:
  - lists
  - ranges
  - generators / one-shot iterables
- the validated year collection is the same one the function iterates
- the implementation stays explicit and lightweight

The simplest acceptable shape is:

- normalize `years` once
- validate that normalized collection
- iterate that same normalized collection

Do not build a generic grouping framework.

### 2. Add a regression test that proves the generator case works

Required outcome:

- add at least one grouping test using a generator for `years`
- prove `compose()` is actually called for each yielded year
- prove the returned dict contains the expected year keys

This test should have failed before the fix.

### 3. Decide the `start=None` / `end=None` edge case cleanly

Choose one of these:

- keep the current strict behavior and document it honestly
- or relax the check so only non-`None` user-provided values are rejected

Whichever you choose:

- keep it small
- keep it explicit
- add or adjust a test if behavior changes

Do not turn this into a broader kwargs-validation rewrite.

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

- fix only the milestone-004 closure items
- add only the tests needed to prove those fixes
- keep docs/governance aligned with actual results

You should not:

- implement `initialize()`
- add notebooks
- add export monitoring
- add GCS export
- add monthly or seasonal grouping
- redesign `compose()`
- perform broad unrelated refactors

## Verification

Use the project `.venv` and verify with:

```powershell
.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp
```

If you use any additional targeted commands, record them honestly.

## Definition of Done

- `compose_yearly()` works for generators and other supported iterables
- a regression test proves the generator case is fixed
- the `start`/`end` edge-case behavior is clearly decided and documented
- the suite passes in the documented `.venv` environment
- milestone 004 is left ready for a short closure review

## Important principle

This is a closure pass, not a feature pass.

Prefer:

- one precise bug fix
- one meaningful regression test
- honest documentation cleanup

over:

- broader grouping work
- early post-v0.1 improvements
- abstractions that do more than the review requires
