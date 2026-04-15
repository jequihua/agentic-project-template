# Review Prompt — Observation Count Milestone

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to evaluate the milestone 006 implementation and decide whether it is closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals and existing reducer system,
2. what was implemented in milestone 006 (count reducer),
3. whether the implementation is correct, minimal, and well-tested,
4. whether the count semantics are clearly documented.

Then produce a structured review and a closure decision.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`

Current development stage:
- milestones 001–005 closed, hardening pass complete
- **milestone 006 (observation count) has just been implemented — this is the
  primary review target**
- 176 tests pass, 0 skipped

The implementation claim is that adding `count` required only two one-line
changes (validation + reducer map) with no modifications to `compose.py`,
dataset modules, or any other package code.

---

## What was recently implemented

### 1. Reducer vocabulary extension

**File:** `08_pkg/src/geecomposer/validation.py`

`SUPPORTED_REDUCERS` changed from:
```python
("median", "mean", "min", "max", "mosaic")
```
To:
```python
("median", "mean", "min", "max", "mosaic", "count")
```

**Review focus:**
- Is this the only change needed in validation? Does `validate_reducer("count")`
  now pass?
- Does the existing parametrized `test_valid_reducers_accepted` automatically
  pick up `"count"`?

### 2. Reducer dispatch extension

**File:** `08_pkg/src/geecomposer/reducers/temporal.py`

`_REDUCER_MAP` extended with:
```python
"count": lambda col: col.count(),
```

**Review focus:**
- Does `ee.ImageCollection.count()` return an `ee.Image` where each pixel
  value is the number of non-masked images at that pixel? This is the core
  semantic question. Verify against EE documentation or known behavior.
- Is `col.count()` the right method? Earth Engine also has
  `col.reduce(ee.Reducer.count())` — are they equivalent for this use case?
- Does the `count()` method correctly count only non-masked pixels? For
  Sentinel-2 with Cloud Score+ masking, masked pixels should be excluded
  from the count. Verify this is how EE's `count()` works.
- Is the return type of `count()` consistent with other reducers? Other
  reducers return single-band or multi-band images depending on the input.
  Does `count()` return the same band structure?

### 3. Tests — count reducer

**File:** `08_pkg/tests/test_compose.py`, class `TestComposeCountReducer`

Three new tests:

- `test_sentinel2_count_with_mask` — compose with S2 + mask + count:
  - Verifies `apply_mask` called before count
  - Verifies `apply_reducer` called with `(masked_col, "count")`
  - Verifies metadata records `"count"` as the reducer
- `test_sentinel1_float_count` — compose with S1 float + filters + count:
  - Verifies `apply_reducer` called with `(col, "count")`
- `test_sentinel2_ndvi_count_with_mask_and_transform` — compose with S2 +
  mask + ndvi transform + count:
  - Verifies pipeline order: mask → transform → count
  - Verifies `apply_reducer` called with `(transformed_col, "count")`

**Review focus:**
- Do the tests use `_all_mock_modules()` correctly? The earlier milestone 004
  review found a bug where `_make_mock_s2_module()` was used outside the
  patched dict, causing assertion failures. Are these tests free of that
  pattern?
- Do the tests prove the pipeline order for count (mask → select → preprocess
  → transform → count)?
- Is there a test that exercises `count` through the real `apply_reducer`
  function (not mocked)? The reducer parametrized tests in `test_reducers.py`
  should cover this.
- Are there missing test scenarios? Consider:
  - `count` with `select` (band selection before count)
  - `count` with no masking (raw observation count)
  - `count` through `compose_yearly`

### 4. Validation test update

**File:** `08_pkg/tests/test_validation.py`

- `test_supported_reducers_is_tuple` assertion changed to `len == 6` with
  `assert "count" in SUPPORTED_REDUCERS`

**Review focus:**
- Does the parametrized `test_valid_reducers_accepted` automatically include
  `"count"` since it iterates over `SUPPORTED_REDUCERS`?

### 5. No changes to other modules

**Claimed unchanged:**
- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/datasets/sentinel1.py`
- `08_pkg/src/geecomposer/datasets/sentinel1_float.py`
- `08_pkg/src/geecomposer/datasets/sentinel2.py`
- `08_pkg/src/geecomposer/export/drive.py`
- `08_pkg/src/geecomposer/grouping.py`
- `08_pkg/src/geecomposer/auth.py`
- `08_pkg/src/geecomposer/aoi.py`
- `08_pkg/src/geecomposer/transforms/`
- All test files except `test_compose.py` and `test_validation.py`
- `08_pkg/pyproject.toml`

**Review focus:**
- Verify the claim that only `validation.py` and `reducers/temporal.py` were
  changed in the implementation. This is the strongest signal that the reducer
  dispatch pattern is well-designed — adding a new reducer should require no
  orchestration changes.

### 6. Governance and documentation

**Files updated:**
- `08_pkg/current_status.md` — six reducers listed, 176 tests
- `08_pkg/testing_strategy.md` — per-file counts updated
- `03_experiments/run_summary.md` — M006 test breakdown
- `05_governance/review_log.md` — M006 implementation entry
- `02_analysis/findings.md` — count semantics finding

**Review focus:**
- Do per-file test counts match reality?
- Is the count-semantics finding clear about the pipeline-position dependency?
- Is the risk about count semantics (S2 masked = clear observations, S1 =
  acquisitions) documented in `05_governance/risks.md`?

---

## Instructions

### Step 1 — Read project guidance
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (section 11 for reducer system)
- `08_pkg/architecture_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/risks.md`
- `docs/GEECOMPOSER_MILESTONE_006_OBSERVATION_COUNT.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `05_governance/review_log.md`

### Step 2 — Verify the implementation is truly two lines
Inspect:
- `08_pkg/src/geecomposer/validation.py` — one tuple entry added?
- `08_pkg/src/geecomposer/reducers/temporal.py` — one dict entry added?

Then verify nothing else changed:
- `08_pkg/src/geecomposer/compose.py` — unchanged?
- `08_pkg/src/geecomposer/datasets/` — all unchanged?
- `08_pkg/src/geecomposer/export/` — unchanged?
- `08_pkg/src/geecomposer/grouping.py` — unchanged?

### Step 3 — Verify count semantics
This is the most important semantic question:

- Does `ee.ImageCollection.count()` return per-pixel counts of non-masked
  images? If a pixel is masked in some images, does it contribute 0 to the
  count for that pixel?
- Is this behavior consistent for:
  - Sentinel-2 after Cloud Score+ masking (clear-observation count)?
  - Sentinel-1 / S1 float without masking (acquisition count)?
  - Collections after transform (valid transformed-image count)?

If you cannot verify against live EE, note this as a deferred validation
item rather than a confirmed issue.

### Step 4 — Evaluate the tests
Inspect:
- `08_pkg/tests/test_compose.py` (new `TestComposeCountReducer` class)
- `08_pkg/tests/test_reducers.py` (parametrized dispatch)
- `08_pkg/tests/test_validation.py` (parametrized validation + constant)

- Do the compose count tests use `_all_mock_modules()` correctly (from the
  dict, not separate fresh mocks)?
- Do the parametrized reducer tests in `test_reducers.py` automatically
  include `count`?
- Is the NDVI count test proving the full pipeline order
  (mask → transform → count)?

Run the suite:
`.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 5 — Evaluate scope discipline
- No seasonal/monthly grouping added
- No count-specific helper functions added
- No dataset-specific count logic added
- No compose changes made
- No export changes made

### Step 6 — Evaluate documentation
- Is the count-semantics difference (S2 clear obs vs S1 acquisitions) clearly
  documented?
- Are per-file test counts accurate?
- Is the review log entry specific enough?

### Step 7 — Produce a structured review

# Repo Review — Observation Count

## 1. Implementation Assessment
- Is the two-line claim accurate?
- Is `col.count()` the correct EE method?
- Are count semantics correct for masked vs unmasked collections?

## 2. Test Quality
- Do the compose count tests prove pipeline ordering?
- Are parametrized tests automatically covering count?
- Any missing scenarios?

## 3. Scope Discipline
- Did the milestone stay narrow?
- Was compose.py truly untouched?

## 4. Documentation and Governance
- Are count semantics documented?
- Are per-file counts accurate?

## 5. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should come next?
- Known debt

## 6. Optional Recommendations
Small items only.

---

## Review style constraints

- Be concrete and repo-aware
- This is a narrow reducer extension — the bar is whether it's correct,
  minimal, and well-tested
- Be especially rigorous about:
  - Whether `ee.ImageCollection.count()` counts non-masked pixels (this is
    the core semantic claim — if it counts ALL pixels regardless of mask,
    the entire milestone's value proposition is wrong)
  - Whether the compose count tests use `_all_mock_modules()` correctly
    (learned from M004 review's mock-dict bug)
  - Whether the two-line implementation claim is honest — verify no other
    source files were modified
  - Whether the parametrized tests in `test_reducers.py` and
    `test_validation.py` automatically include count without explicit new
    test methods
  - Whether per-file test counts match the actual suite
- Cross-reference against:
  - `docs/GEECOMPOSER_MILESTONE_006_OBSERVATION_COUNT.md` for milestone scope
  - `geecomposer_v0.1_spec.md` section 11 for reducer system design
  - `05_governance/review_rubric.md` for review criteria
  - `05_governance/risks.md` for documented count-semantics risk
- Verify the 176-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_006.md`

Be direct. This should be a quick review — the implementation is small. The
key questions are: is `col.count()` semantically correct for observation
counting, is the two-line implementation claim honest, and do the tests prove
the right pipeline ordering?
