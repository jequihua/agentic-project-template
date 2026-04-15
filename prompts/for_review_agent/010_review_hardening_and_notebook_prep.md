# Review Prompt — Hardening and Notebook-Prep Pass

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the hardening pass, and decide whether the package is ready for notebook-based live validation.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals and v0.1 scope,
2. the milestone history (001–004 all closed),
3. what was changed in the hardening pass,
4. whether `initialize()` is correctly implemented, whether the polish items are complete, and whether the package is ready for live notebook validation.

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
- milestones 001–004 are all closed
- **a hardening pass has just been applied — this is the primary review target**
- all four public API functions (`initialize`, `compose`, `compose_yearly`,
  `export_to_drive`) are now implemented
- 156 tests pass, 0 skipped
- GCS export remains placeholder; monthly/seasonal grouping deferred

This is NOT a milestone review — it is a readiness assessment for the next
phase: notebook-based live Earth Engine validation.

---

## What was changed in the hardening pass

### 1. `initialize()` implementation

**File:** `08_pkg/src/geecomposer/auth.py`

Previously a placeholder with `NotImplementedError`. Now contains:

- Imports `ee` and `GeeComposerError`
- `initialize(project=None, authenticate=False)`:
  - If `authenticate=True`, calls `ee.Authenticate()` first
  - If `project is not None`, calls `ee.Initialize(project=project)`
  - Otherwise calls `ee.Initialize()`
  - Wraps any exception in `GeeComposerError` via `except Exception as exc`

**Review focus:**
- Is the implementation consistent with the spec (section 15)? The spec says:
  `initialize(project: str | None = None, authenticate: bool = False)` — does
  the signature match?
- Is `except Exception` too broad? Could it catch `KeyboardInterrupt` or
  `SystemExit`? (In Python 3, `Exception` does NOT catch `KeyboardInterrupt`
  or `SystemExit`, so this is actually safe. But verify the reviewer
  understands this.)
- Should the function return anything? The spec says "keep this helper very
  thin." The current implementation returns `None`.
- Is wrapping EE errors in `GeeComposerError` the right approach? It keeps
  error handling consistent with the rest of the package, but it hides the
  original EE exception type. The `from exc` chain preserves the original
  exception — is this sufficient for debugging?
- The `ee` import is at the top of the module. If `earthengine-api` is not
  installed, the import fails at module load time. Is this acceptable? (It
  is — `ee` is a declared dependency.)
- Compare with the spec section 15: does the behavior match "if
  `authenticate=True`, call `ee.Authenticate()`; then
  `ee.Initialize(project=project)` where applicable"?

### 2. Auth tests

**File:** `08_pkg/tests/test_auth.py`

6 tests:

- `test_default_initializes_without_project` — `initialize()` calls
  `ee.Initialize()` with no arguments, does not call `ee.Authenticate()`
- `test_project_passed_through` — `initialize(project="my-ee-project")` calls
  `ee.Initialize(project="my-ee-project")`
- `test_authenticate_called_before_initialize` — verifies ordering: auth
  happens before init (uses a call-order list)
- `test_authenticate_with_project` — both `ee.Authenticate()` and
  `ee.Initialize(project=...)` called
- `test_initialization_failure_raises_package_error` — `ee.Initialize` raises
  → `GeeComposerError`
- `test_authenticate_failure_raises_package_error` — `ee.Authenticate` raises
  → `GeeComposerError`

**Review focus:**
- Does `test_authenticate_called_before_initialize` actually prove ordering?
  It uses `side_effect` lambdas that append to a list — is this reliable?
- The `ee.Initialize` mock in the authenticate-ordering test uses
  `lambda **kw: call_order.append("init")`. Does this handle the no-project
  case where `ee.Initialize()` is called without kwargs? (The default call
  `ee.Initialize()` passes no kwargs — does the `**kw` lambda accept that?)
- Are there missing auth test scenarios? Consider:
  - `initialize(project="")` — empty string project
  - `initialize(authenticate=False)` — explicitly false (should be same as
    default, but is it tested?)
- Are the tests deterministic and free of live EE requirements?

### 3. Export polish test

**File:** `08_pkg/tests/test_export_drive.py`

New test `test_default_file_name_prefix_from_description`:
- Calls `export_to_drive(..., file_name_prefix=None)`
- Verifies `fileNamePrefix` in the `toDrive` call equals the `description`

**Review focus:**
- Was this identified as a P2 item in the milestone 004 review? Is it now
  resolved?
- Does it add genuine coverage beyond `test_creates_drive_task` which
  implicitly tests the default?

### 4. Grouping polish test

**File:** `08_pkg/tests/test_grouping.py`

New test `test_start_none_in_kwargs_still_raises`:
- Calls `compose_yearly(years=[2024], start=None, ...)`
- Verifies `GeeComposerError` is raised with the same message as explicit
  start values

**Review focus:**
- Does this serve as executable documentation of the strict key-presence
  check?
- Was this identified as a P1 item in the milestone 004 review? Is the
  decision (keep strict) now documented in both code and test?

### 5. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — all four API functions listed as ready, test
  count 156, next steps updated to notebook validation
- `08_pkg/development_backlog.md` — hardening pass added to completed, next
  steps focused on notebooks/examples/release
- `08_pkg/testing_strategy.md` — auth tests added, export/grouping counts
  updated
- `05_governance/review_log.md` — hardening pass entry
- `05_governance/risks.md` — `initialize()` error wrapping risk noted
- `03_experiments/run_summary.md` — hardening pass changes and test breakdown
- `02_analysis/findings.md` — auth implementation finding

**Review focus:**
- Do the per-file test counts match reality?
- Is `current_status.md` now accurate (it was stale after M004 corrective)?
- Does the review log correctly record the hardening pass?
- Are the next steps realistic?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged (already exports
  `initialize`)
- `08_pkg/src/geecomposer/compose.py` — unchanged
- `08_pkg/src/geecomposer/grouping.py` — unchanged
- `08_pkg/src/geecomposer/export/drive.py` — unchanged
- `08_pkg/src/geecomposer/aoi.py` — unchanged
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all unchanged
- `08_pkg/src/geecomposer/datasets/` — all unchanged
- `08_pkg/src/geecomposer/utils/` — unchanged
- `08_pkg/src/geecomposer/export/__init__.py` — unchanged
- `08_pkg/src/geecomposer/export/gcs.py` — placeholder, unchanged
- `08_pkg/tests/test_aoi.py` — unchanged
- `08_pkg/tests/test_validation.py` — unchanged
- `08_pkg/tests/test_reducers.py` — unchanged
- `08_pkg/tests/test_transforms.py` — unchanged
- `08_pkg/tests/test_sentinel1.py` — unchanged
- `08_pkg/tests/test_sentinel2.py` — unchanged
- `08_pkg/tests/test_compose.py` — unchanged
- `08_pkg/tests/test_metadata.py` — unchanged
- `08_pkg/tests/test_public_api.py` — unchanged
- `08_pkg/pyproject.toml` — unchanged

---

## Instructions

### Step 1 — Read project guidance and v0.1 scope
Read these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (sections 6.1, 15 especially)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `05_governance/review_log.md`
- `03_experiments/run_summary.md`

### Step 2 — Evaluate `initialize()` implementation
Inspect `08_pkg/src/geecomposer/auth.py`:

- Does the signature match the spec (section 15)?
- Is the control flow correct: authenticate → initialize with or without
  project?
- Is the error wrapping appropriate? Does `from exc` preserve the chain?
- Is the function appropriately thin?
- Is there any hidden state or side effect beyond calling EE methods?

### Step 3 — Evaluate auth tests
Inspect `08_pkg/tests/test_auth.py`:

- Do the tests cover the four main paths (default, project, authenticate,
  authenticate+project)?
- Do the failure tests cover both auth and init failures?
- Does the ordering test actually prove ordering?
- Are there missing edge cases?
- Run the tests:
  `.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 4 — Evaluate polish items
Inspect `08_pkg/tests/test_export_drive.py` and `08_pkg/tests/test_grouping.py`:

- Does the export `file_name_prefix=None` test add genuine coverage?
- Does the grouping `start=None` test serve as executable documentation?
- Were these items identified in previous reviews?

### Step 5 — Evaluate v0.1 feature completeness
Assess the package against the spec:

- **Section 6.1 (top-level exports)**: `initialize`, `compose`,
  `compose_yearly`, `export_to_drive` — all importable?
- **Section 4.1 (in-scope)**:
  - Collections: S2 and S1 ✓
  - Inputs: AOI, dates, reducer, transform, filters ✓
  - Transforms: select_band, normalized_difference, ndvi, expression ✓
  - Reducers: median, mean, min, max, mosaic ✓
  - Grouping: yearly ✓
  - Export: Drive ✓
  - Auth: initialize ✓
- **Section 4.2 (out of scope)**: monthly/seasonal grouping, GCS, Landsat,
  CLI, visualization — all correctly absent?
- Is the package ready for notebook-based live validation?

### Step 6 — Evaluate scope discipline
- Only `auth.py`, `test_auth.py`, `test_export_drive.py`,
  `test_grouping.py`, and governance docs were modified
- No new features beyond `initialize()`
- No dataset changes
- No compose/export/grouping redesign
- No notebooks created

### Step 7 — Evaluate governance accuracy
- Per-file test counts match reality?
- Review log accurate?
- Risks properly updated?
- Next steps realistic and honest?

### Step 8 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Hardening and Notebook-Prep

## 1. `initialize()` Assessment
- Is the implementation correct and spec-compliant?
- Are the tests sufficient?
- Is the error wrapping appropriate?

## 2. Polish Items
- Export `file_name_prefix` test: useful or redundant?
- Grouping `start=None` test: useful executable documentation?
- Stale docs: corrected?

## 3. v0.1 Feature Completeness
- Are all spec section 4.1 items covered?
- Are all spec section 6.1 exports present?
- What remains (GCS, monthly grouping)?

## 4. Notebook Readiness
- Is the package ready for live EE validation?
- What would a reviewer expect to work in a notebook using
  `01_data/case_studies/rbmn.geojson`?
- Any concerns about the notebook experience?

## 5. Problems / Risks
### Confirmed issues
- Any bugs
- Any doc inaccuracies
### Design risks
- `except Exception` scope
- Error wrapping information loss
- Any accumulated debt
### What remains
- GCS export placeholder
- Monthly/seasonal grouping
- Live EE validation gap

## 6. Recommended Next Step
- Is the package ready for notebook validation?
- What should the notebook pass cover?
- Any prerequisites before notebooks?

## 7. Optional Recommendations
Small items only.

---

## Review style constraints

- Be concrete and repo-aware
- This is a readiness assessment, not a milestone closure review
- The question is: can the project move to live notebook validation?
- Be especially rigorous about:
  - Whether `initialize()` matches the spec section 15 exactly
  - Whether `except Exception` in `auth.py` is safe (it is in Python 3 —
    `BaseException` subclasses like `KeyboardInterrupt` and `SystemExit` are
    NOT caught by `except Exception`)
  - Whether the auth ordering test is reliable (side-effect list approach)
  - Whether the per-file test counts match the actual suite
  - Whether `current_status.md` is now accurate (it was stale after M004)
  - Whether the package is genuinely feature-complete for spec section 4.1
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` sections 4.1, 6.1, 15
  - `08_pkg/architecture_contract.md`
  - `08_pkg/public_api_contract.md`
  - `05_governance/review_rubric.md`
- Verify the 156-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_hardening_pass.md`

Be direct and practical. This is not a feature review — it is a readiness
gate. The question is whether the package is trustworthy enough, complete
enough, and documented enough for a human to open a notebook, initialize
Earth Engine, compose imagery over the case-study AOI, and export results to
Drive.
