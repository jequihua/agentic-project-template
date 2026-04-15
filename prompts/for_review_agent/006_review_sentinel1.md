# Review Prompt — Sentinel-1 Dataset Milestone

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 003 implementation, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the existing foundation (milestone 001) and Sentinel-2 path (milestone 002),
3. what was implemented in milestone 003 (Sentinel-1 dataset support),
4. whether the implementation is correct, well-placed, appropriately scoped, and aligned with the architecture contract and spec,
5. whether adding Sentinel-1 preserved the pipeline stability established in milestone 002.

Then produce a structured review.

---

## Project context

This repository follows an artifact-first agentic ML workflow.

The project is:
- `geecomposer`: a lightweight Python library for Google Earth Engine compositing with an export-first workflow
- the active package workspace is `08_pkg/`
- the package source is at `08_pkg/src/geecomposer/`
- the product contract lives in `geecomposer_v0.1_spec.md`
- v0.1 must support Sentinel-2 and Sentinel-1 compositing, local vector AOI inputs, built-in and custom transforms, temporal reducers, and Drive export

Current development stage:
- milestone 001 (core foundations) is closed
- milestone 002 (Sentinel-2 compose) is closed
- **milestone 003 (Sentinel-1) has just been implemented — this is the primary review target**
- `compose_yearly()` is NOT yet implemented (placeholder)
- `export_to_drive()` is NOT yet implemented (placeholder)
- `initialize()` is NOT yet implemented (placeholder)
- 126 tests pass, 1 skipped (placeholder for grouping)

Review history:
- Milestone 001: 3 implementation passes, 3 reviews to close
- Milestone 002: 2 implementation passes, 2 reviews to close
- **Milestone 003: first implementation pass — review target**

---

## What was recently implemented

Milestone 003 adds Sentinel-1 GRD dataset support to prove the package can
handle both required v0.1 dataset families (optical and radar) without
breaking architectural simplicity.

### 1. Sentinel-1 dataset loading

**File:** `08_pkg/src/geecomposer/datasets/sentinel1.py`

Previously a placeholder with `NotImplementedError` stubs. Now contains:

- `COLLECTION_ID = "COPERNICUS/S1_GRD"`
- `SUPPORTED_FILTERS = ("instrumentMode", "orbitPass", "polarizations")`
- `_DEFAULT_INSTRUMENT_MODE = "IW"`
- `load_collection(aoi, start, end, filters=None)`:
  - Creates `ee.ImageCollection(COLLECTION_ID).filterBounds(aoi).filterDate(start, end)`
  - Applies `instrumentMode` filter (defaults to `"IW"` if not in filters)
  - Applies optional `orbitPass` filter via `ee.Filter.eq("orbitProperties_pass", value)`
  - Applies optional `polarizations` filter via `ee.Filter.listContains("transmitterReceiverPolarisation", pol)` for each polarization
  - Validates filter keys via `_validate_filters()`
- `apply_mask(collection, mask)`:
  - Always raises `GeeComposerError` — no masking presets for S1 GRD in v0.1
- `_validate_filters(filters)`:
  - Checks all keys against `SUPPORTED_FILTERS`
  - Raises `GeeComposerError` listing unsupported keys

**Review focus:**
- Is `instrumentMode=IW` the right default? The spec says "default to IW when
  `dataset="sentinel1"` is used and no filters are provided." But the current
  implementation defaults to IW even when other filters ARE provided (e.g.,
  `filters={"orbitPass": "ASCENDING"}` still gets IW). Is this correct, or
  should IW only be defaulted when `filters` is empty or None?
- The user-facing filter key `orbitPass` is mapped internally to the EE
  property `orbitProperties_pass`. Is this mapping documented clearly enough?
  Could a user who reads EE docs be confused by the different key name?
- Does `_validate_filters` catch all invalid inputs? What about non-string
  values for `instrumentMode` or `orbitPass`? What about an empty list for
  `polarizations`?
- Is the `filters` parameter validation happening at the right boundary? The
  spec puts filter keys as part of the dataset module — is `_validate_filters`
  the right place, or should validation happen in `compose()`?
- Does `apply_mask` raise the right exception type? The Sentinel-2 module uses
  `GeeComposerError` for unsupported masks too — is this consistent?
- The `GeeComposerError` import is at the top of the module (unlike the
  Sentinel-2 module which had it inside the function body). Is this
  inconsistency worth noting?
- Compare with the spec (section 9.2): does the implementation satisfy the
  Sentinel-1 helper interface requirements?

### 2. Compose integration

**File:** `08_pkg/src/geecomposer/compose.py`

Changes:
- Added `from .datasets import sentinel1, sentinel2`
- Added `"sentinel1": sentinel1` to `_DATASET_MODULES` dict

No pipeline logic was changed.

**Review focus:**
- Is this the right integration approach? The `_DATASET_MODULES` dispatch
  pattern was designed in milestone 002 specifically to make this extension
  trivial. Does it work as intended?
- The `compose()` pipeline is unchanged — does it handle Sentinel-1's
  different characteristics correctly? Specifically:
  - S1 has no masking presets (mask= should raise)
  - S1 uses `filters` for dataset-specific metadata filtering
  - S1 transforms work the same as S2 (callable `ee.Image -> ee.Image`)
- Does the `filters` parameter flow correctly from `compose()` through
  `_resolve_dataset()` to `sentinel1.load_collection()`?
- Sentinel-1 was previously validated by `validate_dataset()` but raised
  `DatasetNotSupportedError("no loader module")` in `_resolve_dataset()`.
  Is this error path now correctly eliminated?

### 3. Tests — Sentinel-1

**File:** `08_pkg/tests/test_sentinel1.py`

13 tests in 5 classes:

- `TestSentinel1Constants` (3 tests): COLLECTION_ID value, get_collection_id,
  SUPPORTED_FILTERS membership
- `TestLoadCollection` (5 tests): loads with defaults (AOI + date +
  instrumentMode=IW), orbit pass filter, polarization filter, custom
  instrument mode, all filters combined
- `TestFilterValidation` (4 tests): unsupported key raises, mixed valid/invalid
  raises, valid filters pass, empty filters pass
- `TestApplyMask` (1 test): always raises GeeComposerError

**Review focus:**
- Does `test_loads_and_filters_with_defaults` verify the default IW filter is
  applied? It checks `mock_ee.Filter.eq.assert_called_once_with("instrumentMode", "IW")` — is this sufficient?
- Does `test_polarization_filter` verify that BOTH polarizations are applied?
  It checks for both `VV` and `VH` in `listContains` calls.
- Is there a test that verifies the `filters=None` default behavior (no
  explicit filters dict)?
- Is there a test for `orbitPass` mapping to `orbitProperties_pass`? The
  `test_orbit_pass_filter` checks for `call("orbitProperties_pass", "ASCENDING")`
  — does this prove the mapping?
- Are there missing test scenarios? Consider:
  - `filters={"polarizations": []}` (empty polarization list)
  - `filters={"instrumentMode": 123}` (non-string value)
  - `filters={"orbitPass": "INVALID_DIRECTION"}`
  - calling `load_collection` with no `filters` argument at all

### 4. Tests — Compose S1 path

**File:** `08_pkg/tests/test_compose.py`

Changes:
- `test_sentinel1_validated_but_no_loader` replaced with
  `test_sentinel1_resolves` — verifies sentinel1 module is returned
- Added class `TestComposeSentinel1Pipeline` (4 tests):
  - `test_minimal_sentinel1_pipeline` — dataset + aoi + dates + reducer
  - `test_sentinel1_with_filters_and_transform` — filters passed through,
    transform mapped
  - `test_sentinel1_mask_raises` — mask= causes GeeComposerError
  - `test_sentinel1_metadata_has_correct_dataset` — metadata records
    "sentinel1" and "COPERNICUS/S1_GRD"
- Added `_make_mock_s1_module()` helper

**Review focus:**
- Does `test_sentinel1_with_filters_and_transform` verify that the filters
  dict is passed through to `load_collection`?
- Does `test_sentinel1_mask_raises` test the real `apply_mask` behavior, or
  does it mock it? (It sets `mock_s1.apply_mask.side_effect` — does this
  actually prove the sentinel1 module's behavior?)
- Do the S1 compose tests patch `_DATASET_MODULES` correctly to include both
  sentinel1 and sentinel2?
- Are there missing compose-path tests? Consider:
  - `compose(dataset="sentinel1", select="VV", ...)` — band selection
  - `compose(dataset="sentinel1")` with no optional parameters

### 5. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — updated to reflect both dataset paths
- `08_pkg/development_backlog.md` — M003 completed, M004 active
- `08_pkg/testing_strategy.md` — updated test counts and S1 coverage
- `05_governance/decision_log.md` — two new decisions: default IW instrument
  mode, `orbitPass` mapping to `orbitProperties_pass`
- `05_governance/risks.md` — new risks: `orbitPass` mapping, no S1 masking
- `05_governance/review_log.md` — M003 implementation entry
- `03_experiments/run_summary.md` — M003 test breakdown and observations
- `02_analysis/findings.md` — findings about dispatch pattern confirmation,
  filter mapping, review convergence

**Review focus:**
- Do the docs accurately reflect what was implemented?
- Are the two new decision log entries well-reasoned?
- Are the new risks at appropriate severity?
- Do the per-file test counts in `testing_strategy.md` and `run_summary.md`
  match reality? (Previous milestones had count mismatches.)
- Is the observation about pipeline stability honest — was the pipeline truly
  unchanged, or were there subtle shifts?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/temporal.py` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all transform modules unchanged
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
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (especially sections 9.2, 10, 12)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `docs/GEECOMPOSER_MILESTONE_003_SENTINEL1.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`

### Step 2 — Evaluate Sentinel-1 dataset loading
Inspect `08_pkg/src/geecomposer/datasets/sentinel1.py`:

- Does `load_collection` correctly use `ee.ImageCollection`, `filterBounds`,
  `filterDate`, `ee.Filter.eq`, and `ee.Filter.listContains`?
- Is the default `instrumentMode=IW` behavior correct when `filters` is None?
  When `filters` has other keys but not `instrumentMode`?
- Is `_validate_filters` thorough enough? Does it only check key names, or
  does it also validate value types?
- Is the `orbitPass` → `orbitProperties_pass` mapping correct and documented?
- Does `apply_mask` raise the right exception with a clear message?
- Compare with `datasets/sentinel2.py` — are the module interfaces consistent?
  Both should have `get_collection_id()`, `load_collection()`, and
  `apply_mask()`.

### Step 3 — Evaluate compose integration
Inspect `08_pkg/src/geecomposer/compose.py`:

- Is the change minimal? (It should be: one import, one dict entry.)
- Does `_resolve_dataset("sentinel1", None)` now correctly return the
  sentinel1 module instead of raising?
- Does the existing pipeline handle the Sentinel-1 case correctly without
  any radar-specific logic leaking into compose?
- Does the `filters` parameter flow through compose → `_resolve_dataset` →
  `ds_module.load_collection(geometry, start, end, filters=filters)`?

### Step 4 — Evaluate the tests
Inspect:
- `08_pkg/tests/test_sentinel1.py`
- `08_pkg/tests/test_compose.py`

**Sentinel-1 tests:**
- Do they cover the default IW behavior?
- Do they cover all three filter types (instrumentMode, orbitPass, polarizations)?
- Do they cover filter validation (unsupported keys)?
- Do they cover the mask rejection?
- Are there missing edge cases?

**Compose S1 tests:**
- Do they verify the filters pass-through?
- Do they verify mask rejection through the compose path?
- Do they verify metadata records the correct dataset and collection?
- Is `test_sentinel1_resolves` correct (replacing the old no-loader test)?

**Run the test suite to verify:**
`.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 5 — Evaluate scope discipline
- No advanced SAR processing was introduced (no speckle, terrain correction,
  coherence)
- No export, grouping, or auth work was added
- No Sentinel-2 code was modified
- No pipeline restructuring occurred
- `compose.py` changes are minimal (import + dict entry)
- Placeholder modules remain placeholder

### Step 6 — Evaluate governance and documentation honesty
- Do the per-file test counts match reality?
- Are the decision log entries well-reasoned?
- Are the risks accurately described?
- Is the claim that "no pipeline changes were needed" honest?
- Does the review log accurately describe the milestone scope?

### Step 7 — Evaluate alignment with spec and architecture
Cross-reference against:
- `geecomposer_v0.1_spec.md` section 9.2 — Sentinel-1 module interface
- `geecomposer_v0.1_spec.md` section 12 — pipeline order
- `08_pkg/architecture_contract.md` — module boundaries, dataset isolation
- `08_pkg/public_api_contract.md` — `compose()` signature unchanged

### Step 8 — Evaluate multi-dataset architectural health
Step back and assess the package with both datasets:

- Is the dataset isolation clean? S1 logic in `sentinel1.py`, S2 logic in
  `sentinel2.py`, no cross-contamination?
- Does the `_DATASET_MODULES` pattern scale? Is it adequate for 2 datasets?
  Would it remain adequate for 3–4?
- Are the dataset module interfaces consistent? Both have
  `get_collection_id()`, `load_collection()`, `apply_mask()` — are the
  signatures compatible?
- Is the `filters` parameter semantics consistent across datasets? S2 ignores
  it, S1 uses it for radar-specific metadata. Is this documented?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Sentinel-1

## 1. Current State Summary
- Whether milestone 003 addressed its stated goals
- Whether the Sentinel-1 path works through the existing pipeline
- Whether the compose pipeline was preserved unchanged
- Whether the tests are meaningful
- Whether the docs are honest
- Overall readiness for closing milestone 003

## 2. What Was Done Well
- Dataset isolation quality
- Compose integration minimality
- Filter implementation
- Test coverage and approach
- Scope discipline
- Governance honesty

## 3. Problems / Risks
### Confirmed issues
- Any correctness bugs
- Any docs that overstate achievement
- Any test gaps that should be fixed before closing
### Design risks
- Default IW behavior when other filters are present
- Filter value validation gap
- `orbitPass` mapping clarity
- `filters` parameter inconsistency across datasets
### Technical debt
- Any accumulated concerns

## 4. Alignment with Framework
- Architecture contract compliance
- Public API contract compliance
- Spec compliance (section 9.2)
- Review rubric pass

## 5. What Should Change Now
Provide a prioritized list using the severity guide:
- `P0`: must fix before closing
- `P1`: should fix before closing or early in milestone 004
- `P2`: meaningful improvement before the package matures
- `P3`: polish or future cleanup

## 6. Recommended Next Step
- Is milestone 003 closeable?
- What should milestone 004 prioritize?
- Are there any prerequisites for export/grouping work?

## 7. Optional Code Changes
Small high-confidence fixes only. No new features. No export/grouping logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- Respect the project's current stage (second dataset integration, not
  production)
- Distinguish clearly between confirmed issues, design risks, and preferences
- Be especially rigorous about:
  - Whether the default `instrumentMode=IW` is applied correctly in all cases
    (no filters, partial filters, explicit IW override)
  - Whether `orbitPass` → `orbitProperties_pass` mapping is correct per EE
    documentation
  - Whether `_validate_filters` catches enough invalid input patterns
  - Whether the compose pipeline truly required no changes (diff `compose.py`
    to confirm only import + dict entry changed)
  - Whether the test counts in governance docs match the actual suite
  - Whether the `test_sentinel1_mask_raises` compose test actually proves the
    real sentinel1 module behavior or just mocks it
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` section 9.2 for S1 interface requirements
  - `08_pkg/architecture_contract.md` for module boundaries
  - `08_pkg/public_api_contract.md` for API shape
  - `05_governance/review_rubric.md` for review criteria
  - `docs/GEECOMPOSER_MILESTONE_003_SENTINEL1.md` for milestone scope
- Verify the 126-pass / 1-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_003.md`

Be thorough but constructive. This is a milestone 003 review — the bar is
whether the Sentinel-1 path is correct, well-isolated, properly tested, and
whether adding a second dataset preserved the architectural simplicity that
milestones 001 and 002 established.
