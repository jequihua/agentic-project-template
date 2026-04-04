# Glossary — Artifact-First Agentic ML Workflow

## Artifact
A concrete, persistent piece of work (usually a file) that represents progress.
Examples:
- problem_statement.md
- run_summary.md
- model outputs

Artifacts are the unit of progress.

---

## Workspace
A structured folder representing a stage or function in the project.
Examples:
- 00_brief
- 03_experiments

Each workspace has:
- a clear purpose
- its own CONTEXT.md
- specific artifacts

---

## Active Workspace
The workspace currently guiding the work.

It determines:
- what the agent should focus on
- which files to update
- what “done” means at that moment

---

## CONTEXT.md
A file inside each workspace that defines:
- purpose
- rules
- key artifacts
- definition of done

It acts as local instructions for the agent.

---

## CLAUDE.md
The root instruction file for the repository.

Defines:
- overall behavior
- workspace structure
- global rules
- interaction patterns

---

## Artifact-First Workflow
A methodology where progress is measured by improving artifacts rather than just writing code.

---

## Mode A (New Project)
Starting from scratch with full structure.

---

## Mode B (Existing Repository)
Applying the framework to an existing codebase.

Includes:
- analysis of existing system
- reuse vs rewrite decisions

---

## Governance
Tracking decisions, costs, risks, and reviews.

Ensures:
- reproducibility
- accountability
- traceability

---

## Decision Log
A record of important choices and their rationale.

---

## Cost Log
A record of compute, storage, or operational costs.

---

## Review Loop
Process of:
1. Agent produces work
2. Reviewer critiques
3. Synthesis is created
4. Human decides

---

## Experiment Plan
A document describing what will be tested and how.

---

## Run Summary
A record of experiment results and conclusions.

---

## Error Analysis
A structured investigation of model failures.

---

## Infrastructure (Infra)
Systems that run the code:
- cloud
- containers
- compute environments

---

## Application Layer (App)
Interfaces for users:
- webapps
- dashboards
- APIs

---

## Package (Pkg)
Reusable code packaged for reuse.

---

## Operations (Ops)
Long-running or recurring workflows:
- monitoring
- scheduled jobs

---

## Legacy Review
Structured analysis of an existing codebase before modification.

---

## Convergence
Process of combining multiple reviews into a final decision.

---

## Definition of Done
Criteria that define when a task is complete.

---

## Template Repository
A reusable GitHub repository used to initialize new projects.

---

## Agent
An AI system (e.g., Claude, GPT) performing tasks.

---

## Reviewer
An agent (or human) evaluating work and suggesting improvements.
