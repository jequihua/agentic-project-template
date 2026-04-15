# Review Prompt — Core Foundations Milestone Implementation

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the most recent implementation work, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the artifact-first framework being used,
3. the current stage of development,
4. what was recently implemented in the core foundations milestone (milestone 001),
5. whether the implementation is correct, well-placed, appropriately scoped, and aligned with the intended architecture.

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
- the repository was adapted from a generic artifact-first template into a `geecomposer`-specific development workspace
- the package scaffold (directory structure, pyproject.toml, placeholder modules, `__init__.py` exports) was created before this milestone
- **milestone 001 (core foundations) has just been implemented — this is the primary review target**
- dataset loaders (Sentinel-1, Sentinel-2) are NOT yet implemented (placeholder)
- `compose()` orchestration is NOT yet implemented (placeholder)
- export helpers (`export_to_drive()`) are NOT yet implemented (placeholder)
- grouped composition (`compose_yearly()`) is NOT yet implemented (placeholder)
- authentication (`initialize()`) is NOT yet implemented (placeholder)
- 61 tests pass, 3 skipped (placeholders for later milestones)

Current milestone status:
- **Milestone 001: Core foundations (JUST COMPLETED — review target)**
- Milestone 002: Sentinel-2 dataset support and compose orchestration (NEXT)
- Milestone 003: Sentinel-1 dataset support (FUTURE)
- Milestone 004: Drive export helper and yearly grouping (FUTURE)

---

## What was recently implemented

The core foundations milestone implements the shared building blocks that all
later milestones (dataset loaders, compose orchestration, exports, grouping)
depend on. No dataset-specific code, no composition orchestration, and no
export logic was introduced.

### 1. Custom exceptions

**File:** `08_pkg/src/geecomposer/exceptions.py`

Defines a focused exception hierarchy:
- `GeeComposerError` — base exception
- `InvalidAOIError` — raised when AOI input cannot be normalized
- `InvalidReducerError` — raised when reducer name is unsupported
- `DatasetNotSupportedError` — raised when dataset preset is unsupported
- `TransformError` — raised when a transform is invalid or returns unexpected result

**Review focus:** Is the hierarchy sufficient for the v0.1 scope? Are any
exception types missing or premature? Is `TransformError` used anywhere in the
current implementation, or is it declared but unused?

### 2. Validation helpers and shared constants

**File:** `08_pkg/src/geecomposer/validation.py`

New implementation (previously only constants):
- `SUPPORTED_DATASETS` tuple: `("sentinel1", "sentinel2")`
- `SUPPORTED_REDUCERS` tuple: `("median", "mean", "min", "max", "mosaic")`
- `SUPPORTED_AOI_VECTOR_EXTENSIONS` tuple: `(".geojson", ".json", ".shp", ".gpkg")`
- `validate_reducer(reducer_name)` — normalizes to lowercase, validates against `SUPPORTED_REDUCERS`, raises `InvalidReducerError`
- `validate_dataset(dataset_name)` — normalizes to lowercase, validates against `SUPPORTED_DATASETS`, raises `DatasetNotSupportedError`

**Review focus:** Are the validation functions called from the right places?
Is case-insensitive normalization appropriate for reducer and dataset names?
Should `validate_reducer` be called in `apply_reducer` or should it be the
caller's responsibility? Is `.json` a reasonable AOI vector extension (it's
ambiguous — could be GeoJSON or arbitrary JSON)?

### 3. AOI normalization

**File:** `08_pkg/src/geecomposer/aoi.py`

Full implementation (previously all `NotImplementedError` stubs):
- `to_ee_geometry(aoi)` — top-level normalizer dispatching on type:
  - `ee.Geometry` → returned as-is
  - `ee.Feature` → `.geometry()` extracted
  - `ee.FeatureCollection` → `.geometry()` extracted
  - `dict` → delegates to `geojson_to_ee_geometry()`
  - `str` or `pathlib.Path` → delegates to `read_vector_file()` then `ee.Geometry()`
  - `None` or unsupported type → raises `InvalidAOIError`
- `geojson_to_ee_geometry(obj)` — converts GeoJSON-like dicts:
  - raw geometry types (Polygon, MultiPolygon, Point, etc.) → `ee.Geometry(obj)`
  - Feature → extracts geometry, then `ee.Geometry(geom)`
  - FeatureCollection → extracts first feature's geometry
  - invalid or unknown types → raises `InvalidAOIError`
- `read_vector_file(path)` — reads local vector files:
  - validates file exists and extension is supported
  - imports geopandas (with ImportError handling)
  - reads file with `gpd.read_file()`
  - reprojects to EPSG:4326 if CRS differs
  - dissolves all features with `gdf.geometry.union_all()`
  - returns `dissolved.__geo_interface__` dict
  - raises `InvalidAOIError` for empty features or failed reads

**Review focus — this is the highest-value foundation module:**
- Is `ee.FeatureCollection` → `.geometry()` always correct? This dissolves
  server-side, which may be very slow for large collections. Is there a
  warning or guard?
- FeatureCollection GeoJSON handling only uses the first feature's geometry —
  is this documented clearly enough? Is it the right default?
- Is `union_all()` the correct geopandas method? Older versions use
  `unary_union`. The `pyproject.toml` pins `geopandas>=0.14` — verify this
  is sufficient.
- Does `read_vector_file` handle multi-geometry files correctly? What if the
  dissolved result is a `MultiPolygon` — does `ee.Geometry()` accept it?
- What happens if `read_vector_file` is given a `.json` file that is not
  GeoJSON? Does geopandas fail with a useful error or with something cryptic?
- Is the geopandas import inside the function (lazy import) the right choice?
  It avoids a hard import-time dependency but means the error is deferred.
- The `isinstance` checks for `ee.Geometry`, `ee.Feature`,
  `ee.FeatureCollection` happen against the real `ee` module — this requires
  `ee` to be importable at call time. Is this acceptable? Are there
  implications for environments where `ee` is installed but not initialized?

### 4. Temporal reducer mapping

**File:** `08_pkg/src/geecomposer/reducers/temporal.py`

Full implementation (previously `NotImplementedError`):
- `_REDUCER_MAP` dict mapping five strings to lambdas that call
  `ee.ImageCollection` methods: `median()`, `mean()`, `min()`, `max()`,
  `mosaic()`
- `apply_reducer(collection, reducer_name)` — validates via
  `validate_reducer()`, looks up the lambda, applies it

**Review focus:**
- Are the lambdas correct? Do they produce the expected `ee.Image` output?
- Is `mosaic()` semantically appropriate as a "reducer"? (It's
  order-dependent, unlike the others.) Is this worth documenting?
- The function type-hints `collection` as `ee.ImageCollection` but doesn't
  validate this at runtime — is that appropriate?
- The `_REDUCER_MAP` is typed as `dict[str, callable]` — `callable` is not a
  valid type (should be `Callable`). Is this a type annotation error?

### 5. Transform factories — basic

**File:** `08_pkg/src/geecomposer/transforms/basic.py`

Full implementation (previously `NotImplementedError`):
- `select_band(band, name=None)` — returns a closure that calls
  `img.select(band)` and optionally `.rename(name)`
- `normalized_difference(band1, band2, name)` — returns a closure that calls
  `img.normalizedDifference([band1, band2]).rename(name)`
- Both validate that string arguments are non-empty, raising `ValueError`

**Review focus:**
- Should `select_band` and `normalized_difference` raise `ValueError` or
  `TransformError`? The exceptions module defines `TransformError` but these
  functions use plain `ValueError`. Is this intentional?
- `normalized_difference` takes `band1, band2` as positional — the spec says
  `(band1 - band2) / (band1 + band2)`. Is the parameter ordering clear enough
  for users who might confuse which is positive and which is negative?

### 6. Transform factories — indices

**File:** `08_pkg/src/geecomposer/transforms/indices.py`

Full implementation (previously `NotImplementedError`):
- `ndvi(nir="B8", red="B4", name="ndvi")` — delegates to
  `normalized_difference(nir, red, name)`

**Review focus:**
- Default band names are Sentinel-2 specific (`B8`, `B4`). Is this documented
  clearly enough so users working with other collections know to override?
- The spec mentions possible `ndmi` and `gndvi` — are placeholders or TODOs
  appropriate, or is the current single-function state correct for v0.1?

### 7. Transform factories — expressions

**File:** `08_pkg/src/geecomposer/transforms/expressions.py`

Full implementation (previously `NotImplementedError`):
- `expression_transform(expression, band_map, name, extra_vars=None)` —
  returns a closure that:
  - maps band aliases to `img.select(band)` calls
  - merges `extra_vars` if provided
  - calls `img.expression(expression, mapped).rename(name)`
- Validates non-empty `expression`, `band_map`, and `name`

**Review focus:**
- The closure calls `img.expression()` with band objects from
  `img.select(band)` — this matches the EE expression API for band
  references. Is this correct for all expression forms? (Some EE expressions
  expect `img` itself as a reference, not individual band selections.)
- `extra_vars` merge uses `dict.update()` which could silently overwrite band
  references if an alias collides with an extra_var key. Should this be
  checked?
- Like `basic.py`, uses `ValueError` rather than `TransformError`.

### 8. Subpackage `__init__.py` exports

**File:** `08_pkg/src/geecomposer/reducers/__init__.py`
- Exports: `apply_reducer`

**File:** `08_pkg/src/geecomposer/transforms/__init__.py`
- Exports: `select_band`, `normalized_difference`, `ndvi`, `expression_transform`

**Review focus:** Are the right things exported? Should `SUPPORTED_REDUCERS`
or `validate_reducer` be re-exported from `reducers/`? Should any validation
functions be part of the public surface?

### 9. Unit tests — validation

**File:** `08_pkg/tests/test_validation.py`

12 tests:
- `TestValidateReducer` (5 tests): all valid names, case insensitivity,
  whitespace stripping, invalid name, empty string
- `TestValidateDataset` (3 tests): all valid names, case insensitivity,
  invalid name
- `TestConstants` (3 tests): tuple types and membership checks

**Review focus:** Are edge cases covered? What about `None` input to
`validate_reducer`? Unicode strings? Whitespace-only strings?

### 10. Unit tests — AOI normalization

**File:** `08_pkg/tests/test_aoi.py`

16 tests:
- `TestGeojsonToEeGeometry` (7 tests): Polygon dict, Feature dict,
  FeatureCollection dict, non-dict input, unknown type, Feature without
  geometry, empty FeatureCollection
- `TestReadVectorFile` (4 tests): missing file, unsupported extension, valid
  GeoJSON file read, empty FeatureCollection file
- `TestToEeGeometry` (5 tests): None input, ee.Geometry passthrough, dict
  delegation, string path delegation, unsupported type

**Test fixture:** `tests/fixtures/sample_aoi.geojson` — a minimal polygon
FeatureCollection over Madrid area.

**Review focus:**
- The `test_ee_geometry_passthrough` test creates a mock `ee.Geometry` type
  and instance inline — is this robust enough?
- The `test_string_path_delegates_to_file_reader` test patches `ee.Geometry`,
  `ee.Feature`, and `ee.FeatureCollection` with fake type classes to make
  `isinstance` checks work. Is this pattern fragile? Could it break if the
  `aoi.py` import structure changes?
- Is there a test for `pathlib.Path` input (not just `str`)?
- Is there a test for a multi-feature GeoJSON file?
- Is there a test for CRS reprojection (non-4326 input)?

### 11. Unit tests — reducers

**File:** `08_pkg/tests/test_reducers.py`

10 tests:
- `TestReducerMap` (2 tests): all supported names have entries, no extra
  entries
- `TestApplyReducer` (5+2+1 tests): parametrized dispatch for all 5 reducers,
  invalid reducer, case insensitivity

All use `MagicMock` as stand-in for `ee.ImageCollection`.

**Review focus:** Do the mock-based tests actually verify the right behavior?
They check that `collection.median()` is called — but is that sufficient for
confidence that `apply_reducer` works correctly with real EE collections?

### 12. Unit tests — transforms

**File:** `08_pkg/tests/test_transforms.py`

18 tests:
- `TestSelectBand` (5 tests): returns callable, calls select, renames, empty
  band, non-string band
- `TestNormalizedDifference` (5 tests): returns callable, correct EE call,
  empty band1, empty band2, empty name
- `TestNDVI` (3 tests): returns callable, default bands, custom bands
- `TestExpressionTransform` (5 tests): returns callable, correct EE
  expression call, extra_vars merge, empty expression, empty band_map, empty
  name

All use `MagicMock` as stand-in for `ee.Image`.

**Review focus:** Is the expression_transform test verifying the band_map
correctly? It uses `img.select.side_effect` with a dict lookup — is this
realistic enough?

### 13. Existing test — public API

**File:** `08_pkg/tests/test_public_api.py`

1 test: verifies `initialize`, `compose`, `compose_yearly`, `export_to_drive`
are importable and callable.

**Review focus:** This test imports from `geecomposer.__init__` which imports
from `compose.py`, `grouping.py`, `export/drive.py`, and `auth.py` — all of
which are still placeholder `NotImplementedError` stubs. Does this test verify
anything meaningful beyond "the import graph doesn't crash"?

### 14. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — moved foundation modules from "not ready" to
  "ready" with implementation details; updated next milestone to 002
- `08_pkg/testing_strategy.md` — added current test coverage breakdown, EE
  mocking approach documentation, test fixture description
- `08_pkg/development_backlog.md` — moved milestone 001 to "completed",
  milestone 002 to "active"
- `05_governance/decision_log.md` — added two decisions: Python 3.11 venv
  choice, EE mocking strategy for unit tests
- `05_governance/risks.md` — marked AOI risk as mitigated with details, added
  new risks about EE mock coverage gap and geopandas `union_all` compatibility
- `05_governance/review_log.md` — recorded milestone 001 implementation event,
  noted no independent review yet
- `03_experiments/run_summary.md` — added test breakdown table, observations
  about mocking patterns and fixture coverage
- `02_analysis/findings.md` — added findings about mocking strategy,
  geopandas dissolve method, transform closure testing pattern, expression
  band_map pattern

**Review focus:** Are the docs honest? Do they overstate what was achieved?
Do they correctly identify what remains placeholder? Is the risk about
`union_all` vs `unary_union` a real concern given the `geopandas>=0.14` pin?

---

## Pre-existing code that was NOT modified

The following files were NOT changed during this milestone (important for
scope discipline verification):
- `08_pkg/src/geecomposer/__init__.py` — top-level exports, unchanged
- `08_pkg/src/geecomposer/auth.py` — authentication placeholder, unchanged
- `08_pkg/src/geecomposer/compose.py` — compose orchestration placeholder,
  unchanged
- `08_pkg/src/geecomposer/grouping.py` — grouped composition placeholder,
  unchanged
- `08_pkg/src/geecomposer/export/drive.py` — Drive export placeholder,
  unchanged
- `08_pkg/src/geecomposer/datasets/` — all dataset modules, unchanged
- `08_pkg/src/geecomposer/utils/` — utility modules, unchanged
- `08_pkg/src/geecomposer/reducers/__init__.py` — subpackage init, unchanged
- `08_pkg/src/geecomposer/transforms/__init__.py` — subpackage init, unchanged
- `08_pkg/tests/test_public_api.py` — public API test, unchanged
- `08_pkg/tests/conftest.py` — test configuration, unchanged
- `08_pkg/pyproject.toml` — package configuration, unchanged
- All brief, infra, app, ops, and legacy review workspace files — untouched
  (correctly out of scope)

---

## Instructions

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md`
- `08_pkg/CONTEXT.md`
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `05_governance/review_rubric.md`
- `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md`
- `docs/GEECOMPOSER_ROADMAP.md`
- `docs/GEECOMPOSER_PACKAGE_ANALYSIS.md`

### Step 2 — Evaluate the exception and validation design
Inspect `08_pkg/src/geecomposer/exceptions.py` and `08_pkg/src/geecomposer/validation.py`:

- Is the exception hierarchy the right size? Too many? Too few? Are any
  unused?
- Are the validation functions called from the right consumers, or are there
  modules that should validate but don't?
- Is `.json` as a supported vector extension a potential source of confusing
  errors (arbitrary JSON that is not GeoJSON)?
- Is case-insensitive normalization the right default for reducer and dataset
  names?

### Step 3 — Critically evaluate AOI normalization
Inspect `08_pkg/src/geecomposer/aoi.py`:

This is the highest-value and highest-risk foundation module.

- Trace the `to_ee_geometry` dispatch for each supported input type. Is the
  type-checking order correct? Could a valid input fall through to the wrong
  branch?
- For `ee.FeatureCollection` → `.geometry()`: this calls `.geometry()` which
  server-side dissolves. Is this appropriate for all use cases? Could it be
  slow or fail for large collections? Should there be a warning?
- For GeoJSON FeatureCollection dicts: only the first feature's geometry is
  used. Is this documented? Is it the right default? Should `read_vector_file`
  dissolve but `geojson_to_ee_geometry` not?
- For `read_vector_file`:
  - Is `gdf.geometry.union_all()` the correct method for the pinned geopandas
    version?
  - Is CRS reprojection to EPSG:4326 handled correctly? What if the CRS is
    `None` (no CRS metadata)?
  - What happens with very large or complex geometries? Is there any
    simplification or size guard?
  - Does `dissolved.__geo_interface__` always produce a dict that
    `ee.Geometry()` accepts?
- For the string path branch in `to_ee_geometry`: the result of
  `read_vector_file` (a GeoJSON dict) is passed directly to `ee.Geometry()`
  rather than going through `geojson_to_ee_geometry()`. Is this consistent?
  Should it use the same conversion path as dict inputs?

### Step 4 — Evaluate the reducer mapping
Inspect `08_pkg/src/geecomposer/reducers/temporal.py`:

- Is `_REDUCER_MAP` complete relative to the spec?
- Is `mosaic()` semantically correct as a temporal reducer? The spec includes
  it, but mosaic is order-dependent. Is this worth a docstring note?
- The type annotation `dict[str, callable]` uses lowercase `callable` — is
  this correct Python?
- Should `apply_reducer` return type be annotated as `ee.Image`?

### Step 5 — Evaluate the transform factories
Inspect all three transform modules:
- `08_pkg/src/geecomposer/transforms/basic.py`
- `08_pkg/src/geecomposer/transforms/indices.py`
- `08_pkg/src/geecomposer/transforms/expressions.py`

- Do the closures match the spec's expected signatures and behavior?
- Is `select_band` with optional rename the right API? Should rename be
  mandatory when name is ambiguous?
- Is `normalized_difference` parameter ordering clear (band1 is the positive
  term)?
- Does `ndvi()` default band naming work for Sentinel-2? Is it documented
  that defaults are S2-specific?
- Does `expression_transform` correctly handle the EE expression API? Some
  expressions use `img` directly as a reference variable — does the
  `band_map` approach cover this?
- Validation uses `ValueError` instead of `TransformError` — is this
  intentional? Is there a philosophy behind when to use package exceptions vs
  built-in exceptions?

### Step 6 — Evaluate the tests
Inspect all test files:
- `08_pkg/tests/test_validation.py`
- `08_pkg/tests/test_aoi.py`
- `08_pkg/tests/test_reducers.py`
- `08_pkg/tests/test_transforms.py`
- `08_pkg/tests/test_public_api.py`

**Test quality:**
- Are the tests deterministic? Do any depend on network, EE initialization,
  or external state?
- Is the `MagicMock` approach for EE objects sufficient? Does it verify the
  right things (method calls, arguments) or could it mask real issues?
- The AOI `test_ee_geometry_passthrough` creates a fake type inline — is this
  robust?
- The AOI `test_string_path_delegates_to_file_reader` patches three EE types
  with fake classes — is this fragile?
- Is there a test for `pathlib.Path` AOI input?
- Is there a test for CRS reprojection behavior?
- Is there a test for multi-feature GeoJSON dissolve behavior?
- Are there missing edge cases for validation (None input, numeric input)?
- Verify the 61-pass / 3-skip claim independently by running the tests.

### Step 7 — Evaluate scope discipline
Verify that the implementation stayed within the milestone scope:

- No dataset-specific collection loading was introduced
- No `compose()` orchestration logic was implemented
- No export helper implementations were added
- No grouped composition logic was added
- No authentication logic was implemented
- No CLI or application code was introduced
- Foundation logic stays in `aoi.py`, `validation.py`, `exceptions.py`,
  `reducers/temporal.py`, `transforms/basic.py`, `transforms/indices.py`,
  `transforms/expressions.py`
- No broad refactors outside the active foundation modules
- Placeholder files remain honestly placeholder

### Step 8 — Evaluate governance and documentation honesty
Read the updated governance artifacts:

- `08_pkg/current_status.md` — does it accurately reflect what is and isn't
  implemented?
- `08_pkg/testing_strategy.md` — does it honestly describe the EE mocking
  approach and its limitations?
- `08_pkg/development_backlog.md` — is milestone 001 genuinely complete?
- `05_governance/decision_log.md` — are the new decisions (Python 3.11 venv,
  EE mocking strategy) well-reasoned?
- `05_governance/risks.md` — are the mitigated risks genuinely mitigated? Are
  the new risks (mock coverage gap, geopandas compatibility) at appropriate
  severity?
- `05_governance/review_log.md` — does it honestly note that no independent
  review has been performed yet?
- `03_experiments/run_summary.md` — does the test breakdown match the actual
  test results?
- `02_analysis/findings.md` — are findings honest about both strengths and
  limitations?

### Step 9 — Evaluate alignment with architecture contract and spec
Cross-reference the implementation against:

- `08_pkg/architecture_contract.md` — does the implementation follow the
  module boundary rules? Is AOI logic only in `aoi.py`? Is validation only in
  `validation.py`? Is transform logic only in `transforms/`? Is reducer logic
  only in `reducers/`?
- `08_pkg/public_api_contract.md` — are the right things exported? Are
  invalid inputs handled with custom exceptions?
- `geecomposer_v0.1_spec.md` — do the implemented functions match the spec's
  signatures and behavior? Are any spec requirements missed or deviated from?
  Specifically check:
  - `to_ee_geometry` input types vs spec section 8
  - `apply_reducer` vocabulary vs spec section 11
  - `select_band` vs spec section 10.2
  - `normalized_difference` vs spec section 10.2
  - `ndvi` vs spec section 10.2
  - `expression_transform` vs spec section 10.3

### Step 10 — Evaluate overall project readiness
With the core foundations milestone complete:

- Is this milestone genuinely closeable?
- What are the most important gaps or concerns?
- Are there prerequisites for the next milestone (Sentinel-2 dataset support
  and compose orchestration) that this milestone should have addressed?
- Is the AOI normalization robust enough to build dataset loaders on top of?
- Are the transform and reducer foundations stable enough for compose
  orchestration to consume?
- Should any foundation modules be hardened before proceeding?

### Step 11 — Produce a structured review
Write your answer in the following structure:

# Repo Review

## 1. Current State Summary
- Whether the foundations milestone addressed its stated goals
- Whether the module boundaries are explicit and reviewable
- Whether the implemented functions match the spec
- Whether the tests are meaningful
- Whether the docs are honest
- Overall readiness for closing milestone 001

## 2. What Was Done Well
- Quality of the module design and boundaries
- Quality of the tests
- Scope discipline
- Governance and documentation honesty
- Alignment with spec and architecture contract

## 3. Problems / Risks
### Confirmed issues
- Any correctness bugs in the implementation
- Any places where the docs overstate what was achieved
- Any test gaps that should be fixed before closing
### Design risks
- AOI normalization edge cases
- GeoJSON FeatureCollection handling inconsistency
- EE mocking limitations
- Type annotation issues
### Technical debt
- `ValueError` vs `TransformError` inconsistency
- Missing `pathlib.Path` test
- Missing CRS reprojection test
- Any other accumulated concerns

## 4. Alignment with Framework
- Is the implementation aligned with the artifact-first workflow?
- Does it respect workspace boundaries?
- Does the architecture contract hold?
- Does the public API contract hold?
- Does the review rubric pass?

## 5. What Should Change Now
Provide a prioritized list using the review rubric severity guide:
- `P0`: must fix before closing
- `P1`: should fix before closing or early in milestone 002
- `P2`: meaningful improvement needed before the package matures
- `P3`: polish or future cleanup

## 6. Recommended Next Step
- Is milestone 001 closeable?
- What should milestone 002 focus on?
- Are there prerequisites for compose orchestration work?

## 7. Optional Code Changes
Small high-confidence fixes only. No new features. No dataset logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- Respect the project's current stage (foundation modules, not dataset or
  compose work)
- Distinguish clearly between confirmed issues, design risks, and optional
  improvements
- Be especially rigorous about:
  - Whether `to_ee_geometry` handles all spec-required input types correctly
    (spec section 8.1)
  - Whether `geojson_to_ee_geometry` and `read_vector_file` behave
    consistently for multi-feature inputs (one dissolves, the other takes
    first feature only)
  - Whether the `expression_transform` band_map → `img.select()` approach is
    correct for all EE expression forms
  - Whether `apply_reducer` correctly maps all five reducers
  - Whether the test mocking approach actually validates the intended behavior
  - Whether the governance artifacts are honest about what works and what
    doesn't
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` for spec compliance
  - `08_pkg/architecture_contract.md` for module-boundary compliance
  - `08_pkg/public_api_contract.md` for API contract compliance
  - `05_governance/review_rubric.md` for review criteria alignment
  - `docs/GEECOMPOSER_MILESTONE_001_CORE_FOUNDATIONS.md` for milestone
    acceptance criteria
- Verify the 61-pass / 3-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_001.md`

Be skeptical but constructive. This is a foundations review — the bar is
whether the shared building blocks are correct, well-scoped, appropriately
tested, honestly documented, and ready for dataset and orchestration work to
build on top of. No dataset-specific logic, no compose orchestration, no
export helpers, and no grouping should have been introduced.
