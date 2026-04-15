# Review Prompt — Sentinel-2 Compose Corrective Pass

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 002 corrective pass, and decide whether milestone 002 is now closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. what the milestone 002 independent review found,
3. what was changed in the corrective pass,
4. whether the P1 metadata issue is genuinely resolved, whether the P2 items are addressed, and whether milestone 002 can now be closed.

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
- milestone 001 (core foundations) is closed
- milestone 002 (Sentinel-2 compose) was implemented and independently reviewed
- **a corrective pass has just been applied — this is the primary review target**
- 109 tests pass, 2 skipped (placeholders for grouping and sentinel1)

Review history:
- `05_governance/reviews/review_milestone_002.md` — independent review (P1 metadata, P2 counts/masking test, P3 dead code/double validation)
- **This review** — corrective-pass closure decision

---

## What the milestone 002 review found

From `05_governance/reviews/review_milestone_002.md`:

### P1 — Built-in transforms produce misleading metadata names

`compose()` derived `geecomposer:transform` from
`getattr(transform, "__name__", None)`. All built-in transform factories
returned closures named `_fn`, so `compose(..., transform=ndvi())` attached
`"geecomposer:transform": "_fn"` — not useful metadata.

### P2 — Governance docs misreport test inventory

`testing_strategy.md` and `run_summary.md` reported inaccurate per-file test
counts (e.g., `test_validation.py` listed as 16 instead of 20,
`test_compose.py` listed as 16 instead of 19).

### P2 — Sentinel-2 masking test does not verify threshold behavior

`test_cloud_score_plus_joins_and_maps` verified `linkCollection` and `.map()`
were called, but did not inspect the mapped mask function to verify the
`cs_cdf` band selection, `gte(0.6)` threshold, or `updateMask` call.

### P3 — Dead code and double validation

- `compose.py:106` checked `ds_module is not None` — always true.
- `compose.py:123` called `validate_reducer()`, then `apply_reducer()` called
  it again internally.

---

## What was changed in the corrective pass

### 1. Transform metadata naming fix

**Files:** `08_pkg/src/geecomposer/transforms/basic.py`,
`08_pkg/src/geecomposer/transforms/indices.py`,
`08_pkg/src/geecomposer/transforms/expressions.py`

Each factory now sets `_fn.__name__` on the returned closure before returning:

- `select_band("B4")` → `_fn.__name__ = "select_band('B4')"`
- `normalized_difference("B8", "B4")` → `_fn.__name__ = "normalized_difference('B8', 'B4')"`
- `ndvi()` → overrides to `_fn.__name__ = "ndvi"` (after `normalized_difference` sets its own)
- `expression_transform(name="ratio")` → `_fn.__name__ = "expression_transform('ratio')"`

No changes to `compose.py`'s metadata extraction — it still uses
`getattr(transform, "__name__", None)`, which now produces useful values.

**Review focus:**
- Is setting `__name__` on closures a clean, Pythonic solution? Are there
  cases where this could break (e.g., `functools.wraps`, pickling, debugging)?
- Are the naming conventions consistent? `ndvi()` returns just `"ndvi"` while
  `select_band("B4")` includes the argument. Is this intentional and clear?
- For `ndvi()`: it calls `normalized_difference(nir, red, name)` which sets
  `__name__` to `"normalized_difference('B8', 'B4')"`, then `ndvi()` overrides
  it to `"ndvi"`. Is this the right approach, or should `ndvi` pass through
  the more specific name?
- For custom user transforms (plain functions or lambdas): `__name__` will
  still be whatever Python sets (`"<lambda>"`, or the function name). Is this
  documented and acceptable?
- Does the `compose()` metadata extraction at
  `08_pkg/src/geecomposer/compose.py:127` correctly pick up the new names
  without any changes to compose itself?

### 2. New transform metadata tests

**File:** `08_pkg/tests/test_compose.py`, class `TestTransformMetadata`

Three new tests:

- `test_ndvi_transform_metadata_name` — calls `compose(transform=ndvi())`,
  verifies `props["geecomposer:transform"] == "ndvi"`
- `test_select_band_transform_metadata_name` — calls
  `compose(transform=select_band("B4"))`, verifies
  `props["geecomposer:transform"] == "select_band('B4')"`
- `test_expression_transform_metadata_name` — calls
  `compose(transform=expression_transform(..., name="ratio"))`, verifies
  `props["geecomposer:transform"] == "expression_transform('ratio')"`

All three use real built-in factories (not mocked callables with manual
`__name__`), and verify the actual metadata dict passed to `image.set()`.

**Review focus:**
- Would these tests have failed before the fix? (They should — the old
  closures had `__name__ == "_fn"`.)
- Do the tests import the real transform factories correctly?
- Are the assertions checking the right dict key and value?
- Is there a test for `normalized_difference()` directly (not via `ndvi()`)?
  Its `__name__` would be `"normalized_difference('B8', 'B4')"` — is this
  covered?

### 3. Sentinel-2 masking threshold test

**File:** `08_pkg/tests/test_sentinel2.py`, class `TestApplyMask`

New test `test_cloud_score_plus_mask_fn_threshold`:

- Calls `apply_mask(col, mask="s2_cloud_score_plus")`
- Extracts the mask function from `linked_col.map.call_args[0][0]`
- Builds a mock `ee.Image` and executes the mask function against it
- Verifies: `img.select("cs_cdf")`, `score_band.gte(0.6)`,
  `img.updateMask(mask_result)`

**Review focus:**
- Does extracting the mapped function from `call_args` and executing it
  against mocks actually prove the threshold behavior?
- Is the test deterministic and free of EE initialization requirements?
- Does it verify the full chain: select → gte → updateMask?
- Is the 0.6 threshold hardcoded in both the implementation and the test — if
  the threshold changes, both need updating. Is this acceptable?

### 4. P3 cleanup

**File:** `08_pkg/src/geecomposer/compose.py`

- Removed `and ds_module is not None` from the mask condition at line 106
  (was dead code — `_resolve_dataset` always returns a loader or raises)
- Removed `validate_reducer(reducer)` call at step 10 (validation now happens
  only inside `apply_reducer()`)
- Removed the `validate_reducer` import (no longer needed in compose.py)

**Review focus:**
- Is the `invalid_reducer` test still working? The previous test mocked
  `apply_reducer` and expected `compose()` to raise before calling it. With
  the validation removed from `compose()`, the test must now let the real
  `apply_reducer` run. Was this test correctly updated?
- Is there any code path in `compose()` that could pass an invalid reducer to
  `apply_reducer()` without it being caught?
- Is removing the `validate_reducer` import safe? Are there other callers?

### 5. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — test count updated to 109, notes transform
  naming fix and stable `__name__` attributes
- `08_pkg/testing_strategy.md` — corrected per-file test counts, added masking
  threshold test description and transform metadata test class
- `03_experiments/run_summary.md` — corrected test breakdown table, documented
  corrective changes
- `05_governance/review_log.md` — corrective pass entry with itemized changes
- `02_analysis/findings.md` — new findings about transform naming, single-point
  validation, review convergence

**Review focus:**
- Do the per-file test counts in `testing_strategy.md` and `run_summary.md`
  now match reality? Verify independently.
- Are the new findings in `02_analysis/findings.md` genuine insights?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/temporal.py` — unchanged
- `08_pkg/src/geecomposer/datasets/sentinel2.py` — unchanged (masking
  implementation was already correct; fix was in transform factories)
- `08_pkg/src/geecomposer/utils/metadata.py` — unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/grouping.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/export/` — placeholder, unchanged
- `08_pkg/src/geecomposer/datasets/sentinel1.py` — placeholder, unchanged
- `08_pkg/tests/test_aoi.py` — unchanged
- `08_pkg/tests/test_validation.py` — unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read review history and guidance
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (section 13 for metadata policy)
- `08_pkg/architecture_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_002.md` (the authoritative list of
  what needed to change)

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `05_governance/review_log.md`

### Step 2 — Verify the P1 transform metadata fix
Inspect the three transform factory files:
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`

For each factory:
- Confirm `_fn.__name__` is set to a stable, descriptive value.
- Verify in `.venv` that the `__name__` values are correct:
  ```python
  from geecomposer.transforms.indices import ndvi
  from geecomposer.transforms.basic import select_band, normalized_difference
  from geecomposer.transforms.expressions import expression_transform
  print(ndvi().__name__)
  print(select_band("B4").__name__)
  print(normalized_difference("B8", "B4", "nd").__name__)
  print(expression_transform("a+b", {"a": "B1"}, "out").__name__)
  ```

Then confirm `compose()` picks up these names without changes:
- `08_pkg/src/geecomposer/compose.py:127` — `getattr(transform, "__name__", None)`

### Step 3 — Verify the new transform metadata tests
Inspect `08_pkg/tests/test_compose.py`, class `TestTransformMetadata`:

- Do the three tests use real built-in factories?
- Do they verify the actual metadata dict key `"geecomposer:transform"`?
- Would they have failed before the fix (when `__name__` was `"_fn"`)?
- Is `normalized_difference` tested directly, or only via `ndvi()`?

### Step 4 — Verify the Sentinel-2 masking threshold test
Inspect `08_pkg/tests/test_sentinel2.py`:

- Does `test_cloud_score_plus_mask_fn_threshold` extract the mask function
  from `.map()` call args?
- Does it execute the function against mocks and verify the full chain:
  `select("cs_cdf")` → `gte(0.6)` → `updateMask(...)`?
- Is it deterministic and EE-initialization-free?

### Step 5 — Verify the P3 cleanup
Inspect `08_pkg/src/geecomposer/compose.py`:

- Confirm `ds_module is not None` is removed from the mask condition.
- Confirm `validate_reducer()` is no longer called directly in `compose()`.
- Confirm the `validate_reducer` import is removed.
- Check: does the `test_invalid_reducer_raises` test still work? It previously
  patched `apply_reducer` — does it now let the real `apply_reducer` run so
  the validation fires inside it?

### Step 6 — Verify governance artifact accuracy
- Run the test suite and verify 109 passed, 2 skipped:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`
- Count tests per file and compare with the counts in
  `08_pkg/testing_strategy.md` and `03_experiments/run_summary.md`.
- Check `05_governance/review_log.md` for accurate corrective pass entry.

### Step 7 — Check each original review item
For each item from `review_milestone_002.md` sections 3 and 5:

- `P1` Transform metadata naming → resolved?
- `P2` Governance test counts → resolved?
- `P2` S2 masking threshold test → resolved?
- `P3` Dead `ds_module is not None` → resolved?
- `P3` Double reducer validation → resolved?

### Step 8 — Evaluate scope discipline
- Only transform factory files, `compose.py`, and test/governance files were
  modified.
- No Sentinel-1, export, grouping, or auth work was introduced.
- No new public API surface was added.
- Placeholder modules remain placeholder.

### Step 9 — Make the closure decision
- Are all P1 and P2 items from the original review resolved?
- Are the fixes correct and complete?
- Are the new tests meaningful and not misleading?
- Are there any new issues introduced by the corrective pass?
- Is milestone 002 now closeable?
- If yes, what should milestone 003 prioritize?

### Step 10 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Sentinel-2 Compose Corrective

## 1. P1 Resolution
- Is the transform metadata naming fix correct and complete?
- Do the new tests prove the fix?

## 2. P2/P3 Item Status
For each item from the original review: resolved, honestly deferred, or
still outstanding.

## 3. New Issues
- Any correctness bugs introduced by the corrective pass
- Any test quality concerns
- Any documentation inaccuracies

## 4. Scope Discipline
- Did the corrective pass stay within scope?

## 5. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should milestone 003 prioritize?
- Known debt to carry forward

## 6. Optional Recommendations
Small items only. No new features. No Sentinel-1 logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Focus narrowly on whether the corrective pass resolves the review findings
- Distinguish clearly between confirmed issues and preferences
- Be especially rigorous about:
  - Whether the `__name__` values are stable and consistent across factories
  - Whether the `ndvi()` override of `normalized_difference()`'s `__name__` is
    correct (does the override happen after `normalized_difference` returns?)
  - Whether the `test_invalid_reducer_raises` test was correctly adapted after
    removing the `validate_reducer` call from `compose()`
  - Whether the per-file test counts in governance docs now match reality
  - Whether the masking threshold test actually proves the threshold value
- Cross-reference against:
  - `05_governance/reviews/review_milestone_002.md` (authoritative findings)
  - `geecomposer_v0.1_spec.md` section 13 (metadata policy)
  - `05_governance/review_rubric.md` (review criteria)
- Verify the 109-pass / 2-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_002_corrective.md`

Be direct and decisive. This is a corrective-pass review. The question is:
are the review findings resolved, is the metadata now useful, and can
milestone 002 close so the project can move to Sentinel-1?
