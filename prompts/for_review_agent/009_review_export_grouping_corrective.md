# Review Prompt — Export and Grouping Corrective Pass

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 004 corrective pass, and decide whether milestone 004 is now closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. what the milestone 004 independent review found,
3. what was changed in the corrective pass,
4. whether the P0 generator-exhaustion bug is genuinely resolved, whether the P1 `start`/`end` edge case is clearly decided, and whether milestone 004 can now be closed.

Then produce a structured review and a closure decision.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`
- the package source is at `08_pkg/src/geecomposer/`
- the product contract lives in `geecomposer_v0.1_spec.md`

Current development stage:
- milestones 001–003 are closed
- milestone 004 (export + grouping) was implemented and independently reviewed
- **a corrective pass has just been applied — this is the primary review target**
- 148 tests pass, 0 skipped

Review history:
- `05_governance/reviews/review_milestone_004.md` — independent review (P0
  generator bug, P1 start/end edge case, P2/P3 minor items)
- **This review** — corrective-pass closure decision

---

## What the milestone 004 review found

From `05_governance/reviews/review_milestone_004.md`:

### P0 — `compose_yearly()` silently breaks on generators

`_validate_yearly_args()` converted `years` to `list(years)` at line 74, but
`compose_yearly()` then iterated the original `years` object at line 50. For
generators, this meant:

- validation consumed the iterator
- the `for year in years` loop saw no items
- the function returned `{}` with no error
- `compose()` was never called

The reviewer verified this in `.venv`: `years=(y for y in [2023, 2024])`
returned `{}`.

### P2 — `compose_yearly()` rejects `start=None` / `end=None`

The conflict check `if "start" in compose_kwargs or "end" in compose_kwargs`
rejects key presence regardless of value. So `compose_yearly(years=[2024],
start=None, ...)` raises even though `None` is the default. The reviewer asked
for a clear decision: keep strict or relax.

### P2/P3 — Minor items

- Consider adding an explicit `file_name_prefix=None` export test
- Tighten the export task return type annotation

---

## What was changed in the corrective pass

### 1. Generator-exhaustion fix

**File:** `08_pkg/src/geecomposer/grouping.py`

The function was restructured:

- `_validate_yearly_args()` was renamed to `_validate_and_normalize_years()`
  and now **returns** the normalized `list[int]` instead of discarding it
- `compose_yearly()` assigns `year_list = _validate_and_normalize_years(years,
  compose_kwargs)` and then iterates `year_list` — the same list that was
  validated
- The original `years` parameter is never iterated directly after validation

**Review focus:**
- Trace the code path for a generator: `years=(y for y in [2023, 2024])` →
  `_validate_and_normalize_years` calls `list(years)` → returns `[2023, 2024]`
  → `compose_yearly` iterates `[2023, 2024]`. Is the generator consumed
  exactly once? Is the returned list the same object that's iterated?
- Trace for a regular list: `years=[2023, 2024]` → `list(years)` creates a
  copy → validation runs on the copy → `compose_yearly` iterates the copy.
  Does this work correctly? (It should — `list([2023, 2024])` is a new list.)
- Trace for a range: `years=range(2020, 2025)` → `list(years)` produces
  `[2020, 2021, 2022, 2023, 2024]` → validated → iterated. Correct?
- Is there any code path where the original `years` is still iterated after
  validation? Search for any remaining reference to `years` after line
  where `year_list` is assigned.
- Does the type hint `list[int] | range | Iterable[int]` now accurately
  reflect the accepted input forms?

### 2. Generator regression test

**File:** `08_pkg/tests/test_grouping.py`, class `TestComposeYearly`

New test `test_generator_input_works`:
- Creates `years_gen = (y for y in [2023, 2024])`
- Calls `compose_yearly(years=years_gen, ...)`
- Mocks `compose` with two side-effect return values
- Verifies `result == {2023: img_2023, 2024: img_2024}`
- Verifies `mock_compose.call_count == 2`

**Review focus:**
- Would this test have failed before the fix? Before the fix, the generator
  would be exhausted by `_validate_yearly_args`, and the loop would produce
  `{}`. The test asserts a non-empty dict with both years, so yes — it would
  have failed.
- Does the test verify that `compose()` was actually called (not just that the
  dict has the right keys)?
- Is a generator expression `(y for y in [2023, 2024])` a realistic one-shot
  iterable for this test? Are there other one-shot iterables worth testing
  (e.g., `iter([2023, 2024])`, `map(int, ["2023", "2024"])`)?

### 3. `start`/`end` conflict decision

The corrective pass kept the strict behavior: any presence of `start` or `end`
as keys in `compose_kwargs` is rejected, regardless of value (including
`None`).

This is documented in the updated docstring:
> *"Passing `start` or `end` (even as `None`) raises `GeeComposerError` to
> prevent ambiguity."*

**Review focus:**
- Is this the right decision? The strict approach is simpler and prevents a
  class of confusing bugs where `start=None` might be misinterpreted as "use
  the default" vs "explicitly unset." But it could surprise users who use
  `**kwargs` expansion from a dict that happens to contain `start: None`.
- Is the docstring clear enough about this behavior?
- Is the existing `test_start_in_kwargs_raises` test sufficient, or should
  there be an explicit `start=None` test to prove the strict behavior?

### 4. Governance updates

**Files updated:**
- `08_pkg/testing_strategy.md` — test_grouping count updated to 10, generator
  test noted
- `03_experiments/run_summary.md` — corrective changes documented, test count
  updated to 148
- `05_governance/review_log.md` — corrective pass entry
- `02_analysis/findings.md` — generator-exhaustion finding, strict start/end
  decision

**Review focus:**
- Do the per-file test counts match reality? Verify independently.
- Is the review log entry specific enough?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/compose.py` — unchanged
- `08_pkg/src/geecomposer/export/drive.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all unchanged
- `08_pkg/src/geecomposer/datasets/` — all unchanged
- `08_pkg/src/geecomposer/utils/` — unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/export/gcs.py` — placeholder, unchanged
- All test files except `test_grouping.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read review history and guidance
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (section 7.1 for grouping)
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_004.md` (authoritative findings)

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `05_governance/review_log.md`

### Step 2 — Verify the generator-exhaustion fix
Inspect `08_pkg/src/geecomposer/grouping.py`:

- Read `compose_yearly()` and `_validate_and_normalize_years()` line by line.
- Confirm `_validate_and_normalize_years` returns the list.
- Confirm `compose_yearly` uses the returned list, not the original `years`.
- Search for any remaining direct reference to `years` after the validation
  call. The only reference should be the parameter itself — it should not
  appear in the `for` loop.
- Verify in `.venv` if practical:
  ```python
  from unittest.mock import patch, MagicMock
  with patch("geecomposer.grouping.compose") as m:
      m.return_value = MagicMock()
      from geecomposer.grouping import compose_yearly
      result = compose_yearly(years=(y for y in [2023, 2024]),
                              dataset="sentinel2", aoi={}, reducer="median")
      print(result.keys())  # should show dict_keys([2023, 2024])
      print(m.call_count)   # should show 2
  ```

### Step 3 — Verify the regression test
Inspect `08_pkg/tests/test_grouping.py`:

- Does `test_generator_input_works` use a real generator expression?
- Does it verify both the dict contents and the `compose()` call count?
- Would it have failed before the fix?
- Run the full test suite:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`
- Verify 148 passed, 0 skipped.

### Step 4 — Verify the `start`/`end` decision
- Is the strict behavior documented in the `compose_yearly()` docstring?
- Is the existing `test_start_in_kwargs_raises` test sufficient to prove the
  strict behavior?
- Should there be a `test_start_none_in_kwargs_raises` test? Or is this
  unnecessary given the key-presence check?

### Step 5 — Check each original review item
For each item from `review_milestone_004.md` sections 3 and 5:

- `P0` Generator-exhaustion bug → resolved?
- `P0` Generator regression test → resolved?
- `P1` `start=None` / `end=None` decision → resolved (kept strict)?
- `P2` Explicit `file_name_prefix=None` export test → addressed or deferred?
- `P3` Export return type annotation → addressed or deferred?

### Step 6 — Evaluate scope discipline
- Only `grouping.py` and `test_grouping.py` were modified (plus governance)
- No export changes
- No compose changes
- No new features
- No auth, notebooks, or examples

### Step 7 — Verify governance accuracy
- Per-file test counts match reality?
- Review log entry accurate?

### Step 8 — Make the closure decision
- Is the generator-exhaustion bug definitively fixed?
- Is the `start`/`end` behavior clearly decided and documented?
- Are there any new issues?
- Is milestone 004 closeable?
- If yes, what should come next?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Export and Grouping Corrective

## 1. P0 Resolution
- Is the generator-exhaustion fix correct?
- Does the regression test prove the fix?

## 2. Review Item Status
For each item from `review_milestone_004.md`: resolved, honestly deferred,
or still outstanding.

## 3. New Issues
- Any bugs introduced
- Any test concerns
- Any doc inaccuracies

## 4. Scope Discipline
- Did the corrective pass stay within scope?

## 5. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should come next?
- Known debt to carry forward

## 6. Optional Recommendations
Small items only.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Focus narrowly on whether the corrective pass resolves the review findings
- Be especially rigorous about:
  - Whether the `years` parameter is truly never iterated after
    `_validate_and_normalize_years` — search the function body for any
    reference to `years` in the loop
  - Whether `list(years)` on an already-consumed generator returns `[]` (it
    does in Python — an exhausted generator yields nothing) — this is why the
    original bug produced `{}` instead of an error
  - Whether the regression test would genuinely fail before the fix: the old
    code iterated `years` (exhausted generator) → no loop iterations →
    `results = {}` → returned `{}`; the test asserts `result == {2023: ...,
    2024: ...}` → would fail
  - Whether the strict `start`/`end` check is documented clearly enough in
    the docstring
  - Whether the per-file test counts match the actual suite
- Cross-reference against:
  - `05_governance/reviews/review_milestone_004.md` (authoritative findings)
  - `geecomposer_v0.1_spec.md` section 7.1 (grouping spec)
  - `05_governance/review_rubric.md` (review criteria)
- Verify the 148-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_004_corrective.md`

Be direct and decisive. This is a corrective-pass review for the last major
feature milestone. The question is: is the generator bug fixed, is the
behavior clearly documented, and can the project move past feature
implementation toward validation and release preparation?
