# geecomposer Milestone 006 Cleanup Prompt

You are working in a structured artifact-first scientific software repository.

Follow `CLAUDE.md` strictly and respect workspace boundaries.

This is a very small cleanup pass for milestone 006. The milestone is already
reviewed as closeable; this pass is only to remove small documentation drift so
the reducer surface is described consistently everywhere.

Until further notice, use this case-study AOI as the canonical project polygon
for AOI-dependent examples, local manual checks, and notebook-oriented notes:

- `01_data/case_studies/rbmn.geojson`

The current package state is:

- milestones 001-006 are implemented
- milestone 006 (`count` reducer) has passed independent review
- the only confirmed follow-up is stale reducer documentation in a few places

Use:

- `CLAUDE.md`
- `geecomposer_v0.1_spec.md`
- `docs/GEECOMPOSER_MILESTONE_006_OBSERVATION_COUNT.md`
- `05_governance/reviews/review_milestone_006.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/README.md`

as the primary control artifacts.

## Active Workspaces

- `05_governance`
- `08_pkg`

## Before starting

Read:

- `CLAUDE.md`
- `geecomposer_v0.1_spec.md`
- `05_governance/reviews/review_milestone_006.md`
- `08_pkg/current_status.md`
- `08_pkg/testing_strategy.md`
- `08_pkg/README.md`

Also inspect before editing:

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/reducers/temporal.py`
- `08_pkg/src/geecomposer/validation.py`

## Task

Do one final narrow cleanup pass for milestone 006.

### 1. Fix stale reducer docstrings

Required outcome:

- the `compose()` docstring lists all supported reducers, including `count`
- the `apply_reducer()` docstring lists all supported reducers, including
  `count`

Files to check first:

- `08_pkg/src/geecomposer/compose.py`
- `08_pkg/src/geecomposer/reducers/temporal.py`

### 2. Fix any equally small reducer-list drift in user-facing docs

Required outcome:

- if `08_pkg/README.md` lists supported reducers explicitly, it should include
  `count`
- wording about count should stay accurate:
  - Sentinel-2 with masking -> valid clear-observation count
  - Sentinel-1 / Sentinel-1 float without masking -> contributing-acquisition
    count

This is documentation cleanup only. Do not broaden into a README rewrite.

### 3. Do not reopen milestone scope

You should not:

- change reducer behavior
- add new tests unless a tiny doc-related test is clearly justified
- add helper functions
- add notebook files
- refactor unrelated docs
- reopen seasonal grouping or richer QA ideas

### 4. Update governance only if needed

Only update governance artifacts if the cleanup changes a user-visible status
claim in a meaningful way. In most cases, this pass should not need broad
governance edits.

## Goal

After this pass, milestone 006 should be completely clean to close:

- reducer behavior unchanged
- docstrings accurate
- README reducer list accurate
- no stale mention of the old five-reducer set

## Scope

Keep this pass extremely narrow.

You should:

- fix the stale reducer docstrings
- fix the README reducer list if needed
- leave implementation and architecture untouched

You should not:

- add new functionality
- touch dataset modules
- touch compose logic
- touch export or grouping
- touch milestone planning beyond what is necessary for closure

## Definition of Done

- all explicit reducer lists in the touched user-facing docs include `count`
- no implementation behavior changes
- milestone 006 documentation is internally consistent

## Important principle

Prefer one tiny truthful cleanup over another broad polishing pass.
