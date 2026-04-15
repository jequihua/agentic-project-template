# Review Prompt — Sentinel-2 Compose Milestone

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 002 implementation, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the artifact-first framework being used,
3. the foundation established in milestone 001 (closed),
4. what was implemented in milestone 002 (Sentinel-2 compose),
5. whether the implementation is correct, well-placed, appropriately scoped, and aligned with the architecture contract and spec.

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
- milestone 001 (core foundations) is closed — AOI normalization, validation,
  reducers, and transforms are trustworthy
- **milestone 002 (Sentinel-2 compose) has just been implemented — this is the
  primary review target**
- Sentinel-1 dataset loading is NOT yet implemented (placeholder)
- `compose_yearly()` is NOT yet implemented (placeholder)
- `export_to_drive()` is NOT yet implemented (placeholder)
- `initialize()` is NOT yet implemented (placeholder)
- 105 tests pass, 2 skipped (placeholders for grouping and sentinel1)

Milestone history:
- Milestone 001: 3 implementation passes + 3 reviews to close
- **Milestone 002: first implementation pass — review target**

---

## What was recently implemented

Milestone 002 delivers the first real end-to-end composition workflow: load a
Sentinel-2 collection, apply optional masking/selection/transforms, reduce
across time, attach metadata, and return an `ee.Image`.

### 1. Sentinel-2 dataset loading

**File:** `08_pkg/src/geecomposer/datasets/sentinel2.py`

Previously a placeholder with `NotImplementedError` stubs. Now contains:
- `COLLECTION_ID = "COPERNICUS/S2_SR_HARMONIZED"`
- `SUPPORTED_MASKS = ("s2_cloud_score_plus",)`
- `_CS_PLUS_COLLECTION`, `_CS_PLUS_BAND`, `_CS_PLUS_THRESHOLD` constants for
  Cloud Score+ masking
- `load_collection(aoi, start, end, filters=None)` — creates
  `ee.ImageCollection(COLLECTION_ID).filterBounds(aoi).filterDate(start, end)`
- `apply_mask(collection, mask)` — validates mask name, then delegates to
  `_apply_cloud_score_plus()` for the only supported preset
- `_apply_cloud_score_plus(collection)` — loads Cloud Score+ collection,
  calls `collection.linkCollection(cs_plus, ["cs_cdf"])`, then maps a mask
  function that calls `img.updateMask(score.gte(0.6))`

**Review focus:**
- Is `linkCollection` the correct method for joining Cloud Score+ to S2
  images? The method joins by `system:index` — does this work reliably across
  different AOIs and date ranges?
- The `cs_plus` collection is filtered by `collection.geometry()` — is this
  correct? Does `ee.ImageCollection.geometry()` return the spatial union of
  all images, and is that appropriate for filtering the CS+ collection?
- The threshold of 0.6 is hardcoded. Is this a reasonable default? Is it
  documented clearly enough?
- The `filters` parameter is accepted but unused. Is this appropriate for
  interface consistency, or should it be documented more explicitly as a
  placeholder for future use?
- `apply_mask` imports `GeeComposerError` from `..exceptions` inside the
  function body. Is there a reason not to use a top-level import?
- Does the `_mask_fn` closure correctly select the `cs_cdf` band from the
  linked image? After `linkCollection`, does the CS+ band appear directly on
  the image?

### 2. `compose()` orchestration

**File:** `08_pkg/src/geecomposer/compose.py`

Previously a placeholder. Now implements the 12-step pipeline from the
architecture contract:

- **Step 1** — `_resolve_dataset(dataset, collection)` returns
  `(dataset_name, collection_id, module)`. Uses `_DATASET_MODULES` dict for
  presets, `_GenericLoader` for raw collection IDs.
- **Step 2** — `to_ee_geometry(aoi)` normalizes the AOI.
- **Steps 3–5** — `ds_module.load_collection(geometry, start, end, filters)`
  loads and filters the collection.
- **Step 6** — `ds_module.apply_mask(col, mask=mask)` if mask is provided.
- **Step 7** — `col.select(bands)` if select is provided.
- **Step 8** — `col.map(preprocess)` if preprocess is provided.
- **Step 9** — `col.map(transform)` if transform is provided.
- **Step 10** — `validate_reducer(reducer)` then `apply_reducer(col, reducer)`.
- **Step 11** — `build_metadata_payload(...)` then `image.set(props)`.
- **Step 12** — return `ee.Image`.

**Review focus — this is the most important module to evaluate:**
- Does the pipeline order match the architecture contract exactly? The
  contract specifies: resolve → normalize AOI → load → AOI filter → date
  filter → dataset-specific filters → masking → select → preprocess →
  transform → reduce → metadata → return. Steps 3–5 are collapsed into the
  dataset loader — is this acceptable, or does it blur boundaries?
- `_resolve_dataset` returns a module or `_GenericLoader` instance with the
  same interface. Is this the right dispatch pattern for a function-based
  library? Is `_GenericLoader` justified?
- The condition `if mask is not None and ds_module is not None` at line 106 —
  `ds_module` can never be `None` here (it's always set by `_resolve_dataset`
  which raises if neither dataset nor collection is provided). Is the
  `ds_module is not None` check dead code?
- `validate_reducer(reducer)` is called at step 10, right before
  `apply_reducer()`. But `apply_reducer()` also calls `validate_reducer()`
  internally. Is this double validation intentional or redundant?
- The `transform_name` extraction uses `getattr(transform, "__name__", None)`
  — does this work for lambda transforms? For `functools.partial` objects? For
  the built-in transform factories like `ndvi()`? (Closures returned by
  `ndvi()` have `__name__ = "_fn"`, not `"ndvi"` — is this documented?)
- Is `GeeComposerError` the right exception for missing `aoi`, missing dates,
  and both-dataset-and-collection? Or should these be `ValueError` or more
  specific custom exceptions?
- Does the `filters` parameter get passed through to the dataset loader but
  Sentinel-2's `load_collection` doesn't use it? Is this a silent no-op?

### 3. `_GenericLoader` class

**File:** `08_pkg/src/geecomposer/compose.py`, lines 175–206

A small internal class providing the same interface as dataset modules:
- `get_collection_id()` → returns the raw collection ID
- `load_collection(aoi, start, end, filters)` → creates
  `ee.ImageCollection(id).filterBounds(aoi).filterDate(start, end)`
- `apply_mask(collection, mask)` → raises `GeeComposerError`

**Review focus:**
- This is the only class in the package. The spec and architecture contract
  favor function-based design. Is this justified by the need for interface
  uniformity with dataset modules?
- Should `_GenericLoader` be in a separate file, or is it acceptable in
  `compose.py`?
- The `load_collection` method ignores the `filters` parameter. Is this
  correct for a generic loader, or should it apply `filters` as metadata
  filters?

### 4. Metadata helpers

**File:** `08_pkg/src/geecomposer/utils/metadata.py`

Previously a placeholder. Now contains:
- `build_metadata_payload(dataset, collection, start, end, reducer,
  transform_name, metadata)` → returns a dict of `geecomposer:*` prefixed
  properties, with user metadata under `geecomposer:user:*` prefix

**Review focus:**
- Is the `geecomposer:user:*` prefix convention clear and useful?
- Are `None` values correctly handled (converted to empty strings)?
- Should the payload include any additional properties (e.g., mask name,
  select bands)?

### 5. Tests — Sentinel-2

**File:** `08_pkg/tests/test_sentinel2.py`

6 tests in 3 classes:
- `TestSentinel2Constants` (3 tests): COLLECTION_ID value, get_collection_id,
  SUPPORTED_MASKS membership
- `TestLoadCollection` (1 test): mocks `ee.ImageCollection`, verifies
  `filterBounds` and `filterDate` are called with correct arguments
- `TestApplyMask` (2 tests): unsupported mask raises `GeeComposerError`;
  Cloud Score+ joins CS+ collection and maps a mask function

**Review focus:**
- Is the `load_collection` test sufficient? It verifies the EE method calls
  but not the return value chain.
- The Cloud Score+ test verifies `linkCollection` was called with
  `["cs_cdf"]` — but does it verify the mask function behavior (threshold,
  `updateMask`)? It only checks that `.map()` was called.
- Are there missing tests? For example: calling `load_collection` with
  `filters` parameter, calling `apply_mask` with `"s2_cloud_score_plus"`
  explicitly (not just the default).

### 6. Tests — compose orchestration

**File:** `08_pkg/tests/test_compose.py`

16 tests in 4 classes:
- `TestComposeInputValidation` (6 tests): missing aoi, missing dates,
  missing dataset/collection, both dataset and collection, invalid dataset,
  invalid reducer
- `TestDatasetResolution` (4 tests): sentinel2 resolves, sentinel1 no loader,
  raw collection generic loader, generic loader mask error
- `TestComposePipeline` (7 tests): minimal pipeline, with mask, with select,
  with transform, with preprocess, full pipeline order, metadata attached
- `TestComposeRawCollection` (2 tests): raw collection loads and reduces, raw
  collection with mask raises

Key testing approach: compose tests patch `_DATASET_MODULES` with mock dataset
modules to avoid real EE initialization.

**Review focus:**
- The `test_pipeline_order_mask_select_preprocess_transform` test uses a chain
  of distinct mock objects to verify ordering — is this reliable? Could a
  pipeline reordering bug pass undetected?
- Does `test_metadata_attached` verify the transform name extraction
  correctly? The test sets `transform_fn.__name__` — but real transform
  factories return closures with `__name__ = "_fn"`. Is this tested?
- Is there a test for `compose()` with `select` as a list of multiple bands
  (not just a single string)?
- Is there a test for `compose()` with both `preprocess` and `transform` to
  verify they're applied in the correct order (preprocess first)?
- `test_sentinel1_validated_but_no_loader` — does this correctly verify the
  error message? It matches `"no loader module"` — is this stable?

### 7. Tests — metadata

**File:** `08_pkg/tests/test_metadata.py`

4 tests: basic payload, None values become empty strings, user metadata
prefixed, no user metadata.

**Review focus:** Straightforward and correct. No concerns expected.

### 8. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — updated to reflect compose and S2 loading
- `08_pkg/development_backlog.md` — M001 and M002 completed, M003 active
- `08_pkg/testing_strategy.md` — updated test counts, new modules listed,
  `_DATASET_MODULES` mocking approach documented
- `05_governance/decision_log.md` — two new decisions: `_DATASET_MODULES` dict
  dispatch, Cloud Score+ `linkCollection` masking
- `05_governance/risks.md` — new risks: `_GenericLoader` class in function-based
  package, hardcoded CS+ threshold
- `05_governance/review_log.md` — M002 implementation entry
- `03_experiments/run_summary.md` — M002 test breakdown and observations
- `02_analysis/findings.md` — new findings about mocking approach, CS+ masking,
  `_GenericLoader`, sentinel1 validation vs loader gap

**Review focus:**
- Do the docs accurately reflect what was implemented?
- Are the new risks at appropriate severity?
- Is the sentinel1 validation-vs-loader gap honestly described?

---

## Pre-existing code that was NOT modified

The following files were NOT changed during milestone 002:
- `08_pkg/src/geecomposer/__init__.py` — top-level exports, unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/grouping.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/export/drive.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/aoi.py` — AOI normalization, unchanged (consumed
  by compose)
- `08_pkg/src/geecomposer/validation.py` — validation helpers, unchanged
  (consumed by compose)
- `08_pkg/src/geecomposer/exceptions.py` — exception hierarchy, unchanged
  (consumed by compose and sentinel2)
- `08_pkg/src/geecomposer/reducers/temporal.py` — reducer mapping, unchanged
  (consumed by compose)
- `08_pkg/src/geecomposer/transforms/` — all transform modules, unchanged
  (consumed by compose via transform callables)
- `08_pkg/src/geecomposer/datasets/sentinel1.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/datasets/__init__.py` — subpackage init, unchanged
- `08_pkg/tests/test_aoi.py` — AOI tests, unchanged
- `08_pkg/tests/test_validation.py` — validation tests, unchanged
- `08_pkg/tests/test_reducers.py` — reducer tests, unchanged
- `08_pkg/tests/test_transforms.py` — transform tests, unchanged
- `08_pkg/tests/test_public_api.py` — public API test, unchanged
- `08_pkg/pyproject.toml` — package configuration, unchanged

---

## Instructions

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (especially sections 5, 6, 9, 12, 13, 17)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `docs/GEECOMPOSER_MILESTONE_002_SENTINEL2_COMPOSE.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`

### Step 2 — Evaluate Sentinel-2 dataset loading
Inspect `08_pkg/src/geecomposer/datasets/sentinel2.py`:

- Does `load_collection` correctly use `ee.ImageCollection`, `filterBounds`,
  and `filterDate`?
- Is the Cloud Score+ masking implementation correct? Trace the full path:
  load CS+ collection → `linkCollection` → map mask function → `updateMask`
  with threshold.
- Does `linkCollection` correctly join by `system:index`? Is this reliable for
  Sentinel-2 SR Harmonized + Cloud Score+ V1 S2 Harmonized?
- Is `collection.geometry()` the right way to spatially filter the CS+
  collection?
- Is the 0.6 threshold appropriate? Is it documented?
- Does `apply_mask` handle the unsupported mask case correctly?
- Compare with the spec (section 9.1): does the implementation satisfy the
  Sentinel-2 helper interface requirements?

### Step 3 — Critically evaluate compose() orchestration
Inspect `08_pkg/src/geecomposer/compose.py`:

This is the most important file to review.

- **Pipeline order**: trace each step against the architecture contract (12
  steps). Are any steps missing, reordered, or blurred?
- **Dataset resolution**: is `_DATASET_MODULES` dict dispatch the right
  pattern? Is `_GenericLoader` justified or over-engineered?
- **Dead code**: is `ds_module is not None` at line 106 reachable as False?
- **Double validation**: `validate_reducer` is called in `compose()` and again
  inside `apply_reducer()`. Is this intentional?
- **Transform name extraction**: `getattr(transform, "__name__", None)` — what
  does this return for closures from `ndvi()`, `select_band()`, etc.? Is the
  metadata misleading?
- **Error hierarchy**: `GeeComposerError` is used for missing aoi, missing
  dates, and dataset/collection conflicts. Should these use `ValueError` or
  more specific exceptions?
- **Signature match**: compare `compose()` parameters with the spec (section
  6.2). Are all spec parameters present? Are any extra?
- **The `filters` parameter**: it's passed to `load_collection` but Sentinel-2
  ignores it. Is this a silent no-op that could confuse users?

### Step 4 — Evaluate the tests
Inspect all new test files:
- `08_pkg/tests/test_sentinel2.py`
- `08_pkg/tests/test_compose.py`
- `08_pkg/tests/test_metadata.py`

- Are the tests deterministic? Do any require EE initialization or network?
- Is the `_DATASET_MODULES` patching approach reliable?
- Does `test_pipeline_order_mask_select_preprocess_transform` actually prove
  the pipeline order, or could it pass even with reordered steps?
- Are there missing test scenarios? Consider:
  - `compose()` with no optional parameters (minimal path)
  - `compose()` with `select` as a multi-element list
  - `compose()` with both `preprocess` and `transform`
  - sentinel2 `load_collection` with `filters` parameter
  - CS+ mask function threshold behavior
  - transform name in metadata for real transform factories
- Verify the 105-pass / 2-skip claim independently:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 5 — Evaluate scope discipline
Verify that the implementation stayed within milestone 002 scope:

- No Sentinel-1 implementation was introduced
- No `compose_yearly()` logic was added
- No export helper implementations were added
- No authentication logic was implemented
- No CLI or app features were introduced
- Milestone 001 foundation modules were consumed but not modified
- Placeholder modules remain honestly placeholder

### Step 6 — Evaluate governance and documentation honesty
- Does `08_pkg/current_status.md` accurately reflect what is and isn't
  implemented?
- Are the two new decision log entries well-reasoned?
- Are the new risks at appropriate severity?
- Does `03_experiments/run_summary.md` match actual test results?
- Does `02_analysis/findings.md` add genuine insight?
- Is the sentinel1 gap (validated name but no loader) honestly documented?

### Step 7 — Evaluate alignment with spec and architecture contract
Cross-reference the implementation against:

- `geecomposer_v0.1_spec.md` section 6.2 — does `compose()` signature match?
- `geecomposer_v0.1_spec.md` section 9.1 — does S2 module match the helper
  interface?
- `geecomposer_v0.1_spec.md` section 12 — does the pipeline order match?
- `geecomposer_v0.1_spec.md` section 13 — does metadata match?
- `08_pkg/architecture_contract.md` — module boundaries and pipeline order
- `08_pkg/public_api_contract.md` — public API shape

### Step 8 — Evaluate readiness for next steps
With milestone 002 complete:

- Is the `compose()` implementation robust enough for notebook-based smoke
  testing with `01_data/case_studies/rbmn.geojson`?
- Is the pipeline extensible for Sentinel-1 in milestone 003? (Adding a dict
  entry + loader module should be sufficient.)
- Are there any design decisions in milestone 002 that would make Sentinel-1
  integration harder?
- Is the `_GenericLoader` pattern stable, or should it be reconsidered before
  building more on top of it?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Sentinel-2 Compose

## 1. Current State Summary
- Whether milestone 002 addressed its stated goals
- Whether the Sentinel-2 path works end-to-end (at the code level)
- Whether the compose pipeline order matches the architecture contract
- Whether the tests are meaningful
- Whether the docs are honest
- Overall readiness for closing milestone 002

## 2. What Was Done Well
- Sentinel-2 loading quality
- Compose orchestration design
- Test coverage and approach
- Scope discipline
- Governance honesty

## 3. Problems / Risks
### Confirmed issues
- Any correctness bugs
- Any places where docs overstate achievement
- Any test gaps that should be fixed before closing
### Design risks
- `_GenericLoader` class in function-based package
- Dead code / double validation
- Transform name metadata accuracy
- CS+ threshold hardcoding
- `filters` parameter silent no-op
### Technical debt
- Any accumulated concerns

## 4. Alignment with Framework
- Architecture contract compliance
- Public API contract compliance
- Spec compliance
- Review rubric pass

## 5. What Should Change Now
Provide a prioritized list using the severity guide:
- `P0`: must fix before closing
- `P1`: should fix before closing or early in milestone 003
- `P2`: meaningful improvement before the package matures
- `P3`: polish or future cleanup

## 6. Recommended Next Step
- Is milestone 002 closeable?
- What should milestone 003 prioritize?
- Are there prerequisites for Sentinel-1 work?

## 7. Optional Code Changes
Small high-confidence fixes only. No new features. No Sentinel-1 logic.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- Respect the project's current stage (first real compose path, not production)
- Distinguish clearly between confirmed issues, design risks, and preferences
- Be especially rigorous about:
  - Whether `linkCollection` correctly joins S2 and Cloud Score+ by
    `system:index` — check the EE API documentation or known behavior
  - Whether `collection.geometry()` is appropriate for spatially filtering the
    CS+ collection
  - Whether the pipeline order in `compose()` exactly matches the architecture
    contract steps 1–12
  - Whether `_GenericLoader` is justified or should be replaced with functions
  - Whether the `ds_module is not None` check is dead code
  - Whether the double `validate_reducer` call is intentional or accidental
  - Whether the tests actually verify pipeline ordering or just method calls
  - Whether `getattr(transform, "__name__", None)` produces useful metadata
    for the built-in transform factories
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` for spec compliance
  - `08_pkg/architecture_contract.md` for pipeline order and module boundaries
  - `08_pkg/public_api_contract.md` for API shape
  - `05_governance/review_rubric.md` for review criteria
  - `docs/GEECOMPOSER_MILESTONE_002_SENTINEL2_COMPOSE.md` for milestone scope
- Verify the 105-pass / 2-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_002.md`

Be thorough but constructive. This is a milestone 002 review — the bar is
whether the first real compose path is correct, well-scoped, properly tested,
and ready for notebook-based validation and Sentinel-1 extension. No
Sentinel-1, export, or grouping work should have been introduced.
