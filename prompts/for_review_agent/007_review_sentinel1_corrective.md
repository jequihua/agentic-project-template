# Review Prompt — Sentinel-1 Corrective Pass

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 003 corrective pass, and decide whether milestone 003 is now closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. what the milestone 003 independent review found,
3. what was changed in the corrective pass,
4. whether the P1 filter-value validation issue is genuinely resolved, whether the tests prove it, and whether milestone 003 can now be closed.

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
- milestone 002 (Sentinel-2 compose) is closed
- milestone 003 (Sentinel-1) was implemented and independently reviewed
- **a corrective pass has just been applied — this is the primary review target**
- 132 tests pass, 1 skipped (placeholder for grouping)

Review history:
- `05_governance/reviews/review_milestone_003.md` — independent review (P1
  filter-value validation, P2 default-IW clarification, P3 compose docstring)
- **This review** — corrective-pass closure decision

---

## What the milestone 003 review found

From `05_governance/reviews/review_milestone_003.md`:

### P1 — Malformed Sentinel-1 filter values not validated

`_validate_filters()` validated unsupported filter keys but not malformed
values. The review confirmed these passed instead of failing:

- `{"instrumentMode": 123}` — non-string instrument mode
- `{"orbitPass": 123}` — non-string orbit pass
- `{"polarizations": []}` — empty polarization list
- `{"polarizations": "VV"}` — bare string iterates as `["V", "V"]`, producing
  two `listContains(..., "V")` filters instead of one `VV` filter

### P2 — Default IW behavior broader than spec wording

The spec says "default to IW when no filters are provided." The
implementation defaults to IW whenever `instrumentMode` is absent from
`filters`, even when other filters are present. The review noted this is
documented in the decision log but broader than the spec's literal wording.

### P3 — `compose()` docstring only mentions `"sentinel2"`

The `dataset` parameter docstring still read ``"sentinel2"`` only, despite
`"sentinel1"` being implemented.

---

## What was changed in the corrective pass

### 1. Filter value validation

**File:** `08_pkg/src/geecomposer/datasets/sentinel1.py`, function
`_validate_filters()`

The function now validates both keys and values:

- **Key validation** — unchanged from before (checks against
  `SUPPORTED_FILTERS`)
- **`instrumentMode` value** — must be a non-empty string; raises
  `GeeComposerError` with `"instrumentMode must be a non-empty string"` if
  not
- **`orbitPass` value** — must be a non-empty string; raises
  `GeeComposerError` with `"orbitPass must be a non-empty string"` if not
- **`polarizations` value** — must be a non-empty `list` or `tuple`; each
  element must be a non-empty string; raises `GeeComposerError` with clear
  messages including the element index for non-string entries
- The `load_collection()` docstring was updated to note that malformed values
  raise too

**Review focus:**
- Does the validation catch all four cases from the review?
  - `{"instrumentMode": 123}` — should hit the `isinstance(val, str)` check
  - `{"orbitPass": 123}` — should hit the `isinstance(val, str)` check
  - `{"polarizations": []}` — should hit the `len(val) == 0` check
  - `{"polarizations": "VV"}` — should hit the `isinstance(val, (list, tuple))`
    check, since `str` is not `list` or `tuple`
- Is the bare-string `"VV"` case definitively blocked? Trace the code: a
  `str` is not an instance of `(list, tuple)`, so it should be rejected. But
  verify this — could there be a code path where a string slips through?
- Are empty strings handled? `{"instrumentMode": ""}` and
  `{"instrumentMode": "  "}` — does `val.strip()` catch whitespace-only?
- Is the element-level validation for `polarizations` correct? It uses
  `enumerate(val)` and checks each element. Does it handle
  `["VV", ""]` (empty string element)?
- Is `GeeComposerError` the right exception type for value validation? The
  module uses it for both key and value errors. Is this consistent with the
  rest of the package?
- The review's P2 item (default IW broader than spec) was not changed. Was
  this an intentional deferral or an oversight? Check the corrective prompt
  to confirm.

### 2. New filter-value validation tests

**File:** `08_pkg/tests/test_sentinel1.py`, class `TestFilterValidation`

Six new tests:

- `test_non_string_instrument_mode_raises` — `{"instrumentMode": 123}` →
  `GeeComposerError` matching `"instrumentMode must be a non-empty string"`
- `test_non_string_orbit_pass_raises` — `{"orbitPass": 123}` →
  `GeeComposerError` matching `"orbitPass must be a non-empty string"`
- `test_empty_polarizations_list_raises` — `{"polarizations": []}` →
  `GeeComposerError` matching `"polarizations must be a non-empty list"`
- `test_string_polarizations_raises` — `{"polarizations": "VV"}` →
  `GeeComposerError` matching `"polarizations must be a non-empty list"`.
  Docstring notes this prevents the character-iteration bug.
- `test_non_string_element_in_polarizations_raises` —
  `{"polarizations": ["VV", 42]}` → `GeeComposerError` matching
  `"polarizations\\[1\\] must be a non-empty string"`
- `test_empty_string_instrument_mode_raises` — `{"instrumentMode": ""}` →
  `GeeComposerError` matching `"instrumentMode must be a non-empty string"`

**Review focus:**
- Do these tests cover the exact four cases the review identified?
- Would each test have failed before the fix?
- Is the `test_string_polarizations_raises` test the one that would have
  caught the character-iteration bug? Verify: before the fix,
  `_validate_filters({"polarizations": "VV"})` would have passed. After the
  fix, it raises.
- Are there missing edge cases? Consider:
  - `{"polarizations": ("VV",)}` — tuple input (should pass)
  - `{"orbitPass": ""}` — empty string (should fail)
  - `{"polarizations": ["VV", ""]}` — empty string element
- Is the regex `"polarizations\\[1\\]"` in the element test fragile? Could
  the error message format change?

### 3. Compose docstring fix

**File:** `08_pkg/src/geecomposer/compose.py`, line 62

Changed from:
```
Friendly preset name (``"sentinel2"``). Resolves the collection ID
```
To:
```
Friendly preset name (``"sentinel2"`` or ``"sentinel1"``). Resolves
```

**Review focus:**
- Is this the only place where the dataset preset is documented in `compose()`?
- Are there other docstrings or comments that still only mention sentinel2?

### 4. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — test count updated to 132, notes filter value
  validation
- `08_pkg/testing_strategy.md` — test_sentinel1 count updated to 19, value
  validation tests listed
- `03_experiments/run_summary.md` — corrected test breakdown, corrective
  changes documented
- `02_analysis/findings.md` — finding about bare-string polarization bug
- `05_governance/review_log.md` — corrective pass entry with itemized changes

**Review focus:**
- Do the per-file test counts match reality? Verify independently.
- Is the bare-string character-iteration finding clearly documented?
- Is the review log entry specific enough?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/temporal.py` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all unchanged
- `08_pkg/src/geecomposer/datasets/sentinel2.py` — unchanged
- `08_pkg/src/geecomposer/datasets/__init__.py` — unchanged
- `08_pkg/src/geecomposer/utils/metadata.py` — unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/grouping.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/export/` — placeholder, unchanged
- `08_pkg/tests/test_aoi.py` — unchanged
- `08_pkg/tests/test_validation.py` — unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_sentinel2.py` — unchanged
- `08_pkg/tests/test_compose.py` — unchanged
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read review history and guidance
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (section 9.2 for S1 interface)
- `08_pkg/architecture_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_003.md` (the authoritative list of
  what needed to change)

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `03_experiments/run_summary.md`
- `05_governance/review_log.md`

### Step 2 — Verify the P1 filter-value validation fix
Inspect `08_pkg/src/geecomposer/datasets/sentinel1.py`, function
`_validate_filters()`:

- Read the function line by line. Trace each of the four review cases through
  the code:
  1. `{"instrumentMode": 123}` — hits `isinstance(val, str)` → False → raises
  2. `{"orbitPass": 123}` — hits `isinstance(val, str)` → False → raises
  3. `{"polarizations": []}` — hits `len(val) == 0` → raises
  4. `{"polarizations": "VV"}` — hits `isinstance(val, (list, tuple))` → False
     (str is not list/tuple) → raises
- Verify the bare-string case is definitively blocked: a `str` is NOT an
  instance of `(list, tuple)`, so `"VV"` is caught.
- Check edge cases not in the review but potentially relevant:
  - `{"instrumentMode": " "}` — whitespace-only: `val.strip()` → empty → raises?
  - `{"polarizations": ["VV", ""]}` — empty string element: hits `pol.strip()` → empty → raises?
  - `{"polarizations": ("VV", "VH")}` — tuple: `isinstance(val, (list, tuple))` → True → passes
- Verify in `.venv` if practical:
  ```python
  from geecomposer.datasets.sentinel1 import _validate_filters
  _validate_filters({"polarizations": "VV"})  # should raise
  _validate_filters({"instrumentMode": 123})   # should raise
  ```

### Step 3 — Verify the new tests
Inspect `08_pkg/tests/test_sentinel1.py`, class `TestFilterValidation`:

- Do the six new tests cover the four review cases plus useful extras?
- Would each test have failed before the fix?
- Is `test_string_polarizations_raises` the regression test for the
  character-iteration bug?
- Are the error message patterns specific enough without being fragile?
- Run the test suite:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`
- Verify 132 passed, 1 skipped.

### Step 4 — Verify the P3 docstring fix
Inspect `08_pkg/src/geecomposer/compose.py`:

- Does the `dataset` parameter docstring now mention both presets?
- Are there other places in `compose.py` that still only mention sentinel2?

### Step 5 — Check each original review item
For each item from `review_milestone_003.md` sections 3 and 5:

- `P1` Filter value validation → resolved?
- `P1` Tests for malformed values → resolved?
- `P2` Default IW broader than spec → addressed, deferred, or unchanged?
- `P3` Compose docstring → resolved?

### Step 6 — Evaluate scope discipline
- Only `sentinel1.py`, `test_sentinel1.py`, `compose.py` (docstring only),
  and governance docs were modified
- No export, grouping, auth, or advanced SAR work introduced
- No pipeline restructuring
- Sentinel-2 code untouched

### Step 7 — Verify governance artifact accuracy
- Count tests per file and compare with `testing_strategy.md` and
  `run_summary.md`
- Check `review_log.md` for accurate corrective pass entry

### Step 8 — Make the closure decision
- Are all P1 items from the original review resolved?
- Is the bare-string polarization bug definitively prevented?
- Are there any new issues introduced by the corrective pass?
- Is milestone 003 now closeable?
- If yes, what should milestone 004 prioritize?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Sentinel-1 Corrective

## 1. P1 Resolution
- Is the filter-value validation fix correct and complete?
- Do the new tests prove the fix?
- Is the bare-string character-iteration bug definitively prevented?

## 2. Review Item Status
For each item from `review_milestone_003.md`: resolved, honestly deferred,
or still outstanding.

## 3. New Issues
- Any correctness bugs introduced by the corrective pass
- Any test quality concerns
- Any documentation inaccuracies

## 4. Scope Discipline
- Did the corrective pass stay within scope?

## 5. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should milestone 004 prioritize?
- Known debt to carry forward

## 6. Optional Recommendations
Small items only. No new features. No export/grouping logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Focus narrowly on whether the corrective pass resolves the review findings
- Distinguish clearly between confirmed issues and preferences
- Be especially rigorous about:
  - Whether `isinstance("VV", (list, tuple))` is actually `False` in Python
    (it is — but verify the code path, not just the theory)
  - Whether `val.strip()` correctly catches whitespace-only strings for
    `instrumentMode` and `orbitPass`
  - Whether the element-level check in `polarizations` catches `["VV", ""]`
  - Whether the P2 default-IW item was intentionally deferred (check the
    corrective prompt to confirm — it focused on value validation, not
    default behavior)
  - Whether the per-file test counts match the actual suite
- Cross-reference against:
  - `05_governance/reviews/review_milestone_003.md` (authoritative findings)
  - `geecomposer_v0.1_spec.md` section 9.2 (S1 interface)
  - `05_governance/review_rubric.md` (review criteria)
- Verify the 132-pass / 1-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_003_corrective.md`

Be direct and decisive. This is a corrective-pass review. The question is:
are the filter-value validation gaps closed, is the bare-string bug prevented,
and can milestone 003 close so the project can move to export and grouping?
