# Review Prompt — Sentinel-1 Linear Float Milestone

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 005 implementation, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals and v0.1 scope,
2. the existing dataset paths (sentinel2, sentinel1 dB),
3. what was implemented in milestone 005 (sentinel1_float),
4. whether the implementation is correct, well-isolated, appropriately scoped, and whether it preserves the existing sentinel1 dB behavior unchanged.

Then produce a structured review.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`
- the package source is at `08_pkg/src/geecomposer/`
- the product contract lives in `geecomposer_v0.1_spec.md`

Current development stage:
- milestones 001–004 are closed, hardening pass complete
- **milestone 005 (Sentinel-1 linear float) has just been implemented — this
  is the primary review target**
- 171 tests pass, 0 skipped

The decision to add `sentinel1_float` as a separate preset rather than
changing the meaning of `sentinel1` is recorded in
`05_governance/decision_log.md`.

---

## What was recently implemented

Milestone 005 adds a linear-unit Sentinel-1 dataset path to enable physically
meaningful SAR ratio and algebraic features (VH/VV, VH−VV, RVI) without
altering the existing dB-scaled `sentinel1` preset.

### 1. `sentinel1_float` dataset module

**File:** `08_pkg/src/geecomposer/datasets/sentinel1_float.py`

New module containing:

- `COLLECTION_ID = "COPERNICUS/S1_GRD_FLOAT"`
- `get_collection_id()` → returns the float collection ID
- `load_collection(aoi, start, end, filters=None)`:
  - Creates `ee.ImageCollection(COLLECTION_ID).filterBounds(aoi).filterDate(start, end)`
  - Applies `instrumentMode` filter (defaults to IW)
  - Applies optional `orbitPass` and `polarizations` filters
  - Validates filters via imported `_validate_filters` from `sentinel1.py`
- `apply_mask(collection, mask)` → always raises `GeeComposerError`
- Imports `SUPPORTED_FILTERS`, `_DEFAULT_INSTRUMENT_MODE`, and
  `_validate_filters` from `sentinel1.py`

**Review focus:**
- Is importing shared filter logic from `sentinel1.py` the right design? It
  avoids duplication but creates a coupling between the two modules. If the
  dB module's filter vocabulary changes, the float module inherits the change.
  Is this intentional and documented?
- Is the `load_collection` function body duplicated from `sentinel1.py`, or
  could it be refactored to share the loading logic as well? The filter
  application code (lines 63–83) is identical to `sentinel1.py` lines 65–87.
  Is this acceptable duplication, or should a shared helper exist?
- Does `COPERNICUS/S1_GRD_FLOAT` actually use the same metadata properties
  (`instrumentMode`, `orbitProperties_pass`,
  `transmitterReceiverPolarisation`) as `COPERNICUS/S1_GRD`? Verify this is
  a safe assumption.
- Is the module docstring clear about when to use this preset vs `sentinel1`?
  Does it explain the physical difference (linear power vs dB)?
- Does `apply_mask` use the right error message? It says "Sentinel-1 float"
  while the dB module says "Sentinel-1". Is this distinction helpful or
  inconsistent?

### 2. Validation and compose registration

**File:** `08_pkg/src/geecomposer/validation.py`

- `SUPPORTED_DATASETS` changed from `("sentinel1", "sentinel2")` to
  `("sentinel1", "sentinel1_float", "sentinel2")`

**File:** `08_pkg/src/geecomposer/compose.py`

- Added `from .datasets import sentinel1, sentinel1_float, sentinel2`
- Added `"sentinel1_float": sentinel1_float` to `_DATASET_MODULES`

**File:** `08_pkg/src/geecomposer/datasets/__init__.py`

- Added `SENTINEL1_FLOAT_COLLECTION_ID` export

**Review focus:**
- Are the changes minimal? (Should be: one tuple entry, one import, one dict
  entry, one `__init__` export.)
- Is `validate_dataset("sentinel1_float")` now accepted?
- Does `_resolve_dataset("sentinel1_float", None)` return the correct module?
- Is the existing `sentinel1` behavior provably unchanged?

### 3. Tests — sentinel1_float module

**File:** `08_pkg/tests/test_sentinel1_float.py`

10 tests in 5 classes:

- `TestSentinel1FloatConstants` (2 tests): COLLECTION_ID value,
  get_collection_id
- `TestLoadCollection` (3 tests): loads float collection with defaults,
  polarization filter, orbit pass filter
- `TestFilterValidation` (2 tests): unsupported key raises, string
  polarizations raises
- `TestApplyMask` (1 test): always raises
- `TestSentinel1FloatPreservesDbPreset` (2 tests): dB COLLECTION_ID
  unchanged, dB load_collection still uses `COPERNICUS/S1_GRD`

**Review focus:**
- The preservation tests (`TestSentinel1FloatPreservesDbPreset`) verify that
  the dB module is unchanged. Do they actually prove this, or do they just
  re-verify the dB module's constants?
- Is `_validate_filters` tested for the float module specifically, or only via
  the imported version from `sentinel1.py`? The test imports
  `_validate_filters` from `sentinel1_float` — is this actually the same
  function object from `sentinel1.py`?
- Are there missing tests? Consider:
  - All three filter types combined
  - Custom instrument mode
  - Full filter value validation (non-string instrumentMode, empty
    polarizations, etc.) — or is this inherited from sentinel1 tests?
  - The `_validate_filters` import behavior itself

### 4. Tests — compose integration

**File:** `08_pkg/tests/test_compose.py`

New class `TestComposeSentinel1FloatPipeline` (3 tests):
- `test_sentinel1_float_pipeline` — minimal compose with metadata verification
  (`geecomposer:dataset == "sentinel1_float"`,
  `geecomposer:collection == "COPERNICUS/S1_GRD_FLOAT"`)
- `test_sentinel1_float_with_expression_transform` — VH/VV ratio via
  `expression_transform`, verifies transform metadata name is
  `"expression_transform('vh_vv_ratio')"`
- `test_sentinel1_db_unchanged_after_float_added` — compose with
  `dataset="sentinel1"` still records `COPERNICUS/S1_GRD`

New in `TestDatasetResolution`:
- `test_sentinel1_float_resolves` — resolves to `sentinel1_float` module

New helper functions:
- `_make_mock_s1_float_module()`
- `_all_mock_modules()` — returns all three mock modules

**Review focus:**
- Does `test_sentinel1_float_with_expression_transform` prove a real
  linear-unit feature workflow? It uses `expression_transform("vh / vv", ...)`
  with the real factory — does the mock chain verify it's applied?
- Does `test_sentinel1_db_unchanged_after_float_added` use the correct
  `_DATASET_MODULES` dict containing all three presets? If it only patches
  with `{sentinel1: mock}`, it doesn't prove the float module doesn't
  interfere.
- Does the `_all_mock_modules()` helper maintain consistency? All compose tests
  that use it will have all three datasets available. Is this better than the
  earlier pattern of per-test module dicts?
- Are there missing compose tests? Consider:
  - sentinel1_float with select="VV"
  - sentinel1_float with filters

### 5. Validation test update

**File:** `08_pkg/tests/test_validation.py`

- `test_supported_datasets_is_tuple` assertion changed from `len == 2` to
  `len == 3` with additional `assert "sentinel1_float" in SUPPORTED_DATASETS`

**Review focus:**
- Is this sufficient to verify the validation registration?
- The parametrized `test_valid_datasets_accepted` already tests all
  `SUPPORTED_DATASETS` entries — does `sentinel1_float` appear there
  automatically?

### 6. Governance and documentation

**Files updated:**
- `08_pkg/current_status.md` — three S1 paths listed, test count 171
- `08_pkg/testing_strategy.md` — sentinel1_float tests described
- `08_pkg/development_backlog.md` — already reflects M005 as next item
- `05_governance/review_log.md` — M005 implementation entry
- `05_governance/risks.md` — shared validation coupling risk, unit confusion
  risk
- `03_experiments/run_summary.md` — M005 test breakdown, observations about
  shared validation and expression transforms
- `02_analysis/findings.md` — findings about shared validation, linear-unit
  features, dispatch pattern

**Review focus:**
- Do per-file test counts match reality?
- Are the risks about shared validation coupling and unit confusion
  appropriately noted?
- Is the distinction between dB and linear-unit features clearly explained?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/auth.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all unchanged
- `08_pkg/src/geecomposer/datasets/sentinel1.py` — unchanged (consumed via
  import by sentinel1_float but not modified)
- `08_pkg/src/geecomposer/datasets/sentinel2.py` — unchanged
- `08_pkg/src/geecomposer/grouping.py` — unchanged
- `08_pkg/src/geecomposer/export/` — unchanged
- `08_pkg/src/geecomposer/utils/` — unchanged
- `08_pkg/tests/test_auth.py` — unchanged
- `08_pkg/tests/test_aoi.py` — unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_sentinel1.py` — unchanged
- `08_pkg/tests/test_sentinel2.py` — unchanged
- `08_pkg/tests/test_export_drive.py` — unchanged
- `08_pkg/tests/test_grouping.py` — unchanged
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (section 9.2 for S1 interface)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md` (especially the sentinel1_float decision)
- `docs/GEECOMPOSER_MILESTONE_005_S1_LINEAR_FLOAT.md`
- `docs/ML_FEATURES.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`

### Step 2 — Evaluate the sentinel1_float module
Inspect `08_pkg/src/geecomposer/datasets/sentinel1_float.py`:

- Does `load_collection` use the correct collection ID?
- Is the filter application code correct and consistent with `sentinel1.py`?
- Is the shared import (`_validate_filters`, `_DEFAULT_INSTRUMENT_MODE`,
  `SUPPORTED_FILTERS`) clean? Are these considered stable exports from
  `sentinel1.py`, or are they internal implementation details being imported
  across module boundaries?
- Is the duplicated filter-application logic (lines 63–83 vs sentinel1.py
  65–87) acceptable, or is it a refactoring opportunity?
- Does the module docstring clearly explain the physical difference between
  dB and linear units?

### Step 3 — Evaluate compose and validation integration
Inspect `08_pkg/src/geecomposer/compose.py` and
`08_pkg/src/geecomposer/validation.py`:

- Are the changes minimal (one tuple entry, one import, one dict entry)?
- Is `sentinel1.py` completely unchanged? (diff or inspect)
- Does `compose(dataset="sentinel1", ...)` still resolve to `S1_GRD`?
- Does `compose(dataset="sentinel1_float", ...)` resolve to `S1_GRD_FLOAT`?

### Step 4 — Evaluate the tests
Inspect:
- `08_pkg/tests/test_sentinel1_float.py`
- `08_pkg/tests/test_compose.py` (new classes/tests)
- `08_pkg/tests/test_validation.py` (updated assertion)

- Do the sentinel1_float tests cover the same filter scenarios as sentinel1?
  Or do they rely on the sentinel1 tests for shared validation coverage?
- Does the VH/VV expression transform test prove a real linear-unit workflow?
- Do the preservation tests prove that sentinel1 dB is unchanged?
- Is the `_all_mock_modules()` helper pattern an improvement or a risk?
- Run the suite:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 5 — Evaluate scope discipline
- No speckle filtering, terrain correction, or texture features added
- No existing sentinel1 behavior changed
- No compose pipeline restructuring
- No export/grouping/auth changes
- No notebooks created

### Step 6 — Evaluate the physical correctness claim
The milestone's value proposition is that VH/VV in linear units is physically
correct while VH/VV in dB is not (dB ratio = subtraction, not division).

- Is this claim correct?
- Is it documented clearly enough that a user would choose the right preset?
- Should there be a warning or note in the `sentinel1` module about the dB
  limitation for ratio features?

### Step 7 — Evaluate governance accuracy
- Per-file test counts match reality?
- Decision log entry well-reasoned?
- Risks appropriately noted?
- Review log accurate?

### Step 8 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Sentinel-1 Linear Float

## 1. Current State Summary
- Whether milestone 005 addressed its goals
- Whether sentinel1_float is correct and well-isolated
- Whether sentinel1 dB behavior is preserved
- Whether the tests are meaningful
- Whether the docs are honest
- Overall readiness for closing milestone 005

## 2. What Was Done Well
- Separate preset design
- Shared validation reuse
- Linear-unit feature workflow test
- Scope discipline

## 3. Problems / Risks
### Confirmed issues
- Any correctness bugs
- Any test gaps
### Design risks
- Shared validation coupling
- Duplicated filter-application code
- Unit confusion potential
- `_validate_filters` as a cross-module import of a private function
### Technical debt
- Any accumulated concerns

## 4. Alignment with Framework
- Architecture contract
- Decision log compliance
- Spec alignment

## 5. What Should Change Now
Prioritized list (P0–P3).

## 6. Recommended Next Step
- Is milestone 005 closeable?
- What should come next?

## 7. Optional Code Changes
Small items only.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Distinguish confirmed issues from design preferences
- Be especially rigorous about:
  - Whether `COPERNICUS/S1_GRD_FLOAT` uses the same metadata property names
    as `COPERNICUS/S1_GRD` (instrumentMode, orbitProperties_pass,
    transmitterReceiverPolarisation)
  - Whether importing `_validate_filters` (a private function) from another
    module is a clean boundary or a code smell
  - Whether the duplicated filter-application code in `load_collection` is
    acceptable or should be extracted into a shared helper
  - Whether the VH/VV expression transform test actually exercises the
    transform callable through `col.map()` and records the correct metadata
  - Whether `test_sentinel1_db_unchanged_after_float_added` uses a
    `_DATASET_MODULES` dict containing all three presets (proving
    non-interference) or only the dB preset (proving nothing about float
    interaction)
  - Whether the per-file test counts match the actual suite
- Cross-reference against:
  - `05_governance/decision_log.md` for the separate-preset decision
  - `docs/ML_FEATURES.md` for the linear-unit feature rationale
  - `08_pkg/architecture_contract.md` for module boundaries
  - `05_governance/review_rubric.md` for review criteria
- Verify the 171-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_005.md`

Be thorough but constructive. The key questions are: is the float preset
correctly isolated from the dB preset, does the expression transform workflow
prove linear-unit feature generation, and is importing private functions
across module boundaries an acceptable design choice for shared filter logic?
