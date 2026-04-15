# Review Prompt — Core Foundations Final Closure

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the final closure pass for milestone 001, and decide whether the milestone is now genuinely closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the artifact-first framework being used,
3. the review history so far (original review → corrective pass → corrective-pass review → this final closure pass),
4. what was changed in the final closure pass,
5. whether the corrective-pass review's remaining closure blocker is resolved, whether the fix is correct, and whether milestone 001 can now be closed.

Then produce a structured review and a final closure decision.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The unit of progress is:
- artifacts advancing from one reviewable state to another

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`
- the package source is at `08_pkg/src/geecomposer/`
- the product contract lives in `geecomposer_v0.1_spec.md`
- v0.1 must support Sentinel-2 and Sentinel-1 compositing, local vector AOI inputs, built-in and custom transforms, temporal reducers, and Drive export

Current development stage:
- milestone 001 (core foundations) has been through three implementation passes and two reviews
- the original two `P1` issues were resolved in the corrective pass
- the corrective-pass review found one remaining closure blocker: malformed FeatureCollection geometry dicts leaking raw exceptions instead of `InvalidAOIError`
- **a final closure pass has just been applied — this is the primary review target**
- dataset loaders, `compose()`, export helpers, grouping, and auth remain placeholder stubs
- 76 tests pass, 3 skipped (placeholders for later milestones)

Review history:
- `05_governance/reviews/review_milestone_001.md` — original review (2 P1, several P2/P3)
- `05_governance/reviews/review_milestone_001_corrective.md` — corrective-pass review (P1s resolved, new blocker found)
- **This review** — final closure decision

---

## What the corrective-pass review found as remaining blocker

From `05_governance/reviews/review_milestone_001_corrective.md`, section 3:

> `P1` Malformed `FeatureCollection` geometry entries can still leak raw
> exceptions instead of `InvalidAOIError`. The new helper [...] calls
> `shapely.geometry.shape()` directly on each geometry dict without wrapping
> failures. [...] malformed inputs currently raise `KeyError` and
> `GeometryTypeError`, not package-level AOI errors.

The corrective-pass review also noted:

> `P3` `test_reads_pathlib_path` is redundant as written. Both
> `test_reads_geojson_file` and `test_reads_pathlib_path` call
> `read_vector_file(SAMPLE_GEOJSON_PATH)`, and `SAMPLE_GEOJSON_PATH` is
> already a `Path`.

> `P3` MultiPolygon acceptance by `ee.Geometry()` was not independently
> verified in a live initialized Earth Engine session. [...] This is not a
> blocker by itself.

---

## What was changed in the final closure pass

### 1. Malformed geometry error handling fix

**File:** `08_pkg/src/geecomposer/aoi.py`, lines 85–120

`_dissolve_feature_collection()` changes:
- The `shapely.geometry.shape(geom_dict)` call is now wrapped in a
  `try/except Exception` block
- On failure, raises `InvalidAOIError` with a message that includes the
  feature index and the original exception message:
  `"Malformed geometry in FeatureCollection feature {i}: {exc}"`
- The original exception is chained via `from exc`
- The docstring was updated to document the intended behavior: features
  without a `geometry` key are skipped, but features with a malformed
  `geometry` dict cause an immediate `InvalidAOIError`

**Design decision documented:** mixed valid/malformed FeatureCollections fail
fast on the first malformed geometry rather than silently skipping it.

**Review focus:**
- Is the `try/except Exception` too broad? Could it catch non-geometry-related
  exceptions (e.g., `MemoryError`, `SystemExit`) that should propagate? Should
  it catch a narrower set of exceptions instead?
- Is the error message clear enough? Does including the original `{exc}`
  message from shapely help or does it expose implementation internals?
- Is the feature index (`feature {i}`) correct? It uses `enumerate(features)`
  which is 0-based — is this clear enough for users?
- Is the fail-fast behavior the right choice? The alternative would be to
  collect all valid geometries and skip malformed ones, or to collect all
  errors and report them together. Is fail-fast justified given the package's
  explicit-error philosophy?
- Does the `geom_dict is None` skip (for features without a `geometry` key)
  interact correctly with the malformed-geometry catch? A feature with
  `"geometry": None` would be skipped, while a feature with
  `"geometry": {"type": "Polygon"}` (missing coordinates) would fail. Is this
  distinction correct and clear?
- Verify that the fix actually works: create test inputs with missing
  coordinates, unknown geometry types, and mixed valid/malformed collections
  and confirm they raise `InvalidAOIError` rather than `KeyError` or
  `GeometryTypeError`.

### 2. Redundant pathlib test replaced

**File:** `08_pkg/tests/test_aoi.py`

- `test_reads_pathlib_path` was replaced with `test_reads_string_path`
- The new test calls `read_vector_file(str(MULTI_FEATURE_PATH))` — passing a
  `str` path (not `Path`) to a different fixture (multi-feature, not
  single-feature)
- This addresses the corrective-pass review's `P3` finding that the original
  test was redundant

**Review focus:**
- Does the new test add genuine coverage? It exercises a `str` path (vs the
  `Path` used in other tests) and a different fixture. Is this sufficient?
- Note that `test_reads_geojson_file` already uses a `Path`
  (`SAMPLE_GEOJSON_PATH`) and `test_reads_multi_feature_file` already uses a
  `Path` (`MULTI_FEATURE_PATH`). The new test's value is specifically the
  `str()` wrapper. Is that worth a test?

### 3. New malformed-geometry tests

**File:** `08_pkg/tests/test_aoi.py`, class `TestDissolveFeatureCollection`

Three new tests added:

- `test_malformed_geometry_missing_coordinates_raises` — a feature with
  `{"type": "Polygon"}` (no `coordinates` key) raises `InvalidAOIError` with
  `"Malformed geometry"` in the message
- `test_malformed_geometry_unknown_type_raises` — a feature with
  `{"type": "Hexagon", "coordinates": []}` raises `InvalidAOIError` with
  `"Malformed geometry"` in the message
- `test_mixed_valid_and_malformed_raises` — two features where the first is
  valid (`POLYGON_WEST`) and the second is malformed (`{"type": "Polygon"}`)
  — raises `InvalidAOIError` matching `"Malformed geometry.*feature 1"`

**Review focus:**
- Do the tests cover the specific failure modes identified in the
  corrective-pass review (`KeyError` for missing coordinates,
  `GeometryTypeError` for unknown types)?
- Is the mixed test correctly asserting on `feature 1` (0-based index of the
  second feature)?
- Are there other malformed-geometry patterns worth testing? For example:
  - `"geometry": "not a dict"` (string instead of dict)
  - `"geometry": {"type": "Polygon", "coordinates": "not a list"}`
  - `"geometry": {}` (empty dict, no type key)
- Is there a test that exercises malformed geometries through the full
  `geojson_to_ee_geometry()` path (not just `_dissolve_feature_collection`
  directly)?

### 4. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — test count updated to 76, notes malformed
  geometry handling, declares milestone 001 complete
- `08_pkg/testing_strategy.md` — test count updated, malformed geometry tests
  listed, deferred items unchanged
- `05_governance/review_log.md` — final closure pass entry added with itemized
  changes and design decision
- `05_governance/risks.md` — AOI mitigation updated to include malformed
  geometry handling, `ValueError` vs `TransformError` noted as known deferred
  inconsistency
- `03_experiments/run_summary.md` — test breakdown updated, fail-fast
  rationale documented
- `02_analysis/findings.md` — finding added about fail-fast approach and the
  three-iteration review cycle

**Review focus:**
- Does `08_pkg/current_status.md` accurately declare milestone 001 complete?
- Does `05_governance/review_log.md` have enough detail for a future reader to
  understand the three-pass history?
- Are any claims in the docs overstated or inaccurate?
- Does `05_governance/risks.md` correctly identify remaining known gaps (CRS
  reprojection test, `ValueError` vs `TransformError`, MultiPolygon EE
  acceptance)?

---

## Pre-existing code that was NOT modified

The following were NOT changed in this final closure pass:
- `08_pkg/src/geecomposer/validation.py` — validation helpers, unchanged
- `08_pkg/src/geecomposer/exceptions.py` — exception hierarchy, unchanged
- `08_pkg/src/geecomposer/__init__.py` — top-level exports, unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/compose.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/grouping.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/export/` — placeholder, unchanged
- `08_pkg/src/geecomposer/datasets/` — placeholder, unchanged
- `08_pkg/src/geecomposer/transforms/` — all transform modules, unchanged
- `08_pkg/src/geecomposer/reducers/temporal.py` — reducer mapping, unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_validation.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read project guidance and review history
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (especially section 8.4)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_001.md`
- `05_governance/reviews/review_milestone_001_corrective.md`
- `05_governance/review_log.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `03_experiments/run_summary.md`

### Step 2 — Verify the malformed-geometry fix
Inspect `08_pkg/src/geecomposer/aoi.py`, specifically `_dissolve_feature_collection()`:

- Read the function line by line. Trace the code path for each malformed input
  pattern: missing coordinates, unknown geometry type, string instead of dict,
  empty dict.
- Confirm that `shapely.geometry.shape()` failures are caught and re-raised as
  `InvalidAOIError`.
- Check: is the `try/except Exception` too broad? Should it be narrower
  (e.g., `except (KeyError, TypeError, ValueError)`)? What are the actual
  exceptions shapely raises for these malformed inputs?
- Check: does the `geom_dict is None` skip path interact correctly with the
  error handling? What about `"geometry": None` vs `"geometry": {}` vs
  `"geometry": "string"`?
- Check: is `from exc` used correctly for exception chaining?
- Verify the fix works by running the test suite:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 3 — Verify the test quality
Inspect `08_pkg/tests/test_aoi.py`:

- Are the three new malformed-geometry tests sufficient to prove the blocker
  is fixed?
- Does `test_mixed_valid_and_malformed_raises` correctly verify the feature
  index in the error message?
- Is there a missing test for malformed geometries exercised through
  `geojson_to_ee_geometry()` end-to-end (not just the helper)?
- Is `test_reads_string_path` a genuine improvement over the redundant
  `test_reads_pathlib_path`?
- Count the total tests: does 76 passed / 3 skipped match?

### Step 4 — Verify the corrective-pass review items are resolved
Check each item from `review_milestone_001_corrective.md` section 3:

- `P1` Malformed geometry leaking raw exceptions — resolved?
- `P3` Redundant pathlib test — resolved?
- `P3` MultiPolygon EE acceptance — still deferred, but honestly noted?

### Step 5 — Verify scope discipline
- Only `aoi.py` and `test_aoi.py` were modified in the implementation
- No dataset, compose, export, grouping, or auth code was touched
- No new public API surface was introduced
- Placeholder modules remain placeholder

### Step 6 — Verify governance and documentation honesty
- Does `08_pkg/current_status.md` accurately reflect reality?
- Does `05_governance/review_log.md` correctly record the full three-pass
  history?
- Does `05_governance/risks.md` honestly identify remaining known gaps?
- Does `03_experiments/run_summary.md` match actual test results?
- Does `02_analysis/findings.md` provide genuine insight?

### Step 7 — Cumulative milestone assessment
Step back and assess milestone 001 as a whole, across all three passes:

- Are the foundation modules (`exceptions.py`, `validation.py`, `aoi.py`,
  `reducers/temporal.py`, `transforms/basic.py`, `transforms/indices.py`,
  `transforms/expressions.py`) trustworthy enough for dataset and compose
  work to build on?
- Are invalid inputs handled consistently across all foundation modules?
- Are there any remaining gaps that would make milestone 002 work unreliable?
- Is the test suite sufficient for the foundation scope, or are there
  important missing cases?
- Is the review rubric satisfied?

### Step 8 — Make the final closure decision
This is the primary deliverable:

- Is milestone 001 closeable? Yes / No / Conditional
- If yes: what should milestone 002 prioritize?
- If no or conditional: what specifically still needs to change?
- Are there any items that should be tracked as known debt for later?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Final Closure

## 1. Blocker Resolution
- Is the malformed-geometry fix correct?
- Is the `try/except` scope appropriate?
- Is the fail-fast design decision justified?
- Are the new tests sufficient?

## 2. Corrective-Pass Items
For each item from `review_milestone_001_corrective.md` section 3:
resolved, honestly deferred, or still outstanding.

## 3. Cumulative Foundation Quality
- Exception handling consistency across all foundation modules
- AOI normalization completeness and correctness
- Reducer and transform factory quality
- Validation coverage
- Test suite adequacy for the foundation scope

## 4. Scope Discipline
- Did the final closure pass stay within scope?

## 5. Documentation Honesty
- Are the governance artifacts accurate?
- Are any claims overstated?

## 6. Milestone Closure Decision
- **Closeable: Yes / No / Conditional**
- If yes, what should milestone 002 prioritize?
- Known debt to track

## 7. Optional Recommendations
Small items only. No new features. No dataset logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- This is a closure review — the bar is whether the foundations are
  trustworthy enough for dataset and compose work to build on
- Distinguish clearly between confirmed issues and preferences
- Be especially rigorous about:
  - Whether `try/except Exception` in `_dissolve_feature_collection` is the
    right exception scope — trace the actual shapely exceptions for each
    malformed input pattern
  - Whether the `geom_dict is None` skip and the `try/except` catch interact
    correctly for all edge cases (`None`, empty dict, string, invalid dict)
  - Whether the three new tests actually cover the `KeyError` and
    `GeometryTypeError` failure modes the corrective-pass review identified
  - Whether the test count (76 passed, 3 skipped) is accurate
  - Whether the governance artifacts are honest about both what was achieved
    and what was deferred
- Cross-reference against:
  - `05_governance/reviews/review_milestone_001.md` (original findings)
  - `05_governance/reviews/review_milestone_001_corrective.md` (corrective
    findings — the authoritative list of what needed to change)
  - `05_governance/review_rubric.md` (review criteria)
  - `geecomposer_v0.1_spec.md` section 8.4 (dissolve policy)
- Verify the 76-pass / 3-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_001_final_closure.md`

Be direct and decisive. This is the third review pass. The question is narrow:
is the malformed-geometry blocker genuinely fixed, are the foundations
trustworthy, and can the project move to milestone 002? Answer that clearly.
