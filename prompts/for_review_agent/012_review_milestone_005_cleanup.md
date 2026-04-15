# Review Prompt — Milestone 005 Cleanup and Final Close

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to evaluate the milestone 005 cleanup pass and decide whether milestone 005 is now fully closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. what the milestone 005 independent review asked for,
2. what the cleanup pass changed,
3. whether the docstring, documentation, and shared-helper extraction are correct and complete,
4. whether milestone 005 can now be closed.

Then produce a structured review and a closure decision.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`

Current development stage:
- milestones 001–004 closed, hardening pass complete
- milestone 005 (sentinel1_float) was implemented and independently reviewed
- **a cleanup pass has just been applied — this is the primary review target**
- 171 tests pass, 0 skipped

The milestone 005 review (`05_governance/reviews/review_milestone_005.md`)
found the milestone closeable with one minor follow-up: `compose()` docstring
should mention `sentinel1_float`.

---

## What the milestone 005 review asked for

From `05_governance/reviews/review_milestone_005.md`:

- **Minor follow-up**: `compose()` docstring should mention `sentinel1_float`
  alongside the existing `sentinel2` and `sentinel1` presets.
- **Optional**: the private cross-module import of `_validate_filters` from
  `sentinel1.py` into `sentinel1_float.py` was a mild boundary smell.

---

## What was changed in the cleanup pass

### 1. `compose()` docstring fix

**File:** `08_pkg/src/geecomposer/compose.py`

The `dataset` parameter docstring was changed from:

```
Friendly preset name (``"sentinel2"`` or ``"sentinel1"``). Resolves
the collection ID and enables dataset-specific loading and masking.
```

To:

```
Friendly preset name: ``"sentinel2"``, ``"sentinel1"`` (dB), or
``"sentinel1_float"`` (linear units). Resolves the collection ID
and enables dataset-specific loading and masking.
```

**Review focus:**
- Does the new wording mention all three presets?
- Are the parenthetical hints (dB, linear units) helpful and accurate?
- Is there any other place in `compose.py` that should also mention
  `sentinel1_float`?

### 2. `sentinel1.py` module docstring update

**File:** `08_pkg/src/geecomposer/datasets/sentinel1.py`

Module docstring changed from a generic "Sentinel-1 dataset helpers" to
explicitly state:
- This module handles dB-scaled imagery (`COPERNICUS/S1_GRD`)
- Band values are in dB scale
- For ratio features, use `sentinel1_float` instead

**Review focus:**
- Is the cross-reference to `sentinel1_float` clear?
- Would a user reading this docstring understand the physical difference?

### 3. README updates

**File:** `08_pkg/README.md`

- Feature list updated to mention "Sentinel-1 float (linear units)"
- New section "3b. Compose A Sentinel-1 Float Image (Linear Units)" added
  with a VH/VV expression transform example
- A callout block explains when to use `sentinel1` vs `sentinel1_float`

**Review focus:**
- Is the new example correct and consistent with the package API?
- Is the callout block accurate about dB vs linear semantics?
- Does the README now give a complete picture of the three dataset presets?

### 4. Shared filter helper extraction

**New file:** `08_pkg/src/geecomposer/datasets/_sentinel1_filters.py`

Contains:
- `SUPPORTED_FILTERS` tuple
- `DEFAULT_INSTRUMENT_MODE` constant
- `validate_filters()` function (the full key + value validation logic)

**Modified files:**
- `sentinel1.py` — now imports `SUPPORTED_FILTERS`, `DEFAULT_INSTRUMENT_MODE`,
  and `validate_filters` from `_sentinel1_filters` instead of defining them
  locally
- `sentinel1_float.py` — now imports from `_sentinel1_filters` instead of
  from `sentinel1`

**Test files updated:**
- `test_sentinel1.py` — imports `validate_filters` from
  `geecomposer.datasets._sentinel1_filters` (aliased as `_validate_filters`
  for test compatibility)
- `test_sentinel1_float.py` — same import change

**Review focus — this is the most important change to verify:**
- Is the extraction behavior-preserving? The validation logic in
  `_sentinel1_filters.py` should be identical to what was previously in
  `sentinel1.py`.
- Do both `sentinel1.py` and `sentinel1_float.py` import the same three
  symbols from the shared module?
- Is the filter-application code in `load_collection()` still duplicated
  between the two modules? (It should be — only the validation was extracted,
  not the loading logic.)
- Do the tests still pass with the changed import paths? The test functions
  call the same `_validate_filters` local name — only the import source
  changed.
- Is `_sentinel1_filters.py` (underscore prefix) appropriately marked as
  internal? It's a package-internal helper, not a public API.
- Does `datasets/__init__.py` remain unchanged? (It should not export from
  `_sentinel1_filters`.)
- Is the naming consistent? The shared module uses `validate_filters`
  (no underscore) and `DEFAULT_INSTRUMENT_MODE` (no underscore), while the
  old sentinel1 module used `_validate_filters` and `_DEFAULT_INSTRUMENT_MODE`
  (with underscores). Is this a deliberate cleanup, and is it safe?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/compose.py` — only docstring changed (no logic)
- `08_pkg/src/geecomposer/auth.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/` — unchanged
- `08_pkg/src/geecomposer/transforms/` — unchanged
- `08_pkg/src/geecomposer/datasets/sentinel2.py` — unchanged
- `08_pkg/src/geecomposer/grouping.py` — unchanged
- `08_pkg/src/geecomposer/export/` — unchanged
- `08_pkg/src/geecomposer/utils/` — unchanged
- `08_pkg/tests/test_auth.py` — unchanged
- `08_pkg/tests/test_aoi.py` — unchanged
- `08_pkg/tests/test_compose.py` — unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_sentinel2.py` — unchanged
- `08_pkg/tests/test_export_drive.py` — unchanged
- `08_pkg/tests/test_grouping.py` — unchanged
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/tests/test_validation.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read review history
- `05_governance/reviews/review_milestone_005.md` (what was asked for)
- `05_governance/review_log.md` (cleanup pass entry)

### Step 2 — Verify the docstring fix
Inspect `08_pkg/src/geecomposer/compose.py`:
- Does the `dataset` parameter mention all three presets?
- Search for any other references to dataset presets in compose.py that
  should also be updated.

### Step 3 — Verify the module docstring and README
- `08_pkg/src/geecomposer/datasets/sentinel1.py` — clear about dB semantics?
- `08_pkg/src/geecomposer/datasets/sentinel1_float.py` — already clear
  (check unchanged)?
- `08_pkg/README.md` — new section correct? Callout accurate?

### Step 4 — Verify the shared filter extraction
This is the most important step.

Inspect `08_pkg/src/geecomposer/datasets/_sentinel1_filters.py`:
- Compare the `validate_filters()` body with the old `_validate_filters()`
  body from sentinel1.py (from the previous version). Are they identical in
  logic?
- Check that `SUPPORTED_FILTERS` and `DEFAULT_INSTRUMENT_MODE` match the
  previous values.

Inspect `08_pkg/src/geecomposer/datasets/sentinel1.py`:
- Confirm it imports from `_sentinel1_filters`.
- Confirm it no longer defines `_validate_filters`, `SUPPORTED_FILTERS`,
  or `_DEFAULT_INSTRUMENT_MODE` locally.
- Confirm `load_collection` calls `validate_filters(filters)` (no underscore).

Inspect `08_pkg/src/geecomposer/datasets/sentinel1_float.py`:
- Confirm it also imports from `_sentinel1_filters` (not from `sentinel1`).

Inspect `08_pkg/src/geecomposer/datasets/__init__.py`:
- Confirm it does NOT export from `_sentinel1_filters`.

Inspect test imports:
- `08_pkg/tests/test_sentinel1.py` — imports `validate_filters` from
  `_sentinel1_filters`?
- `08_pkg/tests/test_sentinel1_float.py` — same?

### Step 5 — Run the test suite
`.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

Verify 171 passed, 0 skipped.

### Step 6 — Verify governance accuracy
- `05_governance/review_log.md` — cleanup pass recorded?
- `02_analysis/findings.md` — shared helper finding present?

### Step 7 — Make the closure decision

- Is the docstring follow-up from the M005 review resolved?
- Is the shared-helper extraction behavior-preserving?
- Are any new issues introduced?
- Is milestone 005 now fully closeable?

### Step 8 — Produce a structured review

# Repo Review — Milestone 005 Cleanup

## 1. Docstring and Documentation
- Is the compose docstring now accurate?
- Is the README sentinel1_float section correct?
- Is the sentinel1 module docstring clear about dB semantics?

## 2. Shared Filter Extraction
- Is the extraction behavior-preserving?
- Is the import structure clean?
- Is the naming change (underscore removal) safe?
- Do both dataset modules use the shared helper correctly?
- Do the tests import from the right place?

## 3. New Issues
- Any bugs introduced?
- Any test concerns?
- Any documentation inaccuracies?

## 4. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should come next?

## 5. Optional Recommendations
Small items only.

---

## Review style constraints

- Be concrete and repo-aware
- Focus on whether the cleanup resolves the review follow-up and whether the
  extraction is behavior-preserving
- Be especially rigorous about:
  - Whether `validate_filters()` in `_sentinel1_filters.py` is logically
    identical to the old `_validate_filters()` in `sentinel1.py`
  - Whether the naming change from `_validate_filters` / `_DEFAULT_INSTRUMENT_MODE`
    to `validate_filters` / `DEFAULT_INSTRUMENT_MODE` (no underscore) has any
    import or visibility implications
  - Whether `datasets/__init__.py` correctly avoids exporting internal helpers
  - Whether the README example uses the correct API (expression_transform
    import path, compose kwargs)
  - Whether test behavior is unchanged despite the import path change
- Verify the 171-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_005_cleanup.md`

Be direct. This is a small cleanup review. The question is: does the docstring
fix resolve the review follow-up, is the shared-helper extraction clean and
safe, and can milestone 005 close?
