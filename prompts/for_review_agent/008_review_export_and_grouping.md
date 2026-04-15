# Review Prompt — Export and Grouping Milestone

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to understand the project, inspect the current repository state, evaluate the milestone 004 implementation, and produce a thorough review aligned with the project framework.

You are reviewing the local repository currently open in your environment.

## Review objective

Understand:
1. the project goals,
2. the foundation and dataset paths established in milestones 001–003,
3. what was implemented in milestone 004 (Drive export + yearly grouping),
4. whether the implementation is correct, well-placed, appropriately scoped, and aligned with the architecture contract and spec,
5. whether export and grouping remain cleanly separated from composition.

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
- milestone 001 (core foundations) is closed
- milestone 002 (Sentinel-2 compose) is closed
- milestone 003 (Sentinel-1) is closed
- **milestone 004 (export + grouping) has just been implemented — this is the
  primary review target**
- `initialize()` is NOT yet implemented (placeholder)
- GCS export is NOT yet implemented (placeholder)
- monthly/seasonal grouping is NOT implemented
- 147 tests pass, 0 skipped

Review history:
- Milestone 001: 3 passes, 3 reviews
- Milestone 002: 2 passes, 2 reviews
- Milestone 003: 2 passes, 2 reviews
- **Milestone 004: first implementation pass — review target**

---

## What was recently implemented

Milestone 004 adds two workflow helpers that sit alongside the existing
composition pipeline: a Drive export task creator and a yearly grouping
function.

### 1. `export_to_drive()`

**File:** `08_pkg/src/geecomposer/export/drive.py`

Previously a placeholder with `NotImplementedError`. Now contains:

- Accepts `image` (ee.Image), `description` (str), `folder` (str),
  `region` (any AOI form), `scale` (int/float), optional `file_name_prefix`
  (str), optional `max_pixels` (float, default 1e13)
- Validates `description` and `folder` are non-empty strings
- Normalizes `region` via `to_ee_geometry()` — so file paths, GeoJSON dicts,
  and EE objects all work
- Creates an `ee.batch.Export.image.toDrive()` task
- Returns the task **without starting it** — user must call `.start()`
- Defaults `fileNamePrefix` to `description` when not provided

**Review focus:**
- Is reusing `to_ee_geometry()` for region normalization the right approach?
  The spec (section 17) shows `region=aoi` as an `ee.Geometry`. Does
  accepting file paths and dicts add value, or does it blur the export
  interface?
- The function does not validate `image` — it accepts any object and passes
  it to `ee.batch.Export.image.toDrive()`. Should there be a type check, or
  is this an acceptable boundary-trust decision?
- The function does not validate `scale` — negative or zero values would be
  passed through to Earth Engine. Is this acceptable?
- `fileNamePrefix` defaults to `description` — is this a good default? Could
  `description` contain characters that are invalid in filenames?
- The return type annotation is `ee.batch.Export.image` — is this the correct
  type for the returned task object?
- The `GeeComposerError` import uses the `..exceptions` relative import. Is
  the `to_ee_geometry` import from `..aoi` consistent with other modules?
- Compare with the spec (section 17): does the signature match the spec's
  `export_to_drive(image, description, folder, region, scale, ...)`?
- Does the implementation satisfy the architecture contract's rule that export
  helpers must not own composition behavior?

### 2. `compose_yearly()`

**File:** `08_pkg/src/geecomposer/grouping.py`

Previously a placeholder with `NotImplementedError`. Now contains:

- Accepts `years` (list[int] | range) and `**compose_kwargs`
- For each year, derives `start="{year}-01-01"` and `end="{year+1}-01-01"`
- Delegates to `compose()` with the derived dates plus all forwarded kwargs
- Returns `dict[int, ee.Image]`
- Validates:
  - `years` is iterable (not a bare int)
  - `years` is non-empty
  - Each element is an integer
  - `start` and `end` are not in `compose_kwargs` (rejects conflict)

**Review focus:**
- Is the date derivation correct? `"{year}-01-01"` to `"{year+1}-01-01"`
  matches Earth Engine's `filterDate` inclusive-start / exclusive-end
  semantics. But is this documented clearly enough?
- The function accepts `**compose_kwargs` and forwards everything. Could
  a user accidentally pass `collection` instead of `dataset` and get
  confusing behavior? Is this a concern or acceptable delegation?
- The validation consumes the `years` iterable by calling `list(years)` in
  `_validate_yearly_args`, but the actual iteration in `compose_yearly`
  iterates the original `years` parameter. If `years` is a generator, it
  would be exhausted by validation. Is this a bug?
- The `start`/`end` conflict check uses `in compose_kwargs`. What if the
  user passes `start=None`? That would trigger the error even though `None`
  is the default. Is this correct?
- Compare with the spec (section 7.1): does the signature match
  `compose_yearly(years, **compose_kwargs) -> dict[int, ee.Image]`?
- Does the implementation satisfy the architecture contract's rule that
  grouping stays intentionally modest?
- Is the import of `compose` from `.compose` creating a circular dependency
  risk? (grouping imports compose, compose imports datasets, etc.)

### 3. Tests — Drive export

**File:** `08_pkg/tests/test_export_drive.py`

6 tests:

- `test_creates_drive_task` — mocks `ee.batch.Export.image.toDrive` and
  `to_ee_geometry`, verifies task creation with correct arguments
- `test_custom_file_name_prefix` — verifies custom prefix is passed through
- `test_custom_max_pixels` — verifies custom max_pixels is passed through
- `test_region_normalization` — verifies `to_ee_geometry` is called with the
  region argument (a string path in this case)
- `test_empty_description_raises` — empty description raises GeeComposerError
- `test_empty_folder_raises` — empty folder raises GeeComposerError

**Review focus:**
- Does `test_creates_drive_task` verify all arguments passed to
  `ee.batch.Export.image.toDrive`? Check that `image`, `description`,
  `folder`, `region`, `scale`, `fileNamePrefix`, and `maxPixels` are all
  verified.
- Is there a test for `file_name_prefix=None` to verify the default behavior
  (falls back to description)?
- Is there a test for a non-string `description` (e.g., `int`)?
- Is there a test that the returned object is the task from
  `ee.batch.Export.image.toDrive`?
- Are there missing tests? Consider:
  - `region` as an `ee.Geometry` (EE object passthrough)
  - `scale=0` or `scale=-1` (invalid but not validated)

### 4. Tests — Yearly grouping

**File:** `08_pkg/tests/test_grouping.py`

9 tests in 2 classes:

- `TestComposeYearly` (4 tests):
  - `test_delegates_to_compose_per_year` — verifies `compose()` called twice
    with correct `start`/`end` for years [2023, 2024]
  - `test_returns_dict_keyed_by_year` — verifies dict keys and call count for
    range(2020, 2023)
  - `test_single_year` — single year with S1 filters
  - `test_forwards_all_compose_kwargs` — verifies mask, transform, select
    forwarded
- `TestComposeYearlyValidation` (5 tests):
  - `test_empty_years_raises`
  - `test_non_integer_year_raises`
  - `test_start_in_kwargs_raises`
  - `test_end_in_kwargs_raises`
  - `test_non_iterable_years_raises`

**Review focus:**
- Does `test_delegates_to_compose_per_year` verify the exact `start`/`end`
  date strings? It checks `"2023-01-01"` to `"2024-01-01"` and
  `"2024-01-01"` to `"2025-01-01"` — is this correct for calendar years?
- Does `test_forwards_all_compose_kwargs` use a real built-in transform
  factory (`ndvi()`) to verify forwarding? Does it verify the transform
  object identity?
- Is there a test for `years` as a generator? The implementation may have
  a generator-exhaustion bug.
- Is there a test for `years` containing duplicate years? Should that raise
  or just overwrite?
- Is there a test for `compose()` raising inside the loop (e.g., invalid
  dataset)? What happens to partially built results?
- Are the validation error messages specific enough?

### 5. Governance and documentation updates

**Files updated:**
- `08_pkg/current_status.md` — both helpers noted, 147 tests, 0 skipped
- `08_pkg/development_backlog.md` — M004 completed, next steps listed
- `08_pkg/testing_strategy.md` — export and grouping test coverage described
- `05_governance/decision_log.md` — two new decisions: task not auto-started,
  calendar year date derivation
- `05_governance/risks.md` — new risks: task not started, calendar-year-only
  limitation, initialize still placeholder
- `05_governance/review_log.md` — M004 implementation entry
- `03_experiments/run_summary.md` — M004 test breakdown
- `02_analysis/findings.md` — findings about region normalization reuse,
  delegation pattern, start/end conflict prevention

**Review focus:**
- Do the per-file test counts match reality?
- Are the decision log entries well-reasoned?
- Are the new risks at appropriate severity?
- Is the `initialize()` placeholder honestly called out?
- Does `development_backlog.md` accurately reflect what's next?

---

## Pre-existing code that was NOT modified

- `08_pkg/src/geecomposer/__init__.py` — unchanged (already exports both)
- `08_pkg/src/geecomposer/compose.py` — unchanged (consumed by grouping)
- `08_pkg/src/geecomposer/aoi.py` — unchanged (consumed by export)
- `08_pkg/src/geecomposer/validation.py` — unchanged
- `08_pkg/src/geecomposer/exceptions.py` — unchanged
- `08_pkg/src/geecomposer/reducers/temporal.py` — unchanged
- `08_pkg/src/geecomposer/transforms/` — all unchanged
- `08_pkg/src/geecomposer/datasets/sentinel1.py` — unchanged
- `08_pkg/src/geecomposer/datasets/sentinel2.py` — unchanged
- `08_pkg/src/geecomposer/datasets/__init__.py` — unchanged
- `08_pkg/src/geecomposer/utils/metadata.py` — unchanged
- `08_pkg/src/geecomposer/export/__init__.py` — unchanged (already exports
  `export_to_drive`)
- `08_pkg/src/geecomposer/export/gcs.py` — placeholder, unchanged
- `08_pkg/src/geecomposer/auth.py` — placeholder, unchanged
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

### Step 1 — Read project guidance
Read and use these first:
- `CLAUDE.md`
- `geecomposer_v0.1_spec.md` (sections 7, 17 especially)
- `08_pkg/architecture_contract.md`
- `08_pkg/public_api_contract.md`
- `05_governance/review_rubric.md`
- `05_governance/decision_log.md`
- `05_governance/risks.md`
- `05_governance/review_log.md`
- `docs/GEECOMPOSER_MILESTONE_004_EXPORT_AND_GROUPING.md`

Then read the current state:
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/development_backlog.md`
- `03_experiments/run_summary.md`

### Step 2 — Evaluate `export_to_drive()`
Inspect `08_pkg/src/geecomposer/export/drive.py`:

- Does the function create the EE task correctly?
- Is `to_ee_geometry()` reuse for region normalization appropriate?
- Is the `fileNamePrefix` default correct?
- Is input validation sufficient? What about `image`, `scale`?
- Does not-starting the task match the spec example?
- Compare with spec section 17.

### Step 3 — Evaluate `compose_yearly()`
Inspect `08_pkg/src/geecomposer/grouping.py`:

- Does the date derivation match EE `filterDate` semantics?
- Does `**compose_kwargs` forwarding work correctly?
- Is there a generator-exhaustion bug? (`list(years)` in validation consumes
  the iterator, but `for year in years` in the main function iterates the
  original — if `years` is a generator, it would be empty)
- Is the `start`/`end` conflict check correct for all edge cases?
- Compare with spec section 7.1.
- Check for circular import risk: grouping → compose → datasets.

### Step 4 — Evaluate the tests
Inspect:
- `08_pkg/tests/test_export_drive.py`
- `08_pkg/tests/test_grouping.py`

**Export tests:**
- Do they verify the full argument set passed to `toDrive()`?
- Is the default `fileNamePrefix` behavior tested?
- Are there missing edge cases?

**Grouping tests:**
- Do they verify date derivation per year?
- Do they verify kwargs forwarding with real objects?
- Is there a generator test?
- Are validation tests comprehensive?

Run the test suite:
`.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

### Step 5 — Evaluate separation of concerns
This is the key architectural question for milestone 004:

- Does `export_to_drive()` depend on `compose()`? (It should not.)
- Does `compose_yearly()` depend on `export_to_drive()`? (It should not.)
- Does `compose()` depend on either export or grouping? (It should not.)
- Is the ownership graph: compose ← grouping, aoi ← export, and nothing
  the other way?
- Does the architecture contract rule hold that export helpers must not own
  composition behavior?

### Step 6 — Evaluate scope discipline
- No GCS export was implemented
- No task monitoring was added
- No monthly/seasonal grouping was added
- No `compose()` changes were made
- No auth was implemented
- No notebooks were created
- Placeholder modules remain placeholder

### Step 7 — Evaluate governance honesty
- Do per-file test counts match reality?
- Are decision log entries well-reasoned?
- Are risks accurately described?
- Is the `initialize()` placeholder honestly called out?
- Does `current_status.md` accurately describe what is and isn't ready?

### Step 8 — Evaluate v0.1 feature completeness
Step back and assess the package against the spec:

- **Spec section 4.1** (in scope): which items are done and which remain?
  - Collections: S2 and S1 ✓ (check)
  - Inputs: AOI, dates, reducer, transform, filters ✓ (check)
  - Transforms: select_band, normalized_difference, ndvi, expression ✓ (check)
  - Reducers: median, mean, min, max, mosaic ✓ (check)
  - Grouping: yearly ✓ (check), monthly/seasonal deferred
  - Export: Drive ✓ (check), GCS placeholder
  - Auth: `initialize()` placeholder — is this a blocker for v0.1?
- **Spec section 6.1** (top-level exports): are all four functions
  (`initialize`, `compose`, `compose_yearly`, `export_to_drive`) importable?
- Is the package ready for notebook-based smoke testing?

### Step 9 — Produce a structured review
Write your answer in the following structure:

# Repo Review — Export and Grouping

## 1. Current State Summary
- Whether milestone 004 addressed its stated goals
- Whether export and grouping are cleanly separated from composition
- Whether the tests are meaningful
- Whether the docs are honest
- Overall readiness for closing milestone 004

## 2. What Was Done Well
- Export helper design
- Grouping delegation pattern
- Test coverage and approach
- Scope discipline
- Governance honesty

## 3. Problems / Risks
### Confirmed issues
- Any correctness bugs (especially the generator-exhaustion question)
- Any docs that overstate achievement
- Any test gaps
### Design risks
- Region normalization in export (value vs complexity)
- `**compose_kwargs` forwarding risks
- `start=None` conflict check edge case
- Return type annotation accuracy
### Technical debt
- `initialize()` placeholder
- GCS export placeholder
- Any accumulated concerns

## 4. Alignment with Framework
- Architecture contract: export/composition separation
- Public API contract: all four exports present
- Spec compliance (sections 7, 17)
- Review rubric pass

## 5. What Should Change Now
Prioritized list:
- `P0`: must fix before closing
- `P1`: should fix before closing or soon after
- `P2`: meaningful improvement
- `P3`: polish

## 6. Recommended Next Step
- Is milestone 004 closeable?
- What should come next? (auth, notebooks, examples?)
- Is the package ready for v0.1 release preparation?

## 7. Optional Code Changes
Small high-confidence fixes only. No new features.

---

## Review style constraints

- Be concrete and repo-aware
- Prefer evidence from the actual files over assumptions
- Do not give generic software advice
- Distinguish clearly between confirmed issues, design risks, and preferences
- Be especially rigorous about:
  - Whether `compose_yearly()` has a generator-exhaustion bug: trace what
    happens when `years` is a generator — `_validate_yearly_args` calls
    `list(years)` which exhausts it, then the `for year in years` loop in
    the main function would iterate an empty generator
  - Whether `to_ee_geometry()` reuse in `export_to_drive()` is justified or
    over-engineered for the export use case
  - Whether the date derivation `"{year}-01-01"` to `"{year+1}-01-01"` is
    correct for Earth Engine's `filterDate` semantics
  - Whether `start=None` in `compose_kwargs` would incorrectly trigger the
    conflict check
  - Whether the return type annotation `ee.batch.Export.image` is accurate
  - Whether the per-file test counts match the actual suite
  - Whether the 0-skipped claim is accurate (all former placeholders replaced)
- Cross-reference against:
  - `geecomposer_v0.1_spec.md` sections 7 and 17
  - `08_pkg/architecture_contract.md` for separation rules
  - `08_pkg/public_api_contract.md` for API shape
  - `05_governance/review_rubric.md` for review criteria
  - `docs/GEECOMPOSER_MILESTONE_004_EXPORT_AND_GROUPING.md` for milestone scope
- Verify the 147-pass / 0-skip claim independently

If needed, inspect as many files as necessary before answering. After
producing the review, also write it to:
`05_governance/reviews/review_milestone_004.md`

Be thorough but constructive. This is milestone 004 — the last major feature
milestone before v0.1 packaging. The bar is whether export and grouping are
correct, well-separated, properly tested, and whether the package is
approaching v0.1 readiness.
