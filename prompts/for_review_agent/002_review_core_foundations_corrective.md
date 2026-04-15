# Review Prompt — Core Foundations Corrective Pass

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the most recent corrective pass, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the artifact-first framework being used,
3. the current stage of development,
4. what was changed in the corrective pass following the milestone 001 independent review,
5. whether the two `P1` issues are genuinely resolved, whether new tests are meaningful, and whether milestone 001 is now closeable.

Then produce a structured review.

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
- milestone 001 (core foundations) was implemented and independently reviewed
- the independent review found two `P1` issues and several `P2`/`P3` items
- **a corrective pass has just been applied — this is the primary review target**
- dataset loaders, `compose()`, export helpers, grouping, and auth remain placeholder stubs
- 73 tests pass, 3 skipped (placeholders for later milestones)

Current milestone status:
- **Milestone 001: Core foundations — corrective pass applied, pending closure decision**
- Milestone 002: Sentinel-2 dataset support and compose orchestration (NEXT)
- Milestone 003: Sentinel-1 dataset support (FUTURE)
- Milestone 004: Drive export helper and yearly grouping (FUTURE)

---

## What the independent review found

The full review is in `05_governance/reviews/review_milestone_001.md`. The key
findings were:

### P1 issues (must fix before closing)

1. **GeoJSON FeatureCollection AOIs silently discard every feature except the
   first.** In `geojson_to_ee_geometry()`, multi-feature FeatureCollection
   dicts took only `features[0]`, discarding the rest. This conflicted with
   the spec's recommendation to dissolve multi-feature inputs (section 8.4)
   and made dict-based AOIs behave differently from file-based AOIs, where
   `read_vector_file()` dissolves all features.

2. **`validate_reducer()` and `validate_dataset()` raise raw `AttributeError`
   on non-string input.** Both functions called `.strip()` before checking
   type, so `None` and numeric inputs crashed with `AttributeError` instead of
   raising `InvalidReducerError` / `DatasetNotSupportedError`.

### P2 issues

- AOI test suite missing `pathlib.Path` coverage, reprojection test, and
  multi-feature GeoJSON case.

### P3 issues

- `_REDUCER_MAP` typed as `dict[str, callable]` (lowercase, not valid typing).
- Dead `_is_ee_type()` helper left in `aoi.py`.
- `ValueError` vs `TransformError` inconsistency in transform factories
  (undocumented).

---

## What was changed in the corrective pass

### 1. FeatureCollection dissolve fix

**File:** `08_pkg/src/geecomposer/aoi.py`

Changes:
- Added `_dissolve_feature_collection(features)` helper at line 85–109 that
  uses `shapely.geometry.shape` and `shapely.ops.unary_union` to dissolve all
  feature geometries into a single geometry dict
- Modified `geojson_to_ee_geometry()` FeatureCollection branch (line 131–136)
  to call `_dissolve_feature_collection()` instead of taking
  `features[0].get("geometry")`
- Updated module docstring to document the dissolve-by-default policy
- Updated `geojson_to_ee_geometry()` docstring to describe FeatureCollection
  dissolve behavior

**What was removed:**
- Dead `_is_ee_type()` helper (was at lines 22–29, no longer present)

**Review focus:**
- Is `shapely.ops.unary_union` the right dissolve operation? It is different
  from `geopandas.GeoSeries.union_all()` used in `read_vector_file()` — do
  they produce equivalent results for the same inputs?
- Does `_dissolve_feature_collection` correctly handle features where
  `feat.get("geometry")` returns a dict that `shapely.geometry.shape()` can
  parse? What about malformed geometry dicts?
- The function skips features without geometry (returns `None` from
  `feat.get("geometry")`) — is this the right behavior, or should it raise?
- Does the dissolved `__geo_interface__` dict always produce something
  `ee.Geometry()` accepts? (MultiPolygon results from non-adjacent inputs?)
- Is the lazy import of `shapely.geometry.shape` and `shapely.ops.unary_union`
  inside `_dissolve_feature_collection` appropriate, or should these be
  top-level imports since `shapely` is a declared dependency?

### 2. Validation non-string input fix

**File:** `08_pkg/src/geecomposer/validation.py`

Changes:
- `validate_reducer()` now checks `isinstance(reducer_name, str)` before
  calling `.strip()`, raising `InvalidReducerError` with
  `"must be a string, got {type}"` for non-string input
- `validate_dataset()` now checks `isinstance(dataset_name, str)` before
  calling `.strip()`, raising `DatasetNotSupportedError` with
  `"must be a string, got {type}"` for non-string input

**Review focus:**
- Is `InvalidReducerError` the right exception for a type error on the reducer
  name? One could argue a type error is different from an unsupported reducer
  name. Is this worth distinguishing, or is keeping the exception vocabulary
  small the right call?
- The error message says `"must be a string"` — is this clear enough for a
  user who passes, say, a list of reducer names?

### 3. Reducer type annotation fix

**File:** `08_pkg/src/geecomposer/reducers/temporal.py`

Change:
- `_REDUCER_MAP` annotation changed from `dict[str, callable]` to
  `dict[str, Callable[[ee.ImageCollection], ee.Image]]`
- Added `from typing import Callable` import

**Review focus:** Is the annotation accurate? The lambdas return whatever the
EE method returns, which is typed as `ee.Image` — but this is a lazy EE
computation object. Is the annotation precise enough?

### 4. New tests — dissolve behavior

**File:** `08_pkg/tests/test_aoi.py`

New test class `TestDissolveFeatureCollection` (4 tests):
- `test_single_feature_returns_geometry` — single-feature list produces a
  geometry dict
- `test_multi_feature_dissolves` — two-feature list produces Polygon or
  MultiPolygon
- `test_multi_feature_bounds_cover_both` — dissolved geometry bounds span both
  input polygons (verifies with shapely bounds and `pytest.approx`)
- `test_no_valid_geometries_raises` — features without geometry dicts raise
  `InvalidAOIError`

Modified test class `TestGeojsonToEeGeometry`:
- `test_feature_collection_dict` renamed to
  `test_single_feature_collection_dissolves` — now verifies the dissolved
  geometry dict is passed to `ee.Geometry`, not just the first feature's
  geometry directly
- New `test_multi_feature_collection_dissolves_all` — verifies multi-feature
  FeatureCollection dissolves all geometries and bounds span both polygons

New tests in `TestReadVectorFile`:
- `test_reads_multi_feature_file` — reads the multi-feature fixture and
  verifies dissolved bounds
- `test_reads_pathlib_path` — passes `pathlib.Path` to `read_vector_file`

New test in `TestToEeGeometry`:
- `test_pathlib_path_delegates_to_file_reader` — `pathlib.Path` input routes
  through `read_vector_file`

**New fixture:** `08_pkg/tests/fixtures/multi_feature_aoi.geojson` — two
non-adjacent polygons (west and east of Madrid) for dissolve verification.

**Review focus:**
- Do the dissolve tests actually verify that ALL features are included, not
  just some? The bounds check is a good proxy — but is it sufficient?
- The `test_single_feature_collection_dissolves` test verifies the mock
  `ee.Geometry` was called with a dict containing `type` — but does it verify
  the dict is actually a valid dissolved geometry, or just any dict?
- Is the multi-feature fixture well-designed? The two polygons are
  non-adjacent — does this test the MultiPolygon result path?
- Is there a test for a FeatureCollection where some features have geometry
  and some don't? (The `_dissolve_feature_collection` skips None geometries.)
- The `test_reads_pathlib_path` test calls `read_vector_file(SAMPLE_GEOJSON_PATH)` where `SAMPLE_GEOJSON_PATH` is already a `Path` — this
  is the same as `test_reads_geojson_file`. Does it actually add value, or
  should the pathlib test use a different fixture or assertion?

### 5. New tests — validation edge cases

**File:** `08_pkg/tests/test_validation.py`

New tests in `TestValidateReducer`:
- `test_none_raises_package_error` — `None` raises `InvalidReducerError`
- `test_int_raises_package_error` — `42` raises `InvalidReducerError`

New tests in `TestValidateDataset`:
- `test_none_raises_package_error` — `None` raises `DatasetNotSupportedError`
- `test_int_raises_package_error` — `123` raises `DatasetNotSupportedError`

**Review focus:**
- Are there other non-string types worth testing? (list, dict, bool, float)
- Should there be a test that the error message includes the actual type name?

### 6. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — updated test count to 73, noted corrective pass
  and multi-feature dissolve behavior
- `08_pkg/testing_strategy.md` — updated test counts, added new fixture
  description, documented verification command with `--basetemp`, noted CRS
  reprojection test deferral
- `05_governance/review_log.md` — added corrective pass entry with itemized
  changes
- `05_governance/risks.md` — updated AOI mitigation, noted two dissolve code
  paths, noted CRS reprojection test gap
- `03_experiments/run_summary.md` — updated test breakdown table, added
  corrective pass changes section, updated observations
- `02_analysis/findings.md` — added findings about dissolve consistency,
  validation guard, and two dissolve code paths

**Review focus:**
- Do the docs accurately reflect the corrective pass?
- Is the CRS reprojection test deferral noted honestly with rationale?
- Does `risks.md` correctly describe the two dissolve code paths
  (`geopandas.union_all` vs `shapely.ops.unary_union`) as a known design
  choice rather than a risk?
- Is the `review_log.md` entry specific enough that a future reader can
  understand what changed without reading the full diff?

---

## Pre-existing code that was NOT modified

The following files were NOT changed during this corrective pass:
- `08_pkg/src/geecomposer/__init__.py` — top-level exports, unchanged
- `08_pkg/src/geecomposer/exceptions.py` — exception hierarchy, unchanged
- `08_pkg/src/geecomposer/auth.py` — authentication placeholder, unchanged
- `08_pkg/src/geecomposer/compose.py` — compose orchestration placeholder,
  unchanged
- `08_pkg/src/geecomposer/grouping.py` — grouped composition placeholder,
  unchanged
- `08_pkg/src/geecomposer/export/drive.py` — Drive export placeholder,
  unchanged
- `08_pkg/src/geecomposer/datasets/` — all dataset modules, unchanged
- `08_pkg/src/geecomposer/transforms/` — all transform modules, unchanged
- `08_pkg/src/geecomposer/utils/` — utility modules, unchanged
- `08_pkg/tests/test_reducers.py` — reducer tests, unchanged
- `08_pkg/tests/test_transforms.py` — transform tests, unchanged
- `08_pkg/tests/test_public_api.py` — public API test, unchanged
- `08_pkg/tests/conftest.py` — test configuration, unchanged
- `08_pkg/pyproject.toml` — package configuration, unchanged

---

## Instructions

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (especially sections 8, 8.2, 8.4)
- `08_pkg/CONTEXT.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_rubric.md`
- `05_governance/reviews/review_milestone_001.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`

### Step 2 — Verify the P1 FeatureCollection fix
Inspect `08_pkg/src/geecomposer/aoi.py`:

- Read `_dissolve_feature_collection()` line by line. Trace the code path for
  a two-feature FeatureCollection: does every feature's geometry get included?
- Compare the dissolve behavior with `read_vector_file()`. File-based AOIs
  use `geopandas.GeoSeries.union_all()`, while dict-based AOIs use
  `shapely.ops.unary_union`. Are these semantically equivalent?
- What does `_dissolve_feature_collection` return for non-adjacent polygons?
  Is a MultiPolygon result valid input for `ee.Geometry()`?
- Is the error handling complete? What happens if a feature has a geometry dict
  that `shapely.geometry.shape()` cannot parse?
- Is the previous first-feature-only behavior completely eliminated? Search
  for any remaining `features[0]` references.

### Step 3 — Verify the P1 validation fix
Inspect `08_pkg/src/geecomposer/validation.py`:

- Confirm that `None`, `int`, `list`, and other non-string types all hit the
  type guard before `.strip()`.
- Is the error message clear and actionable?
- Is using `InvalidReducerError` for type errors the right choice, or should
  there be a separate exception path? Consider the tradeoff between exception
  vocabulary size and error specificity.

### Step 4 — Verify the P3 fixes
- Confirm `_is_ee_type()` is no longer in `aoi.py`.
- Confirm `_REDUCER_MAP` annotation uses `Callable` from `typing`.

### Step 5 — Evaluate new tests
Inspect `08_pkg/tests/test_aoi.py` and `08_pkg/tests/test_validation.py`:

- Are the dissolve tests meaningful? Do they actually prove that multi-feature
  inputs are dissolved, not just that some geometry is returned?
- Is the bounds-checking approach in `test_multi_feature_bounds_cover_both`
  a reliable proxy for "all features were included"?
- Does `test_reads_pathlib_path` add genuine coverage, or is it redundant with
  `test_reads_geojson_file` since `SAMPLE_GEOJSON_PATH` is already a `Path`?
- Are the validation non-string tests sufficient? Should they also verify the
  error message content?
- Run the full test suite to verify the 73-pass / 3-skip claim:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 6 — Evaluate remaining P2/P3 items from the original review
Check whether the corrective pass addressed or deferred each original finding:

- `P2` AOI tests for `pathlib.Path` — addressed?
- `P2` AOI reprojection test — addressed or honestly deferred?
- `P2` Multi-feature GeoJSON test — addressed?
- `P3` `callable` vs `Callable` — addressed?
- `P3` Dead `_is_ee_type()` — addressed?
- `P3` `ValueError` vs `TransformError` in transform factories — addressed,
  deferred, or neither?

### Step 7 — Evaluate scope discipline
Verify that the corrective pass stayed within scope:

- No dataset-specific logic introduced
- No `compose()` orchestration work
- No export helper implementations
- No grouping logic
- No new public API surface unrelated to the review findings
- Only `aoi.py`, `validation.py`, `reducers/temporal.py`, and their tests
  were modified
- Placeholder modules remain honestly placeholder

### Step 8 — Evaluate governance and documentation honesty
- Does `08_pkg/current_status.md` accurately reflect the post-corrective state?
- Does `08_pkg/testing_strategy.md` honestly describe what is and isn't tested?
- Does `05_governance/review_log.md` correctly record the corrective pass?
- Does `05_governance/risks.md` accurately describe the remaining gaps?
- Does `03_experiments/run_summary.md` match the actual test results?
- Does `02_analysis/findings.md` add genuine insight about the corrective pass?

### Step 9 — Make the closure decision
This is the primary deliverable of this review:

- Are both P1 issues genuinely resolved?
- Are the fixes correct and complete?
- Are the new tests meaningful and not misleading?
- Are there any new issues introduced by the corrective pass?
- Is milestone 001 now closeable?
- If not, what specifically remains?

### Step 10 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Corrective Pass

## 1. P1 Resolution Assessment
- Is the FeatureCollection dissolve fix correct and complete?
- Is the validation type-guard fix correct and complete?
- Are both fixes tested meaningfully?

## 2. P2/P3 Item Status
For each item from the original review, state: resolved, honestly deferred,
or still outstanding.

## 3. New Issues
- Any correctness bugs introduced by the corrective pass
- Any test quality concerns
- Any documentation inaccuracies

## 4. Scope Discipline
- Did the corrective pass stay within scope?
- Were any unrelated changes introduced?

## 5. Milestone Closure Decision
- Is milestone 001 closeable? Yes / No / Conditional
- If conditional, what specifically must change?
- If yes, what should milestone 002 prioritize?

## 6. Optional Recommendations
Small improvements only. No new features. No dataset logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- Focus narrowly on whether the corrective pass resolves the review findings
- Distinguish clearly between confirmed issues and subjective preferences
- Be especially rigorous about:
  - Whether `_dissolve_feature_collection` and `read_vector_file` produce
    equivalent results for the same multi-feature input
  - Whether `ee.Geometry()` accepts MultiPolygon GeoJSON dicts (the result of
    dissolving non-adjacent polygons)
  - Whether the `test_reads_pathlib_path` test adds genuine coverage
  - Whether any `features[0]` references remain in `aoi.py`
  - Whether the validation type guard is reached before `.strip()` for all
    non-string types
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` section 8.4 for dissolve policy
  - `05_governance/reviews/review_milestone_001.md` for the original findings
  - `05_governance/review_rubric.md` for review criteria
- Verify the 73-pass / 3-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_001_corrective.md`

Be focused and direct. This is a corrective-pass review — the bar is whether
the P1 issues are genuinely fixed, the tests prove it, the docs are honest,
and milestone 001 is safe to close so that dataset and orchestration work can
begin.

Be strict but fair.