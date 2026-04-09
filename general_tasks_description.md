# Artifact-First Agentic Scientific Workflow Framework

## Overview

This framework defines a structured approach to developing scientific software, benchmarking, data science, and machine learning projects using AI-assisted workflows.

It integrates:
- Structured context engineering (folder-based workflows)
- Artifact-driven development
- Controlled use of AI agents
- Iterative review and convergence
- Minimal but effective instruction design

The goal is to maximize:
- **clarity**
- **traceability**
- **reviewability**
- **reproducibility**
- **useful automation**

while avoiding:
- excessive orchestration complexity
- hidden system state
- over-reliance on prompts or agent personalities

---

## Core Principle

> The unit of progress is not an agent completing a task.  
> The unit of progress is an artifact advancing from one reviewable state to another.

---

## Key Concepts

### 1. Artifact-Centered Development

Artifacts are the primary outputs of the system.  
Each meaningful step in the project produces or updates an artifact.

Examples:
- problem brief
- dataset documentation
- exploratory analysis summaries
- experiment plans
- run summaries
- error analyses
- benchmark cards
- stakeholder reports

Artifacts are:
- human-readable
- version-controlled
- reviewable
- reusable

---

### 2. Workspace-Based Context

The project is divided into **workspaces**, each representing a mode of work.

Each workspace:
- defines its own context
- has clear objectives
- produces specific artifacts

Workspaces act as **context boundaries** that limit what the AI needs to consider.

---

### 3. Minimal Global Instructions

A root instruction file (e.g., `AGENTS.md` or `CLAUDE.md`) provides:

- project identity
- workspace map
- core commands
- essential constraints

It should:
- be concise
- avoid redundancy
- act as a routing layer, not a knowledge base

---

### 4. Localized Context (Per Workspace)

Each workspace contains a `CONTEXT.md` file defining:

- purpose of the workspace
- expected outputs
- evaluation criteria
- relevant files
- common pitfalls

This is where detailed guidance lives.

---

### 5. Role-Based AI Usage

AI is used in clearly defined roles:

#### Maker
- Generates code, analysis, or artifacts
- Performs implementation and iteration

#### Reviewer(s)
- Critiques outputs
- Identifies issues and improvements
- Evaluates correctness, clarity, and completeness

#### Synthesizer
- Merges multiple reviews
- Produces structured conclusions
- Distinguishes between agreement, disagreement, and uncertainty

---

### 6. Convergent Review Process

Instead of accumulating opinions, the system enforces convergence:

1. Output is produced
2. Independent reviews are performed
3. Reviews are merged into structured categories:
   - agreed issues
   - disagreements
   - improvements
4. Disagreements are resolved through evidence
5. Final decisions are recorded

---

### 7. Skills (Reusable Workflows)

Skills represent repeatable processes with defined inputs and outputs.

Examples:
- exploratory data analysis checklist
- experiment review
- error analysis
- notebook-to-report transformation
- regression testing

Skills:
- reduce prompt variability
- standardize workflows
- improve consistency

---

### 8. Selective Tool Integration (MCP)

External tools are used only when necessary.

Typical use cases:
- experiment tracking systems
- data warehouses
- documentation platforms
- issue trackers

The repository remains the primary source of truth.

---

### 9. Version-Controlled Development

All artifacts and code are:
- stored in version control (e.g., Git)
- diffable
- reviewable over time

Git acts as:
- memory
- audit trail
- comparison system

---

## System Architecture

The framework is composed of five layers:

### Layer 1 — Project Operating System
- root instructions
- workspace definitions
- naming conventions
- core commands

### Layer 2 — Workspaces
- structured folders
- localized context
- task-specific environments

### Layer 3 — Artifacts
- outputs of each step
- review surfaces
- decision anchors

### Layer 4 — Agent Roles
- maker
- reviewers
- synthesizer

### Layer 5 — Tooling
- external systems (via MCP)
- experiment tracking
- data access

---

## Workspace Model

A standard project structure consists of five core workspaces:

### 00_brief — Problem Definition
Defines:
- objectives
- constraints
- target metrics
- assumptions
- non-goals

---

### 01_data — Data Understanding
Defines:
- data sources
- schema
- data quality
- leakage risks
- splits
- feature provenance

---

### 02_analysis — Exploration
Contains:
- exploratory analysis
- visualizations
- hypotheses
- observations
- notebooks and summaries

---

### 03_experiments — Experimentation
Contains:
- experiment plans
- configurations
- results
- comparisons
- error analyses

---

### 04_delivery — Outputs
Contains:
- stakeholder summaries
- model documentation
- deployment preparation
- monitoring plans

---

## Artifact Lifecycle

Artifacts evolve through stages:

1. Initial creation
2. Iterative refinement
3. Review and critique
4. Consolidation
5. Finalization

Artifacts are never “final” — they remain editable and versioned.

---

## Execution Flow

A typical workflow:

1. Define or update an artifact
2. Execute work within a workspace
3. Produce or update outputs
4. Run review process
5. Resolve issues
6. Record decisions
7. Move to next step

---

## Design Principles

### Clarity Over Cleverness
Prefer simple, inspectable systems over complex orchestration.

### Local Context Over Global Context
Keep context scoped to relevant workspaces.

### Artifacts Over Hidden State
All important outputs should be visible and editable.

### Reuse Over Repetition
Convert repeated workflows into skills.

### Minimalism Over Exhaustiveness
Avoid unnecessary instructions or structure.

### Evidence Over Opinion
Decisions should be based on artifacts and results.

---

## Comparison to Other Approaches

| Approach | Difference |
|----------|-----------|
| Multi-agent systems | Focus on autonomy rather than artifact traceability |
| Folder-based context | Focus on stages rather than artifact lifecycle |
| Git-native agents | Focus on portability rather than workflow simplicity |
| Minimal instruction | Focus on reducing context rather than structuring work |

---

## Intended Use Cases

This framework is particularly suited for:

- data science projects
- machine learning experimentation
- research workflows
- iterative analytical work
- human-in-the-loop systems

---

## Limitations

- Requires discipline in maintaining artifacts
- May feel slower initially due to structure
- Less optimized for real-time multi-agent collaboration
- Requires adaptation for highly dynamic systems

---

## Summary

This framework defines a structured, artifact-centered approach to agentic workflows.

It combines:
- structured context
- clear outputs
- controlled AI roles
- iterative review
- versioned development

The result is a system that prioritizes:
- transparency
- reliability
- and long-term usability

Proposed step-by-step plan

## Necessary steps

01. Define framework scope for your kind of projects
     Decide exactly what project types this framework must cover for you.
02. Choose the default workspace structure
     Lock the top-level folders and decide whether you need extra infra/app workspaces.
03. Define the core artifact set
     Decide which documents/artifacts every project must have.
04. Define agent roles and review flow
     Clarify Claude’s role, GPT’s role, second-review role, and convergence method.
05. Define the root instruction file
     Specify what AGENTS.md or CLAUDE.md should always contain.
06. Define per-workspace CONTEXT.md files
     Decide what each workspace context file should include.
07. Define project lifecycle stages
     Map how a project moves from idea to delivery under this framework.
08. Define task execution rules
     Decide how you start a task, how work is performed, and what counts as done.
09. Define review and convergence artifacts
     Create the structure for reviewer comments, synthesis, and resolution.
10. Define the reusable skills catalog
     Decide which repeatable workflows should become skills first.
11. Define tooling and MCP boundaries
     Decide when to use local repo context vs cloud tools vs external systems.
12. Define coding/infrastructure conventions
     Establish how Python, notebooks, Docker, Terraform, configs, and tests fit in.
13. Define experiment and data governance rules
     Decide how to track runs, data versions, thresholds, samples, and validation.
14. Define deployment/project-output patterns
     Cover batch pipelines, APIs, webapps, and human-in-the-loop review apps.
15. Create the project initialization template
     Turn all of the above into the starter structure for any new project.
16. Create the operating manual
     Write the step-by-step instructions you’ll actually follow on each new project.
