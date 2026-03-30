# Project Instructions

## Purpose
This repository follows the Artifact-First Agentic ML Workflow.

The unit of progress is not “an agent completed a task.”
The unit of progress is “an artifact advancing from one reviewable state to another.”

## Workspace map
- `00_brief/` — objective, scope, constraints, success metrics
- `01_data/` — data sources, schema, quality, leakage, splits
- `02_analysis/` — exploration, findings, hypotheses, notebook summaries
- `03_experiments/` — experiment plans, runs, comparisons, error analysis
- `04_delivery/` — final outputs, reports, model cards, data products
- `05_governance/` — decisions, costs, assumptions, risks, reviews
- `06_infra/` — infra, Docker, Terraform, local/cloud execution
- `07_app/` — app layer such as review webapps or APIs
- `08_pkg/` — reusable package code
- `09_ops/` — recurring operations, monitoring, runbooks
- `90_legacy_review/` — required for existing-repo work before major changes

## Default behavior
1. Read the relevant workspace `CONTEXT.md` before editing.
2. Prefer updating existing artifacts over creating ad hoc notes.
3. Keep summaries in markdown, not only in notebooks.
4. Log important choices in `05_governance/decision_log.md`.
5. Log meaningful spend assumptions or actual spend in `05_governance/cost_log.md`.
6. Do not modify raw data snapshots unless explicitly instructed.
7. For expensive runs, document the expected cost before execution.
8. For legacy code, do not make major modifications before documenting the system in `90_legacy_review/`.

## Review workflow
- Claude Code may be the main developer.
- GPT may be the independent reviewer.
- A synthesis review should be recorded in `05_governance/reviews/review_synthesis.md`.
- The human owner makes the final decision.
