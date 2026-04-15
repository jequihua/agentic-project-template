# Review Prompt — Observation Count Cleanup and Final Close

You are acting as a repo-aware reviewer for a structured agentic scientific software project.

Your role is NOT to implement new features.
Your role is to verify the milestone 006 cleanup pass and confirm the milestone is fully closeable.

You are reviewing the local repository currently open in your environment.

## Review objective

Verify that:
1. the three stale reducer-list references identified in the M006 review are now corrected,
2. no implementation behavior changed,
3. milestone 006 can be fully closed.

This should be a short, focused review.

---

## Project context

- `geecomposer`: lightweight Python library for Google Earth Engine compositing
- milestones 001–006 implemented; M006 added `count` as a sixth reducer
- M006 independent review confirmed the milestone closeable, noting stale
  reducer docstrings as a minor follow-up
- **a cleanup pass has just been applied — this is the review target**
- 176 tests pass, 0 skipped

---

## What was changed

Three documentation-only edits. No implementation changes.

### 1. `compose()` reducer docstring

**File:** `08_pkg/src/geecomposer/compose.py`

Changed from:
```
Temporal reducer name (``"median"``, ``"mean"``, ``"min"``,
``"max"``, ``"mosaic"``).
```
To:
```
Temporal reducer name (``"median"``, ``"mean"``, ``"min"``,
``"max"``, ``"mosaic"``, ``"count"``).
```

### 2. `apply_reducer()` docstring

**File:** `08_pkg/src/geecomposer/reducers/temporal.py`

Changed from:
```
One of ``"median"``, ``"mean"``, ``"min"``, ``"max"``, ``"mosaic"``.
```
To:
```
One of ``"median"``, ``"mean"``, ``"min"``, ``"max"``, ``"mosaic"``,
``"count"``.
```

### 3. README reducer list

**File:** `08_pkg/README.md`

Added after `"mosaic"`:
```
- `"count"` (per-pixel observation count)
```

---

## Instructions

### Step 1 — Verify the three fixes
Inspect each file and confirm `"count"` is now listed:

- `08_pkg/src/geecomposer/compose.py` — `reducer` parameter docstring
- `08_pkg/src/geecomposer/reducers/temporal.py` — `apply_reducer` docstring
- `08_pkg/README.md` — reducer list section

### Step 2 — Search for any remaining stale five-reducer lists
Search the package source and docs for any remaining reference to the old
five-reducer set that omits `count`:

```
grep -rn "median.*mean.*min.*max.*mosaic" 08_pkg/src/ 08_pkg/README.md
```

Any match that lists exactly five reducers without `count` is stale.

### Step 3 — Verify no implementation changes
Confirm that only docstrings and documentation were modified:

- `08_pkg/src/geecomposer/validation.py` — unchanged from M006 implementation
- `08_pkg/src/geecomposer/reducers/temporal.py` — only docstring changed, not
  `_REDUCER_MAP` or `apply_reducer` logic
- `08_pkg/src/geecomposer/compose.py` — only docstring changed, not pipeline
  logic
- All other source files — unchanged
- All test files — unchanged

### Step 4 — Run the test suite
`.venv\Scripts\python.exe -m pytest 08_pkg/tests -v --basetemp=.pytest_tmp`

Verify 176 passed, 0 skipped.

### Step 5 — Produce a structured review

# Repo Review — Observation Count Cleanup

## 1. Stale Reducer Lists
- Are all three references updated?
- Are there any remaining stale five-reducer lists?

## 2. Implementation Integrity
- Were any non-documentation changes made?

## 3. Milestone Closure Decision
- **Closeable: Yes / No**
- If yes, what should come next?

---

## Review style constraints

- Be brief — this is a three-line documentation fix
- Verify by inspection, not by assumption
- The search for remaining stale lists (step 2) is the most important check —
  a grep for the five-reducer pattern will catch any missed reference
- Verify the 176-pass / 0-skip claim independently

After producing the review, also write it to:
`05_governance/reviews/review_milestone_006_cleanup.md`

Be direct. This should take minutes, not hours.
